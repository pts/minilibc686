#include <stdio.h>
#include <stdlib.h>

extern long mini_strtol(const char *nptr, char **endptr, int base);  /* Function under test. */

extern double mini_log(double x);

static char expect(const char *nptr, int base) {
  char *expected_endptr;
  const int expected_value = strtol(nptr, &expected_endptr, base);
  const int expected_size = expected_endptr - nptr;
  char *endptr;
  const int value = mini_strtol(nptr, &endptr, base);
  int size = endptr - nptr;
  const int value2 = mini_strtol(nptr, NULL, base);
  char is_ok = (value == expected_value && size == expected_size && value2 == expected_value);
  printf("is_ok=%d str=(%s) base=%d expected_value=%d expected_size=%d value=%d size=%d value2=%d\n", is_ok, nptr, base, expected_value, expected_size, value, size, value2);
  return is_ok;
}

extern int isxx(int x);

int main(int argc, char **argv) {
  int exit_code = 0;
  (void)argc; (void)argv;
  if (!expect("  \t4567", 0)) exit_code |= 1;
  if (!expect("4567", 8)) exit_code |= 1;
  if (!expect("04567", 0)) exit_code |= 1;
  if (!expect("045678", 0)) exit_code |= 1;
  if (!expect("+4567", 9)) exit_code |= 1;
  if (!expect("  \t-42", 10)) exit_code |= 1;
  if (!expect("  \t-42", 0)) exit_code |= 1;
  if (!expect(" 0x803-", 0)) exit_code |= 1;
  if (!expect("0xbE34f-", 0)) exit_code |= 1;
  if (!expect("0XbE34f-", 16)) exit_code |= 1;
  if (!expect("\f\v0XbE34gf-", 16)) exit_code |= 1;
  if (!expect("  0aaa", 11)) exit_code |= 1;
  if (!expect("  0aba", 11)) exit_code |= 1;
  if (!expect("  0aBa", 36)) exit_code |= 1;
  if (!expect("  01o", 36)) exit_code |= 1;  /* 'o' is the largest allowed digit */
  if (!expect("  0x3zap", 36)) exit_code |= 1;
  if (!expect("  0x3zAp", 37)) exit_code |= 1;
  if (!expect(" 2147483647", 0)) exit_code |= 1;
  if (!expect("2147483648", 0)) exit_code |= 1;
  if (!expect("+2147483649", 0)) exit_code |= 1;
  if (!expect("-2147483647", 0)) exit_code |= 1;
  if (!expect("-2147483648", 0)) exit_code |= 1;
  if (!expect("-2147483649", 0)) exit_code |= 1;
  if (!expect("-3147483649", 0)) exit_code |= 1;
  return exit_code;
}
