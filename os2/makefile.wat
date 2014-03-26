# Makefile for UnZip, UnZipSFX and fUnZip                     3 March 2007
#
# Makefile for eComstation unzip.exe using OpenWatcom 1.6 and above
#
# Michael K Greene <greenemk@cox.net>
#
# Targets:
#   all     - all files
#   release - all files and exe files lxlite compressed
#   debug   - debug build of all files
#   zipit   - all files, exe files lxlite compressed,
#             zip to acrchive unzip552.zip
#
#----------------------------------------------------------------------------

CC = wcc386
CL = wcl386
LD = wlink

MACHINE= -6s -fp6

# setup for compiling DLL if recurse
!ifndef %UNZIPDLL
COMMONDEFS = -D__ECS__ -DOS2 -DNO_ASM
!else
COMMONDEFS = -DDLL -DOS2DLL -DAPI_DOC
DLLFLAG    = -bd
!endif

!ifdef %UNZIPDEBUG
DEBUG = 1
!endif

NETAPI =  LIB os2\netapi32.lib

!ifndef DEBUG
LDDEBUG   = op el
OPT       = -otbmilera  #-otexan
DEFS      = $(COMMONDEFS)
!else
LDDEBUG   = d all op map op symf
CDEBUG    = -d3 -v
OPT       = -od
DEFS      = $(COMMONDEFS) -DDEBUG
!endif

COMMON   = -za99 -wx -e25 -zq $(OPT) $(MACHINE) -bt=OS2 -mf -bm $(DLLFLAG)

INCLUDE  = .\;..\;$(%watcom)\h;$(%watcom)\h\os2
CFLAGS   = -i=$(INCLUDE) $(DEFS) $(CDEBUG) $(COMMON)
LDFLAGS  = $(LDDEBUG) op maxe=25,st=0x50000


OBJU  = unzip.obj crc32.obj crctab.obj crypt.obj envargs.obj explode.obj &
        extract.obj fileio.obj globals.obj inflate.obj list.obj match.obj &
        process.obj ttyio.obj unreduce.obj unshrink.obj zipinfo.obj

OBJU2 = os2.obj os2acl32.obj

OBJF  = funzip.obj crc32f.obj cryptf.obj inflatef.obj globalsf.obj ttyiof.obj

OBJF2 = os2f.obj

OBJX  = unzipsf_.obj crc32_.obj crctab_.obj crypt_.obj extract_.obj &
        fileio_.obj globals_.obj inflate_.obj match_.obj process_.obj ttyio_.obj

OBJX2 = os2_.obj os2acl32_.obj


OBJDLL1 = api.obj apihelp.obj rexxhelp.obj rexxapi.obj

OBJDLL2 = unzipdll.obj crc32dll.obj crctabdll.obj cryptdll.obj envargsdll.obj &
          explodedll.obj extractdll.obj fileiodll.obj globalsdll.obj inflatedll.obj &
          listdll.obj matchdll.obj processdll.obj ttyiodll.obj unreducedll.obj &
          unshrinkdll.obj zipinfodll.obj

OBJDLL3 = os2dll.obj os2acl32dll.obj

.c:.;.\os2

.c.obj:
  $(CC) $(CFLAGS) $<

default: .SYMBOLIC
  @echo Targets:
  @echo   all     - all files
  @echo   release - all files and exe files lxlite compressed
  @echo   debug   - debug build of all files
  @echo   zipit   - all files, exe files lxlite compressed,
  @echo             zip to acrchive unzip552.zip

all: exe dll .SYMBOLIC

release: exe dll pack .SYMBOLIC

debug: exed dlld .SYMBOLIC

# build executable release
exe: unzip.exe funzip.exe unzipsfx.exe .SYMBOLIC

# build executable debug
exed: .SYMBOLIC
  set UNZIPDEBUG=1
  wmake -f os2\makefile.wat exe

# build dll release
dll: .SYMBOLIC
  set UNZIPDLL=1
  wmake -f os2\makefile.wat unzip32.dll
  wlib iunzip32.lib +unzip32.dll

# build dll debug
dlld: .SYMBOLIC
  set UNZIPDLL=1
  set UNZIPDEBUG=1
  wmake -f os2\makefile.wat unzip32.dll
  wlib iunzip32.lib +unzip32.dll

zipit: release ziparchive .SYMBOLIC

unzip.exe: $(OBJU) $(OBJU2)
  $(LD) NAME $* SYS os2v2 $(LDFLAGS) $(NETAPI) FILE {$(OBJU) $(OBJU2)}

funzip.exe: $(OBJF) $(OBJF2)
  $(LD) NAME $* SYS os2v2 $(LDFLAGS) $(NETAPI) FILE {$(OBJF)}

unzipsfx.exe: $(OBJX) $(OBJX2)
  $(LD) NAME $* SYS os2v2 $(LDFLAGS) $(NETAPI) FILE {$(OBJU) $(OBJU2)}

#dll for use with rexx
unzip32.dll: $(OBJDLL1) $(OBJDLL2) $(OBJDLL3)
  $(LD) NAME $* @os2\rexxapi.lnk $(LDDEBUG) $(NETAPI) FILE {$(OBJDLL1) $(OBJDLL2) $(OBJDLL3)}


# ***** start of misc dependencies *****

crc32f.obj:
  $(CC) $(CFLAGS) -DFUNZIP -fo=crc32f.obj crc32.c

cryptf.obj:
  $(CC) $(CFLAGS) -DFUNZIP -fo=cryptf.obj crypt.c

inflatef.obj:
  $(CC) $(CFLAGS) -DFUNZIP -fo=inflatef.obj inflate.c

globalsf.obj:
  $(CC) $(CFLAGS) -DFUNZIP -fo=globalsf.obj globals.c

ttyiof.obj:
  $(CC) $(CFLAGS) -DFUNZIP -fo=ttyiof.obj ttyio.c

os2f.obj:
  $(CC) $(CFLAGS) -DFUNZIP -fo=os2f.obj os2\os2.c

unzipsf_.obj:
  $(CC) $(CFLAGS) -DSFX -fo=unzipsf_.obj unzip.c

crc32_.obj:
  $(CC) $(CFLAGS) -DSFX -fo=crc32_.obj crc32.c

crctab_.obj:
  $(CC) $(CFLAGS) -DSFX -fo=crctab_.obj crctab.c

crypt_.obj:
  $(CC) $(CFLAGS) -DSFX -fo=crypt_.obj crypt.c

extract_.obj:
  $(CC) $(CFLAGS) -DSFX -fo=extract_.obj extract.c

fileio_.obj:
  $(CC) $(CFLAGS) -DSFX -fo=fileio_.obj fileio.c

globals_.obj:
  $(CC) $(CFLAGS) -DSFX -fo=globals_.obj globals.c

inflate_.obj:
  $(CC) $(CFLAGS) -DSFX -fo=inflate_.obj inflate.c

match_.obj:
  $(CC) $(CFLAGS) -DSFX -fo=match_.obj match.c

process_.obj:
  $(CC) $(CFLAGS) -DSFX -fo=process_.obj process.c

ttyio_.obj:
  $(CC) $(CFLAGS) -DSFX -fo=ttyio_.obj ttyio.c

os2_.obj:
  $(CC) $(CFLAGS) -DSFX -fo=os2_.obj os2\os2.c

os2acl32_.obj:
  $(CC) $(CFLAGS) -DSFX -fo=os2acl32_.obj os2\os2acl32.c

# dll dependencies
unzipdll.obj:
  $(CC) $(CFLAGS) -fo=$@ unzip.c

crc32dll.obj:
  $(CC) $(CFLAGS) -fo=$@ crc32.c

crctabdll.obj:
  $(CC) $(CFLAGS) -fo=$@ crctab.c

cryptdll.obj:
  $(CC) $(CFLAGS) -fo=$@ crypt.c

envargsdll.obj:
  $(CC) $(CFLAGS) -fo=$@ envargs.c

explodedll.obj:
  $(CC) $(CFLAGS) -fo=$@ explode.c

extractdll.obj:
  $(CC) $(CFLAGS) -fo=$@ extract.c

fileiodll.obj:
  $(CC) $(CFLAGS) -fo=$@ fileio.c

globalsdll.obj:
  $(CC) $(CFLAGS) -fo=$@ globals.c

inflatedll.obj:
  $(CC) $(CFLAGS) -fo=$@ inflate.c

listdll.obj:
  $(CC) $(CFLAGS) -fo=$@ list.c

matchdll.obj:
  $(CC) $(CFLAGS) -fo=$@ match.c

processdll.obj:
  $(CC) $(CFLAGS) -fo=$@ process.c

ttyiodll.obj:
  $(CC) $(CFLAGS) -fo=$@ ttyio.c

unreducedll.obj:
  $(CC) $(CFLAGS) -fo=$@ unreduce.c

unshrinkdll.obj:
  $(CC) $(CFLAGS) -fo=$@ unshrink.c

zipinfodll.obj:
  $(CC) $(CFLAGS) -fo=$@ zipinfo.c

os2dll.obj:
  $(CC) $(CFLAGS) -fo=$@ os2\os2.c

os2acl32dll.obj:
  $(CC) $(CFLAGS) -fo=$@ os2\os2acl32.c

# ***** end of dependencies *****

pack: .SYMBOLIC
  -lxlite unzip.exe
  -lxlite funzip.exe
  -lxlite unzipsfx.exe

ziparchive: .SYMBOLIC
  zip -9 -D -j unzip552.zip unzip.exe funzip.exe unzipsfx.exe &
                      unzip32.dll iunzip32.lib os2\rexxtest.cmd &
                      os2\zgrepapi.cmd os2\zip2exe.cmd os2\zipgrep.cmd


clean : .SYMBOLIC
  -@rm *.exe
  -@rm *.dll
  -@rm *.inf
  @%make cleanrel

cleanrel : .PROCEDURE
  -@rm iunzip32.lib
  -@rm *.obj
  -@rm *.def
  -@rm *.sym
  -@rm *.err
  -@rm *.lst
  -@rm *.map
  -@rm *.err


