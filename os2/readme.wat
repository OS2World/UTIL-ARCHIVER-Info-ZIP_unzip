03 March 2007

Unzip 5.5.2 build for eComstation with Open Watcom 1.6 and above.

To build:

Get the unzip 5.5.2 source and unzip this archive into the os2 directory.
Then from the root zip directory:

wmake -f os2\makefile.wat

This will build the executables, but if you add the target rel the
executables will be lxlite packed and zip.inf will be built.


Changes:

- os2acl.c was causing a SIGSEBV fault, so instead of tracking it down
  I changed it to 32 bit API to use only netapi32.dll.  ACL stuff is
  really untested.

- I use c source only, I tried to add in the asm code but had problems.
  However, OW with optimizations compiles in the same time as the
  gcc 3.3.5 version.


unzip552_ow.diff are changes against the original source.
