#include <stdio.h>
#include <string.h>

extern size_t mini_strcspn(const char *s, const char *accept);  /* Function under test. */
extern char *mini_index(const char *s, int c);  /* Function under test. */

static char expect(const char *s, const char *reject) {
  size_t expected_value = strcspn(s, reject);
  size_t value = mini_strcspn(s, reject);
  char is_ok = (value == expected_value);
  printf("is_ok=%d str=(%s) expected_value=%d value=%d\n", is_ok, s, (int)expected_value, (int)value);
  return is_ok;
}

int main(int argc, char **argv) {
  int exit_code = 0;
  (void)argc; (void)argv;
  if (!expect("", "")) exit_code |= 1;
  if (!expect("", "x")) exit_code |= 1;
  if (!expect("x", "x")) exit_code |= 1;
  if (!expect("x", "y")) exit_code |= 1;
  if (!expect("hello", "foo")) exit_code |= 1;
  if (!expect("hello", "help")) exit_code |= 1;
  if (!expect("hello", "world")) exit_code |= 1;
  if (!expect("help", "hello")) exit_code |= 1;
  if (!expect("he", "hello")) exit_code |= 1;
  if (!expect("led", "hello")) exit_code |= 1;
  if (!expect("rude", "hello")) exit_code |= 1;
  if (!expect("ruby", "hello")) exit_code |= 1;
  return exit_code;
}
