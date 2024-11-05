#include <stdarg.h>

typedef struct _FILE *FILE;
void mini_vfprintf_simple(FILE *stream, const char *format, va_list ap);  /* Function under test. */
int mini_fflush(FILE *stream);

extern FILE *mini_stdout;

int my_fprintf(FILE *stream, const char *format, ...) {
  va_list ap;
  va_start(ap, format);
  mini_vfprintf_simple(stream, format, ap);
}

int mini_isatty(int fd) { return 0; }  /* Used by mini_stdout. */

int main(int argc, char **argv) {
  my_fprintf(mini_stdout, "%s, %u%c %s%u\n", "Hello", 42, '!', "+", 0);
  return mini_fflush(mini_stdout) != 0;
}
