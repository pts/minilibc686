/* by pts@fazekas.hu at Fri Jun  9 13:11:03 CEST 2023
 *
 * Compile: pathbin/minicc --noenv --gcc=4.8 -o shbin/uname tools/shbin_uname.c
 *
 * This program is equivalent to this shell script (with #!/bin/sh):
 *
 *     if test "$1" = -m; then echo i386
 *     else exec "${0%/""*}"/busybox uname "$@"
 *     fi
 */
#include <string.h>
#include <stdlib.h>
#include <unistd.h>

int work(char **argv, char *const envp[]) {
  /*char *const noenv[] = { NULL };*/  /* Does OpenWatcom put this constant to .text?? Why? */
  static char cmdbuf[1024];
  static const char busybox[] = "busybox";
  size_t psize;
  char *p0;
  if (argv[0] && argv[1] && !argv[2] && strcmp(argv[1], "-m") == 0) {
    /* Fake `uname -m' as i386. This makes some GNU Autoconf configure scripts target i386 rather than amd64 (x86_64). */
    write(1, "i386\n", 5);
    return 0;
  }
  p0 = argv[0];
  for (psize = strlen(p0); psize > 0 && p0[psize - 1] != '/'; --psize) {}
  if (psize + sizeof(busybox) > sizeof(cmdbuf)) return -2;  /* argv[0] too long. */
  memcpy(cmdbuf, p0, psize);
  memcpy(cmdbuf + psize, busybox, sizeof(busybox));  /* Including the trailing NUL. */
#if !(defined(__i386__) && defined(__linux__))
#  error The argv[-1] trick is guaranteed to work on Linux i386 only.
#endif
  argv[-1] = cmdbuf;  /* Overwrites the envp pointer argument of main. Hence the separate function (work). */
  argv[0] = "uname";
  (void)!execve(cmdbuf, argv - 1, envp);
  return -1;
}

int main(int argc, char **argv, char *const envp[]) {
  (void)argc;
  return work(argv, envp);
}
