#include <stdio.h>
#include <stdlib.h>

typedef char assert_double_size[sizeof(double) == 8 ? 1 : -1];
typedef char assert_long_double_size[sizeof(long double) == 10 || sizeof(long double) == 12 || sizeof(long double) == 16 ? 1 : -1];

static int signbitlp(const long double *ld) {  /* !! Must return int, not char. */
  return ((const unsigned char*)ld)[9] >> 7;
}

/*#define my_signbit(ld) signbit((long double)ld)*/  /* signbitlp(&(ld)) */
#define my_signbit(ld) signbitlp(&(ld))

static float fadd2(long double a, long double b) {
  return a + b;
}

int main(int argc, char **argv) {
  union { unsigned u[3]; long double ld; double d; } x, ldbl_max, ldbl_min, ldbl_epsilon, dbl_min, dbl_mind;
  char is_ok, is_all_ok = 1;
  (void)argc; (void)argv;
  x.u[2] = 0;

  ldbl_max.u[0] = ldbl_max.u[1] = -1; ldbl_max.u[2] = 0x7ffe;
  ldbl_min.u[0] = 0; ldbl_min.u[1] = 0x80000000U; ldbl_min.u[2] = 1;
  ldbl_epsilon.u[0] = 0; ldbl_epsilon.u[1] = 0x80000000U; ldbl_epsilon.u[2] = 0x3fc0;
  dbl_min.u[0] = 0; dbl_min.u[1] = 0x80000000U; dbl_min.u[2] = 0x3c01;
  dbl_mind.u[0] = 0; dbl_mind.u[1] = 0x100000;

#if 0  /* Mismatch with DMC libc */
  x.u[0] = 0xfffffffe; x.u[1] = 0xffffffff; x.u[2] = 0x3fbf;
  printf("got %.20Lg\n", x.ld);
  printf("exp 1.0842021724855044340e-19\n");
#endif

#if 0
  x.u[0] = 2; x.u[1] = 0x80000000U; x.u[2] = 1;
  printf("VX %.20Lg\n", x.ld);  /* VX 3.3621031431120935071e-4932 */
  x.u[0] = 0; x.u[1] = 0x80000000U; x.u[2] = 1;
  printf("VY %.20Lg\n", x.ld);  /* VX 3.3621031431120935065e-4932 */  /* This should be less, printf is wrong. */
  x.u[0] = -1; x.u[1] = 0x7fffffff; x.u[2] = 0;
  printf("VB %.20Lg\n", x.ld);  /* VB 3.3621031431120935062e-4932 */
  x.u[0] = -1; x.u[1] = -1; x.u[2] = 0;
  printf("VA %.20Lg\n", x.ld);  /* VA 6.7242062862241870124e-4932 */
  x.u[0] = 0x45642acfU; x.u[1] = 0x87c6e6c9U; x.u[2] = 0x7f94;
  printf("VL %.20Lg\n", x.ld);  /* VL 7.7777777777777777775e+4899 */
#endif

#if 0  /* EGLIBC printf("%.20Lg") and minilibc strtold values don't match, printf is slightly inaccurate! */
  {
    unsigned u;
    char buf[32];
    for (u = 52; u <= 77; ++u) {
      sprintf(buf, "3.36210314311209350%02ue-4932L", u);
      x.ld = strtold(buf, 0);  /* Random negative large value. */
      printf("%s e/h/l=0x%04x/0x%08x/0x%08x\n", buf, x.u[2] & 0xffff, x.u[1], x.u[0]);
    }
    for (u = 0; u <= 5; ++u) {
      x.u[2] = 1; x.u[1] = 0x80000000U; x.u[0] = u;
      printf("prlg=%.20Lg e/h/l=0x%04x/0x%08x/0x%08x\n", x.ld, x.u[2] & 0xffff, x.u[1], x.u[0]);
    }
  }
#endif

#ifndef __PCC__  /* !! Is it PCC uClibc 0.9.30.1 strtod(...) and strtold(...) bug. */
  x.ld = 1.0842021724855044340e-19L;  /* LDBL_EPSILON. */
  is_all_ok &= (is_ok = x.u[0] == 0 && x.u[1] == 0x80000000U && (x.u[2] & 0xffff) == 0x3fc0);
  printf("is_ok=%d u0=0x%x u1=0x%x u2=0x%x\n", is_ok, x.u[0], x.u[1], x.u[2] & 0xffff);

  x.ld = 2.2250738585072014e-308;  /* DBL_MIN. */
  is_all_ok &= (is_ok = x.u[0] == 0 && x.u[1] == 0x80000000U && (x.u[2] & 0xffff) == 0x3c01);
  printf("is_ok=%d u0=0x%x u1=0x%x u2=0x%x\n", is_ok, x.u[0], x.u[1], x.u[2] & 0xffff);

  x.d = 2.2250738585072014e-308;  /* DBL_MIN. */
  is_all_ok &= (is_ok = x.u[0] == 0 && x.u[1] == 0x100000);
  printf("is_ok=%d u0=0x%x u1=0x%x\n", is_ok, x.u[0], x.u[1]);
#endif

  x.ld = strtold("1.8000320949558996187e-4837", 0);  /* Random small value. */
  is_all_ok &= (is_ok = x.u[0] == 0xcab669c7 && x.u[1] == 0xcd557719 && (x.u[2] & 0xffff) == 0x013b);
  printf("is_ok=%d u0=0x%x u1=0x%x u2=0x%x\n", is_ok, x.u[0], x.u[1], x.u[2] & 0xffff);

  x.ld = strtold("-9.0245045105257814454e+4926", 0);  /* Random negative large value. */
  is_all_ok &= (is_ok = x.u[0] == 0xaa1d633b && x.u[1] == 0xfe857a4f && (x.u[2] & 0xffff) == 0xffed);
  printf("is_ok=%d u0=0x%x u1=0x%x u2=0x%x\n", is_ok, x.u[0], x.u[1], x.u[2] & 0xffff);

  x.ld = (double)ldbl_min.ld;
  is_all_ok &= (is_ok = x.ld == 0.0L);
  printf("is_ok=%d u0=0x%x u1=0x%x u2=0x%x\n", is_ok, x.u[0], x.u[1], x.u[2] & 0xffff);

  x.ld = fadd2(1, 1.000000000000001L);
  is_all_ok &= (is_ok = x.ld == 2.0L);
  printf("is_ok=%d u0=0x%x u1=0x%x u2=0x%x\n", is_ok, x.u[0], x.u[1], x.u[2] & 0xffff);

  x.ld = strtold("2.2250738585072014e-308", 0);
  is_all_ok &= (is_ok = (double)x.ld == dbl_mind.d);
  printf("is_ok=%d u0=0x%x u1=0x%x u2=0x%x\n", is_ok, x.u[0], x.u[1], x.u[2] & 0xffff);

  x.ld = (double)3.3621031431120935062e-4932L;
  is_all_ok &= (is_ok = x.ld == 0.0L);
  printf("is_ok=%d u0=0x%x u1=0x%x u2=0x%x\n", is_ok, x.u[0], x.u[1], x.u[2] & 0xffff);

  x.ld = (float)1.000000000000001L;
  is_all_ok &= (is_ok = x.ld == 1.0L);
  printf("is_ok=%d u0=0x%x u1=0x%x u2=0x%x\n", is_ok, x.u[0], x.u[1], x.u[2] & 0xffff);

  x.ld = strtold("2.22507385850720138309e-308", 0);
  is_all_ok &= (is_ok = x.ld == dbl_min.ld && (double)x.ld == dbl_mind.d);
  printf("is_ok=%d u0=0x%x u1=0x%x u2=0x%x\n", is_ok, x.u[0], x.u[1], x.u[2] & 0xffff);

  x.ld = strtold("2.2250738585072014e-308", 0);
  is_all_ok &= (is_ok = x.ld > dbl_min.ld && x.u[0] == 0x46 && x.u[1] == 0x80000000U && (x.u[2] & 0xffff) == 0x3c01);
  printf("is_ok=%d u0=0x%x u1=0x%x u2=0x%x\n", is_ok, x.u[0], x.u[1], x.u[2] & 0xffff);

  x.ld = strtold("inf", 0);
  is_all_ok &= (is_ok = x.ld > 0.0L && x.ld > ldbl_max.ld && x.ld == x.ld * .5);
  printf("is_ok=%d u0=0x%x u1=0x%x u2=0x%x\n", is_ok, x.u[0], x.u[1], x.u[2] & 0xffff);

  x.ld = strtold("infinity", 0);
  is_all_ok &= (is_ok = x.ld > 0.0L && x.ld > ldbl_max.ld && x.ld == x.ld * .5);
  printf("is_ok=%d u0=0x%x u1=0x%x u2=0x%x\n", is_ok, x.u[0], x.u[1], x.u[2] & 0xffff);

  x.ld = strtold("-infinity", 0);
  is_all_ok &= (is_ok = x.ld < 0.0L && x.ld < -ldbl_max.ld && x.ld == x.ld * .5);
  printf("is_ok=%d u0=0x%x u1=0x%x u2=0x%x\n", is_ok, x.u[0], x.u[1], x.u[2] & 0xffff);

  x.ld = strtold("1.18973149535723176502126385303097021e+4932", 0);
  is_all_ok &= (is_ok = x.ld == ldbl_max.ld);
  printf("is_ok=%d u0=0x%x u1=0x%x u2=0x%x\n", is_ok, x.u[0], x.u[1], x.u[2] & 0xffff);

  x.ld = strtold("1.189731495357231765e+4932", 0);
  is_all_ok &= (is_ok = x.ld == ldbl_max.ld);
  printf("is_ok=%d u0=0x%x u1=0x%x u2=0x%x\n", is_ok, x.u[0], x.u[1], x.u[2] & 0xffff);

  x.ld = strtold("1.1897314953572317650E4932", 0);
  is_all_ok &= (is_ok = x.ld == ldbl_max.ld);
  printf("is_ok=%d u0=0x%x u1=0x%x u2=0x%x\n", is_ok, x.u[0], x.u[1], x.u[2] & 0xffff);

  x.ld = strtold("1.18973149535723176498902e+4932", 0);
  is_all_ok &= (is_ok = x.ld == ldbl_max.ld);
  printf("is_ok=%d u0=0x%x u1=0x%x u2=0x%x\n", is_ok, x.u[0], x.u[1], x.u[2] & 0xffff);

  x.ld = strtold("1.18973149535723176498901e+4932", 0);
  is_all_ok &= (is_ok = x.ld > 0.0L && x.ld < ldbl_max.ld);
  printf("is_ok=%d u0=0x%x u1=0x%x u2=0x%x\n", is_ok, x.u[0], x.u[1], x.u[2] & 0xffff);

  x.ld = strtold("1.189731495357231766e+4932", 0);
  is_all_ok &= (is_ok = x.ld > ldbl_max.ld && x.ld == x.ld * .5);  /* Infinity. */
  printf("is_ok=%d u0=0x%x u1=0x%x u2=0x%x\n", is_ok, x.u[0], x.u[1], x.u[2] & 0xffff);

  x.ld = strtold(" \t3.36210314311209350626267781732175260e-4932", 0);
  is_all_ok &= (is_ok = x.ld > 0.0L && x.ld == ldbl_min.ld && x.ld < dbl_min.ld);
  printf("is_ok=%d u0=0x%x u1=0x%x u2=0x%x\n", is_ok, x.u[0], x.u[1], x.u[2] & 0xffff);

  x.ld = strtold("3.36210314311209350626267781732175260e-4932", 0);  /* "%.36Lg". */
  is_all_ok &= (is_ok = x.ld == ldbl_min.ld);
  printf("is_ok=%d u0=0x%x u1=0x%x u2=0x%x\n", is_ok, x.u[0], x.u[1], x.u[2] & 0xffff);

  x.ld = strtold("3.3621031431120935060e-4932", 0);
  is_all_ok &= (is_ok = x.ld < ldbl_min.ld);
  printf("is_ok=%d u0=0x%x u1=0x%x u2=0x%x\n", is_ok, x.u[0], x.u[1], x.u[2] & 0xffff);

  x.ld = strtold("3.3621031431120935061e-4932", 0);  /* "%.20Lg". */
  is_all_ok &= (is_ok = x.ld == ldbl_min.ld);
  printf("is_ok=%d u0=0x%x u1=0x%x u2=0x%x\n", is_ok, x.u[0], x.u[1], x.u[2] & 0xffff);

  x.ld = strtold("3.3621031431120935062e-4932", 0);
  is_all_ok &= (is_ok = x.ld == ldbl_min.ld);
  printf("is_ok=%d u0=0x%x u1=0x%x u2=0x%x\n", is_ok, x.u[0], x.u[1], x.u[2] & 0xffff);

  x.ld = strtold("3.3621031431120935064e-4932", 0);
  is_all_ok &= (is_ok = x.ld == ldbl_min.ld);
  printf("is_ok=%d u0=0x%x u1=0x%x u2=0x%x\n", is_ok, x.u[0], x.u[1], x.u[2] & 0xffff);

  x.ld = strtold("3.3621031431120935065e-4932", 0);
  is_all_ok &= (is_ok = x.ld > ldbl_min.ld);
  printf("is_ok=%d u0=0x%x u1=0x%x u2=0x%x\n", is_ok, x.u[0], x.u[1], x.u[2] & 0xffff);

  x.ld = strtold("1.08420217248550443400745280086994171e-19", 0);
  is_all_ok &= (is_ok = x.ld == ldbl_epsilon.ld);
  printf("is_ok=%d u0=0x%x u1=0x%x u2=0x%x\n", is_ok, x.u[0], x.u[1], x.u[2] & 0xffff);

  x.ld = strtold("1.0842021724855044340E-19", 0);
  is_all_ok &= (is_ok = x.ld == ldbl_epsilon.ld);
  printf("is_ok=%d u0=0x%x u1=0x%x u2=0x%x\n", is_ok, x.u[0], x.u[1], x.u[2] & 0xffff);

  x.ld = strtold("3.64519953188247460252840593361941982e-4951", 0);
  is_all_ok &= (is_ok = x.u[0] == 1 && x.u[1] == 0 && (x.u[2] & 0xffff) == 0);
  printf("is_ok=%d u0=0x%x u1=0x%x u2=0x%x\n", is_ok, x.u[0], x.u[1], x.u[2] & 0xffff);

  x.ld = strtold("2e-4951", 0);
  is_all_ok &= (is_ok = x.u[0] == 1 && x.u[1] == 0 && (x.u[2] & 0xffff) == 0);
  printf("is_ok=%d u0=0x%x u1=0x%x u2=0x%x\n", is_ok, x.u[0], x.u[1], x.u[2] & 0xffff);

  x.ld = strtold("3e-4951", 0);
  is_all_ok &= (is_ok = x.u[0] == 1 && x.u[1] == 0 && (x.u[2] & 0xffff) == 0);
  printf("is_ok=%d u0=0x%x u1=0x%x u2=0x%x\n", is_ok, x.u[0], x.u[1], x.u[2] & 0xffff);

  x.ld = strtold("4e-4951", 0);
  is_all_ok &= (is_ok = x.u[0] == 1 && x.u[1] == 0 && (x.u[2] & 0xffff) == 0);
  printf("is_ok=%d u0=0x%x u1=0x%x u2=0x%x\n", is_ok, x.u[0], x.u[1], x.u[2] & 0xffff);

  x.ld = strtold("1.8226e-4951", 0);
  is_all_ok &= (is_ok = x.u[0] == 1 && x.u[1] == 0 && (x.u[2] & 0xffff) == 0);
  printf("is_ok=%d u0=0x%x u1=0x%x u2=0x%x\n", is_ok, x.u[0], x.u[1], x.u[2] & 0xffff);

  x.ld = strtold("-1.8226e-4951", 0);
  is_all_ok &= (is_ok = x.u[0] == 1 && x.u[1] == 0 && (x.u[2] & 0xffff) == 0x8000);
  printf("is_ok=%d u0=0x%x u1=0x%x u2=0x%x\n", is_ok, x.u[0], x.u[1], x.u[2] & 0xffff);

  x.ld = strtold("+1.8225e-4951", 0);
  is_all_ok &= (is_ok = x.ld == 0.0L && !my_signbit(x.ld));
  printf("is_ok=%d u0=0x%x u1=0x%x u2=0x%x\n", is_ok, x.u[0], x.u[1], x.u[2] & 0xffff);

  x.ld = strtold("-1.8225E-4951", 0);
  is_all_ok &= (is_ok = x.ld == 0.0L && my_signbit(x.ld));  /* !! */
  printf("is_ok=%d u0=0x%x u1=0x%x u2=0x%x\n", is_ok, x.u[0], x.u[1], x.u[2] & 0xffff);

  x.ld = strtold("  \t4567", 0);
  is_all_ok &= (is_ok = x.u[0] == 0x0&& x.u[1] == 0x8eb80000&& (x.u[2] & 0xffff) == 0x400b);
  printf("is_ok=%d u0=0x%x u1=0x%x u2=0x%x\n", is_ok, x.u[0], x.u[1], x.u[2] & 0xffff);

  x.ld = strtold("12.25", 0);
  is_all_ok &= (is_ok = x.u[0] == 0x0&& x.u[1] == 0xc4000000 && (x.u[2] & 0xffff) == 0x4002);
  printf("is_ok=%d u0=0x%x u1=0x%x u2=0x%x\n", is_ok, x.u[0], x.u[1], x.u[2] & 0xffff);

  x.ld = strtold("inf", 0);
  is_all_ok &= (is_ok = x.u[0] == 0x0 && x.u[1] == 0x80000000 && (x.u[2] & 0xffff) == 0x7fff);
  printf("is_ok=%d u0=0x%x u1=0x%x u2=0x%x\n", is_ok, x.u[0], x.u[1], x.u[2] & 0xffff);

  x.ld = strtold("  -0.0000", 0);
  is_all_ok &= (is_ok = x.u[0] == 0x0 && x.u[1] == 0x0 && (x.u[2] & 0xffff) == 0x8000);
  printf("is_ok=%d u0=0x%x u1=0x%x u2=0x%x\n", is_ok, x.u[0], x.u[1], x.u[2] & 0xffff);

  x.ld = strtold(" 000", 0);
  is_all_ok &= (is_ok = x.u[0] == 0x0 && x.u[1] == 0x0 && (x.u[2] & 0xffff) == 0x0);
  printf("is_ok=%d u0=0x%x u1=0x%x u2=0x%x\n", is_ok, x.u[0], x.u[1], x.u[2] & 0xffff);

  x.ld = strtold("\t-InfINity", 0);
  is_all_ok &= (is_ok = x.u[0] == 0x0 && x.u[1] == 0x80000000 && (x.u[2] & 0xffff) == 0xffff);
  printf("is_ok=%d u0=0x%x u1=0x%x u2=0x%x\n", is_ok, x.u[0], x.u[1], x.u[2] & 0xffff);

  x.ld = strtold("+NaN", 0);
  is_all_ok &= (is_ok = x.u[0] == 0x0 && x.u[1] == 0xc0000000 && (x.u[2] & 0xffff) == 0x7fff);
  printf("is_ok=%d u0=0x%x u1=0x%x u2=0x%x\n", is_ok, x.u[0], x.u[1], x.u[2] & 0xffff);

  x.ld = strtold("-NaN", 0);  /* Negative NaN is the same as NaN. */
  is_all_ok &= (is_ok = x.u[0] == 0x0 && x.u[1] == 0xc0000000 && (x.u[2] & 0xffff) == 0x7fff);
  printf("is_ok=%d u0=0x%x u1=0x%x u2=0x%x\n", is_ok, x.u[0], x.u[1], x.u[2] & 0xffff);

  x.ld = strtold("  -12.345e-67", 0);
  is_all_ok &= (is_ok = x.u[0] == 0x4dde0c28 && x.u[1] == 0x8520d2ce && (x.u[2] & 0xffff) == 0xbf24);
  printf("is_ok=%d u0=0x%x u1=0x%x u2=0x%x\n", is_ok, x.u[0], x.u[1], x.u[2] & 0xffff);

  x.ld = strtold("  +12.345678901234567E67", 0);
  is_all_ok &= (is_ok = x.u[0] == 0x5fda11f1 && x.u[1] == 0x92895a8d && (x.u[2] & 0xffff) == 0x40e1);
  printf("is_ok=%d u0=0x%x u1=0x%x u2=0x%x\n", is_ok, x.u[0], x.u[1], x.u[2] & 0xffff);

  x.ld = strtold("  -1.0345e-4932", 0);
  is_all_ok &= (is_ok = x.u[0] == 0xfbf7ea34 && x.u[1] == 0x276286ee && (x.u[2] & 0xffff) == 0x8000);
  printf("is_ok=%d u0=0x%x u1=0x%x u2=0x%x\n", is_ok, x.u[0], x.u[1], x.u[2] & 0xffff);

  x.ld = strtold("  +1.0345678901234567E4932", 0);
  is_all_ok &= (is_ok = x.u[0] == 0xff618ea && x.u[1] == 0xde9cdc14 && (x.u[2] & 0xffff) == 0x7ffe);
  printf("is_ok=%d u0=0x%x u1=0x%x u2=0x%x\n", is_ok, x.u[0], x.u[1], x.u[2] & 0xffff);

  x.ld = strtold("+infhello", 0);
  is_all_ok &= (is_ok = x.u[0] == 0x0 && x.u[1] == 0x80000000 && (x.u[2] & 0xffff) == 0x7fff);
  printf("is_ok=%d u0=0x%x u1=0x%x u2=0x%x\n", is_ok, x.u[0], x.u[1], x.u[2] & 0xffff);

  x.ld = strtold("+inhello", 0);
  is_all_ok &= (is_ok = x.u[0] == 0x0 && x.u[1] == 0x0 && (x.u[2] & 0xffff) == 0x0);
  printf("is_ok=%d u0=0x%x u1=0x%x u2=0x%x\n", is_ok, x.u[0], x.u[1], x.u[2] & 0xffff);

  x.ld = strtold("+infiniTyLong", 0);
  is_all_ok &= (is_ok = x.u[0] == 0x0 && x.u[1] == 0x80000000 && (x.u[2] & 0xffff) == 0x7fff);
  printf("is_ok=%d u0=0x%x u1=0x%x u2=0x%x\n", is_ok, x.u[0], x.u[1], x.u[2] & 0xffff);

  x.ld = strtold("+0xf00.ba4p16000", 0);
  is_all_ok &= (is_ok = x.u[0] == 0x0 && x.u[1] == 0xf00ba400 && (x.u[2] & 0xffff) == 0x7e8a);
  printf("is_ok=%d u0=0x%x u1=0x%x u2=0x%x\n", is_ok, x.u[0], x.u[1], x.u[2] & 0xffff);

  x.ld = strtold("\r -0xf00.ba4p-16000", 0);
  is_all_ok &= (is_ok = x.u[0] == 0x0 && x.u[1] == 0xf00ba400 && (x.u[2] & 0xffff) == 0x818a);
  printf("is_ok=%d u0=0x%x u1=0x%x u2=0x%x\n", is_ok, x.u[0], x.u[1], x.u[2] & 0xffff);

  /* !! TODO(pts): Add checks for endptr and errno. */

  return !is_all_ok;
}
