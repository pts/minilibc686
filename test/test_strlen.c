#include <stdio.h>
#include <string.h>

extern size_t mini_strlen(const char *s);  /* Function under test. */

static char expect(const char *s) {
  const int expected_value = strlen(s);
  const int value = mini_strlen(s);
  char is_ok = (value == expected_value);
  printf("is_ok=%d str=(%s) expected_value=%d value=%d\n", is_ok, s, expected_value, value);
  return is_ok;
}

int main(int argc, char **argv) {
  int exit_code = 0;
  (void)argc; (void)argv;
  if (!expect("")) exit_code |= 1;
  if (!expect("42")) exit_code |= 1;
  if (!expect("hello")) exit_code |= 1;
  return exit_code;
}
