#include <stdio.h>

/* TODO(pts): Fix printf(3) in --diet to have the accuracy below. */
#define LDBL_MIN 3.36210314311209350626e-4932L  /* printf("%.21LgL\n", LDBL_MIN); Works with --eglibc, inaccurate with --uclibc, -0L with --diet, stops printing with --minilibc. */
#define DBL_MIN 2.2250738585072014e-308  /* printf("%.17g\n", DBL_MIN); Works with --eglibc, works with --uclibc, 0 with --diet, stops printing with --minilibc. */
#define FLT_MIN 1.17549435e-38F  /* printf("%.9gF\n", FLT_MIN); Works with --eglib, 0 with --diet, stops printing with --minilibc. But 1.25 does print correctly with --diet. */

int exit_code = 0;

static char expect(const char *s, char is_ok) {
  printf("is_ok=%d test=%s\n", is_ok, s);
  if (!is_ok) exit_code |= 1;
  return is_ok;
}

int main(int argc, char **argv) {
  (void)argc; (void)argv;
  /* !! TODO(pts): Why would `gcc -ansi` break some tests? */
  /* !! TODO(pts): Test type of: 1.0f * 2.0 */
  /* !! TODO(pts): Test type of: 1.0f * 2.0l */
  if (argc < 100) argc = 1;
  expect("sizeof_float", sizeof(FLT_MIN) == sizeof(float));
  expect("sizeof_double", sizeof(DBL_MIN) == sizeof(double));
  expect("sizeof_long_double", sizeof(LDBL_MIN) == sizeof(long double));
  expect("sizeof_float_times_float", sizeof(1.0f * 2.0f) == sizeof(float));
  expect("sizeof_float_times_double", sizeof(1.0f * 2.0) == sizeof(double));
  expect("sizeof_double_times_long_double", sizeof(1.0 * 2.0l) == sizeof(long double));
  expect("sizeof_long_long_times_float", sizeof(1ll * 2.0f) == sizeof(float));
  expect("sizeof_long_long_times_double", sizeof(1ll * 2.0) == sizeof(double));
  expect("sizeof_long_long_long_double", sizeof(1ll * 2.0l) == sizeof(long double));
  expect("sizeof_int", sizeof(0x7fffffff) == sizeof(int));
  expect("sizeof_long_long", sizeof(0x7fffffffffffffffll) == sizeof(long long));
  expect("sizeof_int_at_least_4", sizeof(int) >= 4);
  expect("sizeof_long_long_at_least_8", sizeof(long long) >= 8);
  expect("int_negative", -0x7fffffff < 0);
  if (sizeof(int) == 4) expect("int_positive", -0x80000000 > 0);
#ifndef __TINYC__
  expect("int_hex_back_negative", -0x80000000ll < 0);  /* !! --tcc is broken. */
  expect("int_dec_back_negative", -2147483648ll < 0);  /* !! --tcc is broken. */
#endif
  expect("long_long_negative", -0x7fffffffffffffffll < 0);
  expect("long_long_positive", -0x8000000000000000ll > 0);
  expect("long_long_back_negative", (long long)-0x8000000000000000ll < 0);
  expect("nonzero_float", FLT_MIN > 0.0f);
  expect("nonzero_double", DBL_MIN > 0.0);
  expect("nonzero_long_double", LDBL_MIN != 0.0l);
  expect("convert_double_to_float", (float)DBL_MIN == 0.0f);
  expect("convert_long_double_to_double", (double)LDBL_MIN == 0.0);
  expect("convert_long_double_to_float", (float)LDBL_MIN == 0.0f);
  expect("convert_double_to_float_and_back", (double)(float)DBL_MIN == 0.0);
  expect("convert_long_double_to_double_and_back", (long double)(double)LDBL_MIN == 0.0l);
  expect("convert_long_double_to_float_and_back", (long double)(float)LDBL_MIN == 0.0l);
  expect("convert_nonzero_float_to_double", (double)FLT_MIN > 0.0);
  expect("convert_nonzero_double_to_long_double", (long double)DBL_MIN > 0.0l);
  expect("convert_nonzero_float_to_long_double", (long double)FLT_MIN > 0.0l);
  expect("convert_min_float_to_double", (double)FLT_MIN == 1.1754943508222875e-38);
#if 1
  expect("convert_min_double_to_long_double1", (long double)DBL_MIN == 2.22507385850720138309e-308l);  /* !! --pcc --uclibc and --pcc --diet and --pcc --minilibc are broken, --pcc --eglibc is good, because strtold is only accurate in --eglibc. !! --tcc is broken. */
#endif
#ifndef __PCC__  /* !! --pcc compiler segmentation fault */
  expect("convert_min_double_to_long_double2", (long double)DBL_MIN == 2.22507385850720138e-308l + 0.00000000000000000309e-308l);  /* !! --pcc --uclibc and --pcc --diet and --pcc --minilibc are broken, --pcc --eglibc is good, because strtold is only accurate in --eglibc. !! --tcc is broken. */
#endif
  expect("convert_min_double_to_long_double3", (long double)DBL_MIN == 2.22507385850720138e-308l + 309e-328l);  /* !! --pcc --uclibc and --pcc --diet and --pcc --minilibc are broken, --pcc --eglibc is good, because strtold is only accurate in --eglibc. !! --tcc is broken. */
#ifndef __PCC__
  expect("convert_min_float_to_long_double", (long double)FLT_MIN == 1.17549435082228750797e-38l);
#endif
  expect("convert_double_to_min_float", FLT_MIN == (float)1.1754943508222875e-38);
  expect("convert_long_double_to_min_double", DBL_MIN == (double)2.22507385850720138309e-308l);
  expect("convert_long_double_to_min_float", FLT_MIN == (float)1.17549435082228750797e-38l);
  expect("convert_approx_double_to_min_float", FLT_MIN == (float)1.17549435e-38);
  expect("convert_approx_long_double_to_min_double", DBL_MIN == (double)2.2250738585072014e-308l);
  expect("convert_approx_long_double_to_min_float", FLT_MIN == (float)1.17549435e-38);
  expect("convert_int_to_max_float_significant", (int)(float)0x800001 == 0x800001);  /* 24 significant bits. */
  expect("convert_long_long_to_max_double_significant", (long long)(double)0x10000000000001ll == 0x10000000000001ll);  /* 53 significant bits in double. */
  expect("convert_max_long_long_to_double_and_back", (long long)(double)0x7ffffffffffffc00ll == 0x7ffffffffffffc00ll);  /* 53 significant bits in double. A larger long long would round it up to 2.**63, which would be overflow (thus undefined behavior) in the long long --> double conversion. */
  expect("convert_max_long_long_to_double", (double)0x7fffffffffffffffll == 9223372036854775808.0);  /* 53 significant bits in double, the long long --> double conversion rounds it up to 2.**63. */  /* !! --pcc is broken */
  /* --pcc above: Both sides of (double)0x7fffffffffffffffll == 9223372036854775808.0 are correct, but the comparison isn't correct.
  >>> float(0x7fffffffffffffff),
  (9.223372036854776e+18,)
  >>> struct.unpack('<d', struct.pack('<LL',  0,1138753536))
  (9.223372036854776e+18,)
  */
  expect("convert_max_long_long_to_long_double", (long long)(long double)0x7fffffffffffffffll == 0x7fffffffffffffffll);  /* >=63 significant bits. */
  expect("convert_int_to_min_float_significant", (int)(float)-0x800001 == -0x800001);  /* 24 significant bits. */
  expect("convert_long_long_to_min_double_significant", (long long)(double)-0x10000000000001ll == -0x10000000000001ll);  /* 53 significant bits. */
  expect("convert_min_long_long_to_long_double", (long long)(long double)(long long)-0x8000000000000000ll == (long long)-0x8000000000000000ll);  /* >=63 significant bits. */  /* The 2nd (long long) conversion is needed, see https://stackoverflow.com/q/78175534 . */
  expect("convert_unsigned__to_max_float_significant", (unsigned)(float)0x800001u == 0x800001u);  /* 24 significant bits. */
  expect("convert_unsigned_long_long_to_max_double_significant", (unsigned long long)(double)0x10000000000001ull == 0x10000000000001ull);  /* 53 significant bits. */
  expect("convert_unsigned_long_long_to_max_long_double", (unsigned long long)(long double)0xffffffffffffffffull == 0xffffffffffffffffull);  /* 64 significant bits. */
  return exit_code;
}
