#include <stdarg.h>
#include <stdio.h>

int mini_fprintf(FILE *stream, const char *format, ...);  /* Function under test. !! */
int mini_fputc(int c, FILE *f) { return fputc(c, f); }

#define myprintf1(fmt, arg1      ) mini_fprintf(stdout, fmt, arg1)
#define myprintf2(fmt, arg1, arg2) mini_fprintf(stdout, fmt, arg1, arg2)

int main(int argc, char **argv) {
  int i;
  (void)argc; (void)argv;
  i = (argc - 3) * 7;
  printf("Hello, %s!%+05d.\n", "World", i);
  myprintf2("Hello, %s!%+05d.\n", "World", i);
  printf("Hello, %s!%+5d.\n", "World", i);
  printf("Hello, %s!%-5d.\n", "World", i);
  myprintf2("Hello, %s!%-5d.\n", "World", i);
  myprintf2("Hello, %s!%+5d.\n", "World", i);
  printf("Hello, %s!%5d.\n", "World", i);
  myprintf2("Hello, %s!%5d.\n", "World", i);
  myprintf1("Hello, %s!\n", NULL);
  return 0;
}
