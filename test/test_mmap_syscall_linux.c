#include <fcntl.h>
#include <string.h>
#include <sys/mman.h>
#include <sys/syscall.h>
#include <unistd.h>

const char big[0x4000] = {'B', 'o', 'o', 'm'};  /* A relatively large array. */

int main(int argc, char **argv) {
  int fd;
  char *p;
  (void)argc; (void)argv;
  p = (char*)syscall(SYS_mmap2, 0, 0x3000, PROT_READ | PROT_WRITE, MAP_PRIVATE | MAP_ANONYMOUS, -1, 0);
  if (!p) return 2;
  if (p[0] != '\0') return 3;
  p[0] = 'X';
  p = (char*)syscall(SYS_mremap, p, 0x3000, 0x4000, MREMAP_MAYMOVE);
  if (!p) return 4;
  if (p[0] != 'X') return 5;
  if (syscall(SYS_munmap, p, 0x4000)) return 6;
  if ((fd = open(argv[0], O_RDONLY)) < 0) return 7;
  p = (char*)syscall(SYS_mmap2, 0, 0x3000, PROT_READ, MAP_PRIVATE, fd, 0x1000 >> 12);
  if (!p) return 8;
  if (close(fd)) return 9;
  /* Find the string "Boom" in the memory-mapped image. */
  if (memcmp(p, "\x7f""ELF", 4) == 0) return 10;  /* Must not be the beginning of the program file. */
  if (syscall(SYS_munmap, p, 0x3000)) return 11;
  return 0;
}
