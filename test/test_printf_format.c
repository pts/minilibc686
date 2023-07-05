#include <stdarg.h>
#include <stdio.h>
#include <string.h>
#include <unistd.h>

extern int mini_snprintf(char *str, size_t size, const char *format, ...);  /* Function under test. */
extern int mini_vsnprintf(char *str, size_t size, const char *format, va_list ap);  /* Function under test. */

void mini_fputc_RP3(void) { _exit(121); }  /* Not called by mini_vsnprintf(...). */
void mini___M_writebuf_relax_RP1(void) {}
void mini___M_writebuf_unrelax_RP1(void) {}

int expect(const char *format, ...) {
  static char expected[0x1000], value[0x1000];
  int expected_size, value_size, value_size2;
  char is_ok;
  va_list ap;
  va_start(ap, format);
  expected_size = vsnprintf(expected, sizeof(expected), format, ap);
  memset(value, '#', expected_size + 1);  /* Overwrite it with dummy, so that strcmp(...) below can check that mini_vsnprintf(...) has overwritten it. */
  value_size = mini_vsnprintf(value, sizeof(value), format, ap);
  value_size2 = mini_vsnprintf(NULL, 0, format, ap);
  is_ok = (expected_size == value_size && expected_size == value_size2 && strcmp(expected, value) == 0);
  printf("is_ok=%d format=(%s) expected=%d(%s) value=%d,%d(%s)\n", is_ok, format, expected_size, expected, value_size, value_size2, value);
  return is_ok;
}

int main(int argc, char **argv) {
  char buf[0x20];
  int exit_code = 0;
  (void)argc; (void)argv;

  if (mini_snprintf(buf, sizeof(buf), "answer=%04d", 42) != 11) return 21;
  if (strcmp(buf, "answer=0042") != 0) return 22;
  if (mini_snprintf(buf, sizeof(buf), "short") != 5) return 23;
  if (strcmp(buf, "short") != 0) return 24;
  if (mini_snprintf(buf, 1, "short") != 5) return 25;
  if (strcmp(buf, "") != 0) return 26;
  if (mini_snprintf(buf, 10, "short") != 5) return 27;
  if (strcmp(buf, "short") != 0) return 28;
  if (mini_snprintf(buf, 3, "short") != 5) return 29;
  if (strcmp(buf, "sh") != 0) return 30;
  if (mini_snprintf(buf, 0, "short") != 5) return 31;
  if (strcmp(buf, "sh") != 0) return 32;  /* Not modified. */
  if (mini_snprintf(NULL, 0, "short") != 5) return 33;

  if (!expect("Hello!\n")) exit_code |= 1;
  if (!expect("")) exit_code |= 1;
  if (!expect("foo%%bar%%%%")) exit_code |= 1;
  if (!expect("%s", NULL)) exit_code |= 1;
  if (!expect("a%10c%cd", 42, 0)) exit_code |= 1;
  if (!expect("Hello, %s!", argc < 2 ? "World" : argv[1])) exit_code |= 1;
  if (!expect("Hello, %s!%5d.", "World", 14)) exit_code |= 1;
  if (!expect("Hello, %s!%5d.", "World", -7)) exit_code |= 1;
  if (!expect("Hello, %s!%+05d.", "World", 14)) exit_code |= 1;
  if (!expect("Hello, %s!%+05d.", "World", -7)) exit_code |= 1;
  if (!expect("Hello, %s!%+5d.", "World", 14)) exit_code |= 1;
  if (!expect("Hello, %s!%+5d.", "World", -7)) exit_code |= 1;
  if (!expect("Hello, %s!%-5d.", "World", 14)) exit_code |= 1;
  if (!expect("Hello, %s!%-5d.", "World", -7)) exit_code |= 1;
  if (!expect("Hello, %s!%-5x.", "World", 14)) exit_code |= 1;
  if (!expect("Hello, %s!%-5x.", "World", -7)) exit_code |= 1;
  if (!expect("Hello, %s!%-5X.", "World", 14)) exit_code |= 1;
  if (!expect("Hello, %s!%-5X.", "World", -7)) exit_code |= 1;
  if (!expect("Hello, %s!%-5u.", "World", 14)) exit_code |= 1;
  if (!expect("Hello, %s!%-5u.", "World", -7)) exit_code |= 1;

  return exit_code;
}
