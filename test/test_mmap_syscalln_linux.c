#include <fcntl.h>
#include <string.h>
#include <sys/mman.h>
#include <sys/syscall.h>
#include <unistd.h>

const struct {
  char padding[0x1000];  /* Make sure that msg is not in the first 0x1000  bytes of the file. */
  char msg[0x2000];
} mydata = {{0}, "Catch me if you can!"};  /* Large so that the mapping is long enough. */

int main(int argc, char **argv) {
  int fd;
  char *p, *q;
  (void)argc; (void)argv;
  p = (char*)syscall6(SYS_mmap2, 0, 0x3000, PROT_READ | PROT_WRITE, MAP_PRIVATE | MAP_ANONYMOUS, -1, 0);
  if (!p) return 2;
  if (p[0] != '\0') return 3;
  p[0] = 'X';
  p = (char*)syscall4(SYS_mremap, (size_t)p, 0x3000, 0x4000, MREMAP_MAYMOVE);
  if (!p) return 4;
  if (p[0] != 'X') return 5;
  if (syscall2(SYS_munmap, (size_t)p, 0x4000)) return 6;
  if ((fd = (int)syscall3(SYS_open, (size_t)argv[0], O_RDONLY, 0666)) < 0) return 7;
  p = (char*)syscall6(SYS_mmap2, 0, 0x3000, PROT_READ, MAP_PRIVATE, fd, 0x1000 >> 12);
  if (!p) return 8;
  if (syscall1(SYS_close, fd)) return 9;
  /* Find the string "Boom" in the memory-mapped image. */
  if (memcmp(p, "\x7f""ELF", 4) == 0) return 10;  /* Must not be the beginning of the program file. */
  /* Find the string msg in the memory-mapped image. */
  for (q = p + ((unsigned)mydata.msg & 0xfff); q < p + 0x3000; q += 0x1000) {
    if (memcmp(q, mydata.msg, 64) == 0) break;
  }
  if (q >= p + 0x3000) return 11;  /* msg not found. */
  if (syscall2(SYS_munmap, (size_t)p, 0x3000)) return 11;
  return 0;
}
