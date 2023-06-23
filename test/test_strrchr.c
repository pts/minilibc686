#include <stdio.h>
#include <string.h>

extern char *mini_strrchr(const char *s, int c);  /* Function under test. */
extern char *mini_rindex(const char *s, int c);  /* Function under test. */

static char expect(const char *s, int c) {
  const char *expected_value = strrchr(s, c);
  const char *expected_value2 = rindex(s, c);
  const char *value = mini_strrchr(s, c);
  const char *value2 = mini_rindex(s, c);
  char is_ok = (value == expected_value && value2 == expected_value && expected_value2 == expected_value);
  printf("is_ok=%d str=(%s) expected_value=%p expected_value2=%p value=%p value2=%p\n", is_ok, s, expected_value, expected_value2, value, value2);
  return is_ok;
}

int main(int argc, char **argv) {
  int exit_code = 0;
  (void)argc; (void)argv;
  if (!expect("", 0)) exit_code |= 1;
  if (!expect("", 'x')) exit_code |= 1;
  if (!expect("hello", 'x')) exit_code |= 1;
  if (!expect("hello", '\0')) exit_code |= 1;
  if (!expect("hello", 'l')) exit_code |= 1;
  if (!expect("hello", 'o')) exit_code |= 1;
  if (!expect("hello", 'o'|0x100)) exit_code |= 1;
  return exit_code;
}
