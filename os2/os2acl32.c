/*
 * acl32.c   v1.0
 *
 *  Modified 28 Feb 2007 for netapi32 use.
 *
 *  Michael Greene <greenemk@cox.net>
 *
 */

/*
  Copyright (c) 1990-2005 Info-ZIP.  All rights reserved.

  See the accompanying file LICENSE, version 2004-May-22 or later
  (the contents of which are also included in zip.h) for terms of use.
  If, for some reason, both of these files are missing, the Info-ZIP license
  also may be found at:  ftp://ftp.info-zip.org/pub/infozip/license.html
*/
/* os2acl.c - access to OS/2 (LAN Server) ACLs
 *
 * Author:  Kai Uwe Rommel <rommel@ars.de>
 * Created: Mon Aug 08 1994
 *
 */

/*
 * supported 32-bit compilers:
 * - emx+gcc
 * - IBM C Set++ 2.1 or newer
 * - Watcom C/C++ 10.0 or newer
 *
 * supported 16-bit compilers:
 * - MS C 6.00A
 * - Watcom C/C++ 10.0 or newer
 *
 * supported OS/2 LAN environments:
 * - IBM LAN Server/Requester 3.0, 4.0 and 5.0 (Warp Server)
 * - IBM Peer 1.0 (Warp Connect)
 */


/*
 * $Log: os2acl.c,v $
 * Revision 1.3  1996/04/03 19:18:27  rommel
 * minor fixes
 *
 * Revision 1.2  1996/03/30 22:03:52  rommel
 * avoid frequent dynamic allocation for every call
 * streamlined code
 *
 * Revision 1.1  1996/03/30 09:35:00  rommel
 * Initial revision
 *
 */


#define INCL_DOSMODULEMGR
#define INCL_DOSFILEMGR
#define INCL_DOSERRORS
#include <os2.h>

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <ctype.h>
#include <malloc.h>

#include "os2/os2acl.h"

#define UNLEN 20
#define LSFAR
#define LSPTR


typedef struct access_list {
    unsigned char   acl_ugname[UNLEN+1];
    unsigned char   acl_ugname_pad_1;
    short           acl_access;
} ACCLIST;


typedef struct access_info_1 {
    unsigned char LSFAR * LSPTR acc1_resource_name;
    short                       acc1_attr;
    short                       acc1_count;
} ACCINFO;

extern unsigned short Net32AccessAdd (
                     const unsigned char * pszServer,
                     unsigned long         ulLevel,
                     unsigned char       * pbBuffer,
                     unsigned long         ulBuffer );


extern unsigned short Net32AccessGetInfo (
                     const unsigned char * pszServer,
                     unsigned char       * pszResource,
                     unsigned long         ulLevel,
                     unsigned char       * pbBuffer,
                     unsigned long         cbBuffer,
                     unsigned long       * pcbTotalAvail );


extern unsigned short Net32AccessSetInfo (
                     const unsigned char * pszServer,
                     unsigned char       * pszResource,
                     unsigned long         ulLevel,
                     unsigned char       * pbBuffer,
                     unsigned long         ulBuffer,
                     unsigned long         ulParmNum );


static char *path;
static char *data;

static BOOL initialized   = FALSE;
static BOOL netapi_avail  = FALSE;

static ACCINFO *ai;


static BOOL acl_init(void)
{
    HMODULE netapi;

    char buf[256];

    if (initialized) return netapi_avail;

    initialized = TRUE;

    if (DosLoadModule(buf, sizeof(buf), "NETAPI32", &netapi)) return FALSE;
    else DosFreeModule(netapi);

    path = malloc(CCHMAXPATH);
    if(path == NULL) return FALSE;

    data = malloc(ACL_BUFFERSIZE);
    if(data == NULL) {
        free(path);
        return FALSE;
    }

    ai = malloc(sizeof(ACCINFO));
    if(ai == NULL) {
        free(path);
        free(data);
        return -1;
    }

    netapi_avail = TRUE;

    return netapi_avail;
}

static void acl_mkpath(char *buffer, const char *source)
{
    char  *ptr;

    static char cwd[CCHMAXPATH];
    static ULONG cwdlen;

    ULONG cdrive;
    ULONG drivemap;

    if (isalpha(source[0]) && source[1] == ':') buffer[0] = 0; /* fully qualified names */
    else {
        if (cwd[0] == 0) {
            DosQueryCurrentDisk(&cdrive, &drivemap);
            cwd[0] = (char)(cdrive + '@');
            cwd[1] = ':';
            cwd[2] = '\\';
            cwdlen = sizeof(cwd) - 3;
            DosQueryCurrentDir(0, cwd + 3, &cwdlen);
            cwdlen = strlen(cwd);
        }

        if (source[0] == '/' || source[0] == '\\') {
            if (source[1] == '/' || source[1] == '\\') buffer[0] = 0; /* UNC names */
            else {
                strncpy(buffer, cwd, 2);
                buffer[2] = 0;
            }
        } else {
            strcpy(buffer, cwd);
            if (cwd[cwdlen - 1] != '\\' && cwd[cwdlen - 1] != '/') strcat(buffer, "/");
        }
    }

    strcat(buffer, source);

    for (ptr = buffer; *ptr; ptr++) if (*ptr == '/') *ptr = '\\';

    if (ptr[-1] == '\\') ptr[-1] = 0;

    strupr(buffer);
}


static int acl_bin2text(char *data, char *text)
{
    unsigned long cnt;
    unsigned long offs;

    ACCINFO *ai;
    ACCLIST *al;

    ai = (ACCINFO *) data;
    al = (ACCLIST *) (data + sizeof(ACCINFO));

    offs = sprintf(text, "ACL1:%X,%d\n", ai -> acc1_attr, ai -> acc1_count);

    for (cnt = 0; cnt < ai -> acc1_count; cnt++)
         offs += sprintf(text + offs, "%s,%X\n", al[cnt].acl_ugname, al[cnt].acl_access);

    return strlen(text);
}


int acl_get(char *server, const char *resource, char *buffer)
{
    unsigned long datalen;
    PSZ srv = NULL;
    int rc;

    if (!acl_init( )) return -1;

    if (server) srv = server;

    acl_mkpath(path, resource);

    datalen = 0;

    rc = Net32AccessGetInfo(srv, path, 1, data, ACL_BUFFERSIZE, &datalen);

    if (rc == 0) acl_bin2text(data, buffer);

    return rc;
}


static int acl_text2bin(char *data, char *text, char *path)
{
    ACCINFO *ai;
    ACCLIST *al;
    char *ptr;
    char *ptr2;

    ULONG cnt;

    ai = (ACCINFO *) data;
    ai -> acc1_resource_name = path;

    if (sscanf(text, "ACL1:%hX,%hd", &ai -> acc1_attr, &ai -> acc1_count) != 2)
            return ERROR_INVALID_PARAMETER;

    al = (ACCLIST *) (data + sizeof(ACCINFO));
    ptr = strchr(text, '\n') + 1;

    for (cnt = 0; cnt < ai -> acc1_count; cnt++) {
        ptr2 = strchr(ptr, ',');
        strncpy(al[cnt].acl_ugname, ptr, ptr2 - ptr);
        al[cnt].acl_ugname[ptr2 - ptr] = 0;
        sscanf(ptr2 + 1, "%hx", &al[cnt].acl_access);
        ptr = strchr(ptr, '\n') + 1;
    }

    return sizeof(ACCINFO) + ai -> acc1_count * sizeof(ACCLIST);
}


int acl_set(unsigned char *server, const char *resource, char *buffer)
{
    USHORT datalen;
    unsigned char *srv = NULL;

    if (!acl_init()) return -1;

    if (server) srv = server;

    acl_mkpath(path, resource);

    ai -> acc1_resource_name = path;
    ai -> acc1_attr  = 0;
    ai -> acc1_count = 0;

    Net32AccessAdd(srv, 1, (PVOID)ai, sizeof(ACCINFO));

    /* Ignore any errors, most probably because ACL already exists. */
    /* In any such case, try updating the existing ACL. */

    datalen = acl_text2bin(data, buffer, path);

    return Net32AccessSetInfo(srv, path, 1, data, datalen, 0);
}

/* end of os2acl32.c */



