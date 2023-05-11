#include <stdarg.h>
#include <stdio.h>

int mini_vfprintf(FILE *stream, const char *format, va_list ap);  /* Function under test. */
int mini_fputc(int c, FILE *f) { return fputc(c, f); }

int myprintf(const char *fmt, ...) {
  va_list ap;
  va_start(ap, fmt);
  return mini_vfprintf(stdout, fmt, ap);
}

int main(int argc, char **argv) {
  int i;
  (void)argc; (void)argv;
  i = (argc - 3) * 7;
#if 0  /* '+' not implemented in mini_vfprintf. */
  printf("Hello, %s!%+05d.\n", "World", i);
  myprintf("Hello, %s!%+05d.\n", "World", i);
  printf("Hello, %s!%+5d.\n", "World", i);
  myprintf("Hello, %s!%+5d.\n", "World", i);
#endif
  printf("Hello, %s!%-5d.\n", "World", i);
  myprintf("Hello, %s!%-5d.\n", "World", i);
  printf("Hello, %s!%5d.\n", "World", i);
  myprintf("Hello, %s!%5d.\n", "World", i);
  myprintf("Hello, %s!\n", NULL);
  return 0;
}
