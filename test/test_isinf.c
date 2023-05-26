#include <stdio.h>

extern int mini_isinf(double x);  /* Function under test. */

static int check_count = 0;

static int check(unsigned long long l, int expected_value) {
  union { unsigned long long u; double d; } ud;
  ud.u = l;
  const int value = mini_isinf(ud.d);
  const char is_ok = value == expected_value;
  ++check_count;
  printf("is_ok=%d check_count=%d expected_value=%d value=%d\n", is_ok, check_count, expected_value, value);
  return !is_ok;
}

int main(int argc, char **argv) {
  int exit_code = 0;
  (void)argc; (void)argv;
  exit_code |= check(0x7ff0000000000000ull, 1);   /* +infinity */
  exit_code |= check(0xfff0000000000000ull, 1);   /* -infinity */
  exit_code |= check(0x7ff8001000000000ull, 0);   /* quiet inf(1) */
  exit_code |= check(0x7ff0001000000000ull, 0);   /* signalling inf(1) */
  exit_code |= check(0x3fffedcba9876543ull, 0);  /* Not  special value. */
  exit_code |= check(0xfff4edcba9876543ull, 0);
  exit_code |= check(0xffffedcba9876543ull, 0);
  exit_code |= check(0xffef000000000000ull, 0);  /* Not a special value. */
  exit_code |= check(0xfff7000000000000ull, 0);
  exit_code |= check(0x7ff1000000000001ull, 0);
  exit_code |= check(0x7ff0000000000002ull, 0);
  return exit_code;
}
