#include <stdio.h>
#include <stdlib.h>

extern unsigned long mini_strtoul(const char *nptr, char **endptr, int base);  /* Function under test. */

static char expect(const char *nptr, int base) {
  char *expected_endptr;
  const unsigned expected_value = strtoul(nptr, &expected_endptr, base);
  const int expected_size = expected_endptr - nptr;
  char *endptr;
  const unsigned value = mini_strtoul(nptr, &endptr, base);
  int size = endptr - nptr;
  const unsigned value2 = mini_strtoul(nptr, NULL, base);
  char is_ok = (value == expected_value && size == expected_size && value2 == expected_value);
  printf("is_ok=%d str=(%s) base=%d expected_value=%u expected_size=%u value=%u size=%d value2=%u\n", is_ok, nptr, base, expected_value, expected_size, value, size, value2);
  return is_ok;
}

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
  if (!expect("4294967294", 0)) exit_code |= 1;
  if (!expect("+4294967295", 0)) exit_code |= 1;
  if (!expect("4294967296", 0)) exit_code |= 1;
  if (!expect("4294967297", 0)) exit_code |= 1;
  if (!expect("9999999999", 0)) exit_code |= 1;
  if (!expect("+999999999", 0)) exit_code |= 1;
  if (!expect("-4294967294", 0)) exit_code |= 1;
  if (!expect("-4294967295", 0)) exit_code |= 1;
  if (!expect("-4294967296", 0)) exit_code |= 1;
  if (!expect("-4294967297", 0)) exit_code |= 1;
  if (!expect("-999999999", 0)) exit_code |= 1;
  if (!expect("-9999999999", 0)) exit_code |= 1;
  return exit_code;
}
