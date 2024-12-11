/* by pts@fazekas.hu at Tue Dec 10 05:32:32 CET 2024 */

#include <fcntl.h>
#include <stdio.h>
#include <stdlib.h>
#include <time.h>
#include <unistd.h>

#ifdef __MINILIBC686__
#  define open __M_fopen_open  /* Make it compatible with: `minicc -bfreebsdx'. */
#  define malloc_DISABLED malloc_simple_unaligned
#endif


int main(int argc, char **argv) {
  char *p, *q;
  char buf[4];
  time_t tloc;
  int fd;
  printf("argc=%d argv[1]=%s\n", argc, argv[1]);
  printf("environ[0]=%s\n", environ[0]);
  printf("remove=%d, must be -1\n", remove("/dev/null/missing"));
  printf("time1=%ld\n", (long)time(0));
  time(&tloc);
  printf("time2=%ld\n", (long)tloc);
  fd = open(argv[0], O_RDONLY);
  printf("open1=%d, must be >=0\n", fd);
  printf("read1=%d, must be 4\n", (int)read(fd, buf, sizeof(buf)));
  printf("lseek1=%d, must be 10\n", (int)lseek(fd, 6, SEEK_CUR));
  printf("close1=%d, must be 0\n", close(fd));
  fd = open("/dev/null/new",  O_WRONLY | O_TRUNC | O_CREAT, 0666);
  printf("open2=%d, must be -1\n", fd);
  p = malloc(42);
  printf("malloc1=0x%lx, must not be 0x0\n", (long)p);
  fflush(stdout);
  if (p) *(int*)p = 43;
  q = malloc(4);
  printf("malloc2=0x%lx, must be different, must not be 0x0\n", (long)q);
  if (q) *(int*)q = 43;
  free(q);
  free(p);
  return 0;
}
