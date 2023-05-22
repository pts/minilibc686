#include <stdio.h>

int main(int argc, char **argv) {
  (void)argc; (void)argv;
  if (fileno(stdout) != STDOUT_FILENO) return 3;
#if 0  /* !! Test all these. */
  if (fileno(stdin) != STDIN_FILENO) return 2;
  if (fileno(stderr) != STDERR_FILENO) return 4;
  if (fprintf(stderr, "%s, ", "Hello") != 7) return 5;
  if (printf("World!\n") != 7) return 6;
#else
  if (fwrite("Hel", 1, 3, stdout) != 3) return 5;
  if (fflush(stdout)) return 6;
  if (fprintf(stdout, "%s, ", "lo") != 4) return 7;
  if (printf("World!\n") != 7) return 8;
#endif
  /* Don't flush(stdout); here, libc flushall takes care of it at exit time. */
  return 0;
}
