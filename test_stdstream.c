#include <string.h>
#include <stdarg.h>
#include <stdio.h>
#include <unistd.h>  /* STDIN_FILENO etc. for glibc and uClibc. */

static int my_printf1(const char *format, ...) {
  va_list ap;
  va_start(ap, format);
  return vprintf(format, ap);
}

static int my_printf2(const char *format, ...) {
  va_list ap;
  va_start(ap, format);
  return vfprintf(stdout, format, ap);
}

static int my_sprintf(char *str, const char *format, ...) {
  va_list ap;
  va_start(ap, format);
  return vsprintf(str, format, ap);
}

static int my_snprintf(char *str, size_t size, const char *format, ...) {
  va_list ap;
  va_start(ap, format);
  return vsnprintf(str, size, format, ap);
}

int main(int argc, char **argv) {
  char buf[0x20];
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

  if (sprintf(buf, "answer=%04d", 42) != 11) return 21;
  if (strcmp(buf, "answer=0042") != 0) return 22;
  if (my_sprintf(buf, "short") != 5) return 23;
  if (strcmp(buf, "short") != 0) return 24;
  if (snprintf(buf, 1, "short") != 5) return 25;
  if (strcmp(buf, "") != 0) return 26;
  if (snprintf(buf, 10, "short") != 5) return 27;
  if (strcmp(buf, "short") != 0) return 28;
  if (my_snprintf(buf, 3, "short") != 5) return 29;
  if (strcmp(buf, "sh") != 0) return 30;
  if (my_snprintf(buf, 0, "short") != 5) return 31;
  if (strcmp(buf, "sh") != 0) return 32;  /* Not modified. */
  if (my_snprintf(NULL, 0, "short") != 5) return 33;

  mode = argv[0] && argv[1] && argv[1][0] ? argv[1][0] : '.';
  if (mode == 'c') {  /* Cat: copy from stdin to stdout using getc and putc. */
    while ((c = getc(stdin)) != EOF) {
      putc(c, stdout);
    }
  } else if (mode == 'h') {  /* Cat: copy from stdin to stdout using getchar and putchar. */
    while ((c = getchar()) != EOF) {
      putchar(c);
    }
  } else {
    if (fwrite("Hel", 1, 3, stdout) != 3) return 5;
    if (fflush(stdout)) return 6;
    if (fprintf(stderr, "%s, ", "lo") != 4) return 7;
    if (my_printf1("Worl") != 4) return 8;
    if (my_printf2("d!\n") != 3) return 8;
  }
  /* Don't flush(stdout); here, libc flushall takes care of it at exit time. */
  return 0;
}
