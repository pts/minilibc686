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
  if (fprintf(stdout, "%s, ", "Hello") != 7) return 5;
  if (printf("World!\n") != 7) return 6;
#endif
  if (fflush(stdout)) return 7;  /* !! This shouldn't be needed, because of flushall. !! */
  return 0;
}
