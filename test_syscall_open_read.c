#include <unistd.h>
#include <sys/syscall.h>
#include <fcntl.h>

int main(int argc, char **argv) {
  char buf[4];
  int fd;
  (void)argc; (void)argv;

  syscall(SYS_mmap, 1, 2, 3, 4, 5, 6, 7);

  if ((fd = syscall3(SYS_open, (long)argv[0], O_RDONLY, 0666)) < 0) return 2;
  if (syscall3(SYS_read, fd, (long)buf, 4) != 4) return 3;
  /* ELF-32 executables start with "\x7f""ELF". */
  if (buf[0] != '\x7f' || buf[1] != 'E' || buf[2] != 'L' || buf[3] != 'F') return 4;
  if (syscall1(SYS_close, fd) != 0) return 5;

  if ((fd = syscall(SYS_open, argv[0], O_RDONLY)) < 0) return 12;
  if (syscall(SYS_read, fd, buf, 4) != 4) return 13;
  /* ELF-32 executables start with "\x7f""ELF". */
  if (buf[0] != '\x7f' || buf[1] != 'E' || buf[2] != 'L' || buf[3] != 'F') return 14;
  if (syscall(SYS_close, fd) != 0) return 15;

  return 0;
}
