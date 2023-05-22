#include <stdio.h>

int main(int argc, char **argv) {
  char mode;
  int c;
  (void)argc; (void)argv;
  if (fileno(stdin) != STDIN_FILENO) return 2;
  if (fileno(stdout) != STDOUT_FILENO) return 3;
  if (fileno(stderr) != STDERR_FILENO) return 4;
  if (fputc('*', stdin) != EOF) return 9;  /* Not open for writing. */
  if (putc('*', stdin) != EOF) return 10;  /* Not open for writing. */
  if (fgetc(stdout) != EOF) return 11;  /* Not open for reading. */
  if (getc(stdout) != EOF) return 12;  /* Not open for reading. */
  if (fgetc(stderr) != EOF) return 13;  /* Not open for reading. */
  if (getc(stderr) != EOF) return 14;  /* Not open for reading. */
  mode = argv[0] && argv[1] && argv[1][0] ? argv[1][0] : '.';
  if (mode == 'c') {  /* Cat: copy from stdin to stdout. */
    while ((c = getc(stdin)) != EOF) {
      putc(c, stdout);
    }
  } else {
    if (fwrite("Hel", 1, 3, stdout) != 3) return 5;
    if (fflush(stdout)) return 6;
    if (fprintf(stderr, "%s, ", "lo") != 4) return 7;
    if (printf("World!\n") != 7) return 8;
  }
  /* Don't flush(stdout); here, libc flushall takes care of it at exit time. */
  return 0;
}
