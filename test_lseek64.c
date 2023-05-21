#include <fcntl.h>
#include <unistd.h>
#include <stdio.h>

int main(int argc, char **argv) {
  char buf[4];
  int fd;
  (void)argc; (void)argv;

  if ((fd = open(argv[0], O_RDONLY, 0666)) < 0) return 2;
  if (read(fd, buf, 4) != 4) return 3;
  /* ELF-32 executables start with "\x7f""ELF". */
  if (buf[0] != '\x7f' || buf[1] != 'E' || buf[2] != 'L' || buf[3] != 'F') return 4;
  if (lseek64(fd, -3, SEEK_CUR) != 1) return 5;
  if (read(fd, buf + 1, 3) != 3) return 6;
  if (buf[0] != '\x7f' || buf[1] != 'E' || buf[2] != 'L' || buf[3] != 'F') return 7;

  if (lseek64_set(fd, 1) != 0) return 5;
  if (read(fd, buf + 1, 3) != 3) return 6;
  if (buf[0] != '\x7f' || buf[1] != 'E' || buf[2] != 'L' || buf[3] != 'F') return 7;

  if (close(fd) != 0) return 9;

  return 0;
}
