#include <math.h>
#include <stdio.h>
#include <stdlib.h>

#ifdef __UCLIBC__
#  define mini_strtod strtod
#else
  extern double mini_strtod(const char *nptr, char **endptr);  /* Function under test. */
#endif

static char FP_EQ(double a, double b) {
  union { unsigned u[2]; double d; } xa, xb;
  xa.d = a;
  xb.d = b;
  return xa.u[0] == xb.u[0] && xa.u[1] == xb.u[1];
}

static char expect(const char *nptr) {
  char *expected_endptr;
  const double expected_value = strtod(nptr, &expected_endptr);
  const int expected_size = expected_endptr - nptr;
  char *endptr;
  const double value = mini_strtod(nptr, &endptr);
  int size = endptr - nptr;
  const double value2 = mini_strtod(nptr, NULL);
  char is_ok = (FP_EQ(value, expected_value) && size == expected_size && FP_EQ(value, expected_value));
  printf("is_ok=%d str=(%s) expected_value=%.17g expected_size=%d value=%.17g size=%d value2=%.17g\n", is_ok, nptr, expected_value, expected_size, value, size, value2);
  return is_ok;
}

static char expect2(const char *nptr, unsigned u0, unsigned u1) {
  union { unsigned u[2]; double d; } x;
  char is_ok;
  x.d = mini_strtod(nptr, NULL);
  is_ok = x.u[0] == u0 && x.u[1] == u1;
  printf("is_ok=%d value=%.17g expected_u={0x%x,0x%x} u={0x%x,0x%x}\n", is_ok, x.d, u0, u1, x.u[0], x.u[1]);
  return is_ok;
}

int main(int argc, char **argv) {
  int exit_code = 0;
  (void)argc; (void)argv;
  if (!expect("  \t4567")) exit_code |= 1;
  if (!expect("12.25")) exit_code |= 1;
  if (!expect("inf")) exit_code |= 1;
  if (!expect("  -0.0000")) exit_code |= 1;
  if (!expect(" 000")) exit_code |= 1;
  if (!expect("\t-InfINity")) exit_code |= 1;
  if (!expect("+NaN")) exit_code |= 1;
  if (!expect("  -12.345e-67")) exit_code |= 1;
  if (!expect("  +12.345678901234567E67")) exit_code |= 1;
  if (!expect("+infhello")) exit_code |= 1;
  if (!expect("+inhello")) exit_code |= 1;
  if (!expect("+infiniTyLong")) exit_code |= 1;
  if (!expect2("2.2250738585072014e-308", 0, 0x100000)) exit_code |= 1;
  return exit_code;
}
