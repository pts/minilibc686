#include <stdio.h>
#include <string.h>

extern char *mini_strstr(const char *haystack, const char *needle);  /* Function under test. */

static char expect(const char *haystack, const char *needle) {
  const char *expected_value = strstr(haystack, needle);
  const char *value = mini_strstr(haystack, needle);
  char is_ok = (value == expected_value);
  printf("is_ok=%d hatstack=(%s) needle=(%s) expected_value=(%s) value=(%s)\n", is_ok, haystack, needle, expected_value, value);
  return is_ok;
}

int main(int argc, char **argv) {
  int exit_code = 0;
  (void)argc; (void)argv;
  if (!expect("", "")) exit_code |= 1;
  if (!expect("", "x")) exit_code |= 1;
  if (!expect("x", "")) exit_code |= 1;
  if (!expect("", "hello")) exit_code |= 1;
  if (!expect("hello", "")) exit_code |= 1;
  if (!expect("hello", "x")) exit_code |= 1;
  if (!expect("hello", "l")) exit_code |= 1;
  if (!expect("hello", "o")) exit_code |= 1;
  if (!expect("hel", "hello")) exit_code |= 1;
  if (!expect("hehello", "hel")) exit_code |= 1;
  if (!expect("hello", "hel")) exit_code |= 1;
  if (!expect("lo", "hello")) exit_code |= 1;
  if (!expect("hello", "lo")) exit_code |= 1;
  if (!expect("ll", "hello")) exit_code |= 1;
  if (!expect("hello", "ll")) exit_code |= 1;
  if (!expect("hellllo!", "llo")) exit_code |= 1;
  if (!expect("llo", "hellllo!")) exit_code |= 1;
  return exit_code;
}
