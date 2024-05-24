/*
 * test_strtold.c: accuracy tests for strtold(...) for x86 f80 long double
 * by pts@fazekas.hu at Wed May 22 00:23:55 CEST 2024
 */

#include <ctype.h>
#include <stdio.h>
#include <stdlib.h>

typedef char assert_long_double_size[sizeof(long double) == 10 || sizeof(long double) == 12 || sizeof(long double) == 16 ? 1 : -1];

static int exit_code = 0;

static char expect(const char *name, const char *s, unsigned exp, unsigned high, unsigned low) {
  union { unsigned u[3]; long double ld; } x;
  char is_ok;
  const char *s2 = s;
  for (; isspace(*s2); ++s2) {}
  x.u[2] = 0;
  x.ld = strtold(s, NULL);
  x.u[2] &= 0xffff;
  is_ok = x.u[0] == low && x.u[1] == high && x.u[2] == exp;
  if (!name || !name[0]) name = s2;
  if (is_ok) {
    printf("is_ok=%d name=%s input=%s output=%.20Lg expected=e/h/l=0x%04x/0x%08x/0x%08x", is_ok, name, s2, x.ld, x.u[2], x.u[1], x.u[0]);
  } else {
    printf("is_ok=%d name=%s input=%s output=%.20Lg expected:e/h/l=0x%04x/0x%08x/0x%08x got:e/h/l=0x%04x/0x%08x/0x%08x", is_ok, name, s2, x.ld, exp, high, low, x.u[2], x.u[1], x.u[0]);
  }
  putchar('\n');
  fflush(stdout);
  if (!is_ok) exit_code |= 1;
  return is_ok;
}

int main(int argc, char **argv) {
  (void)argc; (void)argv;

  expect("", "  \t", 0, 0, 0);
  expect("0", "  \t0", 0, 0, 0);
  expect("1", "\r\n1", 0x3fff, 0x80000000U, 0);
  expect("2", "\n\v2", 0x4000, 0x80000000U, 0);
  expect("", ".25", 0x3ffd, 0x80000000U, 0);
  expect("", "12.25", 0x4002, 0xc4000000U, 0);
  expect("", "+12.249999999999999999999999999999999999999999999999999999999999999999999999", 0x4002, 0xc4000000U, 0);  /* Same as 12.25. */
  expect("", "+12.2499999999999999999", 0x4002, 0xc4000000U, 0);
  expect("", "+12.249999999999999999", 0x4002, 0xc3ffffffU, 0xffffffffU);
  expect("", "42.", 0x4004, 0xa8000000U, 0);
  expect("", "  \t+004567", 0x400b, 0x8eb80000U, 0);
  expect("", "  -0.0000", 0x8000, 0, 0);
  expect("", " 000", 0, 0, 0);
  expect("", " -0", 0x8000, 0, 0);
  expect("", " -00.000", 0x8000, 0, 0);
  expect("", "1.e2", 0x4005U, 0xc8000000U, 0);
  expect("", "  -100", 0xc005U, 0xc8000000U, 0);
  expect("", "  -12.345e-67", 0xbf24, 0x8520d2ceU, 0x4dde0c28U);
  expect("", "  +12.345678901234567E67", 0x40e1, 0x92895a8dU, 0x5fda11f1U);
  expect("", "  -1.0345e-4932", 0x8000, 0x276286eeU, 0xfbf7ea34U);
  expect("", "  +1.0345678901234567E4932", 0x7ffe, 0xde9cdc14U, 0xff618eaU);
  expect("", "+0xf00.ba4p16000", 0x7e8a, 0xf00ba400U, 0);
  expect("", "\r -0xf00.ba4p-16000", 0x818a, 0xf00ba400U, 0);
  expect("huge_exp", "1e9999999999999999999999999999999999999999999999999999999999999999999999", 0x7fff, 0x80000000U, 0);  /* Same as infinity. */
  expect("huge_neg_exp", "1e-9999999999999999999999999999999999999999999999999999999999999999999999", 0, 0, 0);  /* Same as 0. */
  expect("a_small", "+1.8000320949558996187e-4837", 0x013b, 0xcd557719U, 0xcab669c7U);
  expect("a_neg_large", "-9.0245045105257814454e+4926", 0xffed, 0xfe857a4fU, 0xaa1d633bU);

  /* Near the subnormal boundary. */
  expect("", "3.3621031431120935052e-4932L", 0, 0x7fffffffU, 0xfffffffdU);
  expect("", "3.3621031431120935053e-4932L", 0, 0x7fffffffU, 0xfffffffdU);
  expect("", "3.3621031431120935054e-4932L", 0, 0x7fffffffU, 0xfffffffeU);
  expect("", "3.3621031431120935055e-4932L", 0, 0x7fffffffU, 0xfffffffeU);
  expect("", "3.3621031431120935056e-4932L", 0, 0x7fffffffU, 0xfffffffeU);
  expect("", "3.3621031431120935057e-4932L", 0, 0x7fffffffU, 0xfffffffeU);
  expect("", "3.3621031431120935058e-4932L", 0, 0x7fffffffU, 0xffffffffU);
  expect("", "3.3621031431120935059e-4932L", 0, 0x7fffffffU, 0xffffffffU);
  expect("", "3.3621031431120935060e-4932L", 0, 0x7fffffffU, 0xffffffffU);
  expect("", "3.3621031431120935061e-4932L", 1, 0x80000000U, 0);
  expect("", "3.3621031431120935062e-4932L", 1, 0x80000000U, 0);
  expect("", "3.3621031431120935063e-4932L", 1, 0x80000000U, 0);
  expect("", "3.3621031431120935064e-4932L", 1, 0x80000000U, 0);
  expect("", "3.3621031431120935065e-4932L", 1, 0x80000000U, 1);
  expect("", "3.3621031431120935066e-4932L", 1, 0x80000000U, 1);
  expect("", "3.3621031431120935067e-4932L", 1, 0x80000000U, 1);
  expect("", "3.3621031431120935068e-4932L", 1, 0x80000000U, 1);
  expect("", "3.3621031431120935069e-4932L", 1, 0x80000000U, 2);
  expect("", "3.3621031431120935070e-4932L", 1, 0x80000000U, 2);
  expect("", "3.3621031431120935071e-4932L", 1, 0x80000000U, 2);
  expect("", "3.3621031431120935072e-4932L", 1, 0x80000000U, 3);
  expect("", "3.3621031431120935073e-4932L", 1, 0x80000000U, 3);
  expect("", "3.3621031431120935074e-4932L", 1, 0x80000000U, 3);
  expect("", "3.3621031431120935075e-4932L", 1, 0x80000000U, 3);
  expect("", "3.3621031431120935076e-4932L", 1, 0x80000000U, 4);
  expect("", "3.3621031431120935077e-4932L", 1, 0x80000000U, 4);

  expect("FLT_EPSILON", "1.19209290e-07F", 0x3fe8, 0x80000008U, 0x17a7e462U);
  expect("FLT_MIN", "1.17549435e-38F", 0x3f80, 0xfffffffcU, 0xfedd426eU);
  expect("FLT_MAX", "3.40282347e+38F", 0x407e, 0xffffff04U, 0x8ff9eb4eU);
  expect("DBL_EPSILON", "2.2204460492503131e-16", 0x3fcbU, 0x80000000U, 0x50);
  expect("DBL_MIN",     "2.2250738585072014e-308",     0x3c01, 0x80000000U, 0x46);  /* Fewer digits is not enough. */
  expect("DBL_MIN_dbl", "2.22507385850720138309e-308", 0x3c01, 0x80000000U, 0);
  expect("DBL_MAX", "1.7976931348623157e+308", 0x43fe, 0xffffffffU, 0xfffff7acU);
  expect("LDBL_EPSILON", "1.0842021724855044340e-19L", 0x3fc0, 0x80000000U, 0);
  expect("LDBL_EPSILON_long", "1.08420217248550443400745280086994171e-19L", 0x3fc0, 0x80000000U, 0);
  expect("LDBL_MIN", "3.3621031431120935062e-4932L", 0x0001, 0x80000000U, 0);
  expect("LDBL_MIN_twice", "6.7242062862241870124e-4932L", 2, 0x80000000U, 0);
  expect("LDBL_MIN_long", "3.36210314311209350626267781732175260e-4932L", 0x0001, 0x80000000U, 0);
  expect("LDBL_small_zero", "1.8225e-4951", 0, 0, 0);
  expect("LDBL_small_subnormal1", "1.8226e-4951", 0, 0, 1);
  expect("LDBL_small_subnormal2", "-1.8226e-4951", 0x8000, 0, 1);
  expect("LDBL_small_subnormal3", "2e-4951", 0, 0, 1);
  expect("LDBL_small_subnormal4", "3e-4951", 0, 0, 1);
  expect("LDBL_small_subnormal5", "3.64519953188247460252840593361941982e-4951", 0, 0, 1);
  expect("LDBL_small_subnormal6", "4e-4951", 0, 0, 1);
  expect("LDBL_MAX", "1.1897314953572317650e+4932L", 0x7ffe, 0xffffffffU, 0xffffffffU);
  expect("LDBL_MAX_short", "1.189731495357231765e+4932L", 0x7ffe, 0xffffffffU, 0xffffffffU);
  expect("LDBL_MAX_long1", "1.18973149535723176498902e+4932", 0x7ffe, 0xffffffffU, 0xffffffffU);
  expect("LDBL_MAX_long1_smaller", "1.18973149535723176498901e+4932", 0x7ffe, 0xffffffffU, 0xfffffffeU);
  expect("LDBL_MAX_long2", "1.18973149535723176502126385303097021e+4932L", 0x7ffe, 0xffffffffU, 0xffffffffU);
  expect("LDBL_MAX_more1", "1.189731495357231765054e+4932L", 0x7fff, 0x80000000U, 0);  /* Same as infinity. */
  expect("LDBL_MAX_more2", "1.189731495357231766e+4932", 0x7fff, 0x80000000U, 0);  /* Same as infinity. */

  expect("inf", "iNf", 0x7fff, 0x80000000, 0);
  expect("-inf", " -inF", 0xffff, 0x80000000, 0);
  expect("+inf", " +InF", 0x7fff, 0x80000000, 0);
  expect("", "+inx", 0, 0, 0);  /* Parse error. */
  expect("infinity", " inFInity", 0x7fff, 0x80000000, 0);
  expect("-infinity", "-iNFINitY", 0xffff, 0x80000000, 0);
  expect("nan", "NaN", 0x7fff, 0xc0000000, 0);
  expect("-nan", "\t -naN", 0x7fff, 0xc0000000, 0);  /* Positive, even if - is specified. */
  expect("+nan", "\t +NaN", 0x7fff, 0xc0000000, 0);

  expect("", "0x1p-1", 0x3ffeU, 0x80000000U, 0);
  expect("", "0x1p-1000000000000000000000000000000", 0x0000U, 0x00000000U, 0);
  expect("", "0x1p0", 0x3fffU, 0x80000000U, 0);
  expect("", "0x10P0", 0x4003U, 0x80000000U, 0);
  expect("", "0x1p-1023", 0x3c00U, 0x80000000U, 0);
  expect("", "0x1.000002p0", 0x3fffU, 0x80000100U, 0);
  expect("", "0x1.000003p0", 0x3fffU, 0x80000180U, 0);
  expect("", "0x1.000001p0", 0x3fffU, 0x80000080U, 0);
  expect("", "0x1.000001000000001p0", 0x3fffU, 0x80000080U, 0x00000008U);
  expect("", "0x100000000000008p0", 0x4037U, 0x80000000U, 0x00000400U);
  expect("", "0x100000000000008.p0", 0x4037U, 0x80000000U, 0x00000400U);
  expect("", "0x100000000000008.00p0", 0x4037U, 0x80000000U, 0x00000400U);
  expect("", "0x10000000000000800p0", 0x403fU, 0x80000000U, 0x00000400U);
  expect("", "0x10000000000000801p0", 0x403fU, 0x80000000U, 0x00000400U);
  expect("", "0x800000000000ab120p32", 0x4062U, 0x80000000U, 0x0000ab12U);
  expect("", "0x800000000000ab127p32", 0x4062U, 0x80000000U, 0x0000ab12U);
  expect("", "0x800000000000ab128p32", 0x4062U, 0x80000000U, 0x0000ab12U);  /* Rounds down to nearest even. */
  expect("", "0x800000000000ab129p32", 0x4062U, 0x80000000U, 0x0000ab13U);
  expect("", "0x800000000000ab130p-64", 0x4002U, 0x80000000U, 0x0000ab13U);
  expect("", "0x800000000000ab137p-64", 0x4002U, 0x80000000U, 0x0000ab13U);
  expect("", "0x800000000000ab138p-64", 0x4002U, 0x80000000U, 0x0000ab14U);  /* Rounds up to nearest even. */
  expect("", "0x800000000000ab139p-64", 0x4002U, 0x80000000U, 0x0000ab14U);
  expect("", "0x10000000000000800.0000000000001p0", 0x403fU, 0x80000000U, 0x00000400U);
  expect("", "0x10000000000001800p0", 0x403fU, 0x80000000U, 0x00000c00U);
  expect("", "0x1.fffffep126", 0x407dU, 0xffffff00U, 0);
  expect("", "0x1.ffffffp126", 0x407dU, 0xffffff80U, 0);
  expect("", "0x1.fffffep127", 0x407eU, 0xffffff00U, 0);
  expect("", "0x1.ffffffp127", 0x407eU, 0xffffff80U, 0);  /* Rounds up to INFINITY for float. */
  expect("", "0x1.fffffffffffffp1022", 0x43fdU, 0xffffffffU, 0xfffff800U);
  expect("", "0x1.fffffffffffff8p1022", 0x43fdU, 0xffffffffU, 0xfffffc00U);  /* Rounds up for double. */
  expect("", "0x1.fffffffffffffp1023", 0x43feU, 0xffffffffU, 0xfffff800U);
  expect("", "0x1.fffffffffffff8p1023", 0x43feU, 0xffffffffU, 0xfffffc00U);  /* Rounds up to INFINITY for double. */
  expect("", "0x1.fffffffffffffffep16382", 0x7ffdU, 0xffffffffU, 0xffffffffU);
  expect("", "0x1.ffffffffffffffffp16382", 0x7ffeU, 0x80000000U, 0);  /* Rounds up for long double. */
  expect("", "0x1.fffffffffffffffep16383", 0x7ffeU, 0xffffffffU, 0xffffffffU);
  expect("", "0x1.ffffffffffffffffp16383", 0x7fffU, 0x80000000U, 0);  /* Rounds up to INFINITY for long double. */
  expect("hex_large_subnormal1", "0x7fffffffffffffffp-16446", 0, 0x40000000U, 0);
  expect("hex_large_subnormal2", "0x7fffffffffffffffp-16445", 0, 0x7fffffffU, 0xffffffffU);
  expect("hex_large_subnormal3", "0x7fffffffffffffff.7p-16445", 0, 0x7fffffffU, 0xffffffffU);
  expect("hex_large_subnormal4", "0x7fffffffffffffff.8p-16445", 1, 0x80000000U, 0);  /* Rounds up to nearest even. */
  expect("hex_large_subnormal5", "0x7fffffffffffffff.fp-16445", 1, 0x80000000U, 0);
  expect("hex_large_subnormal6", "0x7fffffffffffffff.7p-16445", 0, 0x7fffffffU, 0xffffffffU);
  expect("hex_subnormal0", "0x1p-16445", 0, 0, 1);
  expect("hex_subnormal1", "0x2p-16445", 0, 0, 2);
  expect("hex_subnormal2", "0x4p-16445", 0, 0, 4);
  expect("hex_subnormal3", "0x7p-16449", 0, 0, 0);  /* Rounds down. */
  expect("hex_subnormal4", "0x8p-16449", 0, 0, 0);  /* Rounds down to nearest even. */
  expect("hex_subnormal5", "0x9p-16449", 0, 0, 1);  /* Rounds up. */
  expect("hex_subnormal6", "0xfp-16449", 0, 0, 1);  /* Rounds up. */
  expect("hex_subnormal7", "0xf.fffffffffffffff8p-16449", 0, 0, 1);  /* Rounds up. */
  expect("hex_subnormal8", "0x4.7p-16445", 0, 0, 4);
  expect("hex_subnormal9", "0x4.8p-16445", 0, 0, 4);  /* Rounds down to nearest even. */
  expect("hex_subnormala", "0x4.9p-16445", 0, 0, 5);
  expect("hex_subnormalb", "0x5.7p-16445", 0, 0, 5);
  expect("hex_subnormalc", "0x5.8p-16445", 0, 0, 6);  /* Rounds up to nearest even. */
  expect("hex_subnormald", "0x5.9p-16445", 0, 0, 6);
  printf("is_all_ok=%d\n", !exit_code);
  return exit_code;
}
