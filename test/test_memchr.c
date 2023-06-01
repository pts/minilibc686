#include <stdio.h>
#include <string.h>

extern char *mini_memchr(const char *s, int c, size_t n);  /* Function under test. */

static char expect(const char *s, int c, size_t n) {
  const char *expected_value = memchr(s, c, n);
  const char *value = mini_memchr(s, c, n);
  char is_ok = (value == expected_value);
  printf("is_ok=%d str=(%s) chr=(%c) n=%u expected_value=%p value=%p\n", is_ok, s, c, (unsigned)n, expected_value, value);
  return is_ok;
}

int main(int argc, char **argv) {
  int exit_code = 0;
  (void)argc; (void)argv;
  if (!expect("", 0, 0)) exit_code |= 1;
  if (!expect("", 'x', 0)) exit_code |= 1;
  if (!expect("hello", 'x', 5)) exit_code |= 1;
  if (!expect("hello", 'l', 5)) exit_code |= 1;
  if (!expect("h\0llo", 'l', 3)) exit_code |= 1;
  if (!expect("hello", 'l', 4)) exit_code |= 1;
  if (!expect("hello", 'l', 3)) exit_code |= 1;
  if (!expect("hello", 'l', 2)) exit_code |= 1;
  if (!expect("hello", 'o', 5)) exit_code |= 1;
  if (!expect("hello", 'o'|0x100, 5)) exit_code |= 1;
  return exit_code;
}
