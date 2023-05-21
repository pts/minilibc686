#include <fcntl.h>
#include <unistd.h>

int main(int argc, char **argv) {
  char buf[4];
  int fd;
  (void)argc; (void)argv;

  if ((fd = open(argv[0], O_RDONLY, 0666)) < 0) return 2;
  if (read(fd, buf, 4) != 4) return 3;
  /* ELF-32 executables start with "\x7f""ELF". */
  if (buf[0] != '\x7f' || buf[1] != 'E' || buf[2] != 'L' || buf[3] != 'F') return 4;
  if (close(fd) != 0) return 5;

  if ((fd = open(argv[0], O_RDONLY)) < 0) return 12;
  if (read(fd, buf, 4) != 4) return 13;
  /* ELF-32 executables start with "\x7f""ELF". */
  if (buf[0] != '\x7f' || buf[1] != 'E' || buf[2] != 'L' || buf[3] != 'F') return 14;
  if (close(fd) != 0) return 15;

  return 0;
}
