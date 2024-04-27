#ifdef __WATCOMC__
#  define __extension__
#  ifdef __MINILIBC686__
#    define mini_div mini_div_RP0W
#    define mini_ldiv mini_ldiv_RP0W
#    define mini_lldiv mini_lldiv_RP0W
#  endif
#endif
#ifndef __MINILIBC686__
  #define mini_write write
  #define mini_strlen strlen
  #define mini_div div
  #define mini_ldiv ldiv
  #define mini_lldiv lldiv
#endif

#ifdef CONFIG_LIBC_H
#  include <stdlib.h>
#else
  #define NULL ((void*)0)
  /* long works for both __i386__ and __amd64__. */
  typedef unsigned long size_t;
  typedef int long ssize_t;
  typedef struct { int quot, rem; } div_t;
  typedef struct { long quot, rem; } ldiv_t;
  typedef struct { __extension__ long long quot, rem; } lldiv_t;
  div_t mini_div(int numerator, int denominator);
  ldiv_t mini_ldiv(long numerator, long denominator);
  __extension__ lldiv_t mini_lldiv(long long numerator, long long denominator);
#endif

ssize_t mini_write(int fd, const void *buf, size_t count);
size_t mini_strlen(const char *s);

static const char *format_ll_dec(long long i) {
  static char buf[sizeof(i) == 8 ? 22 : sizeof(i) * 3 + 2];
  char *p = buf + sizeof(buf) - 1;
  const char is_negative = i < 0;
  unsigned long long u = is_negative ? -i : i;
  *p = '\0';
  do {
    *--p = (char)(u % 10) + '0';
    u /= 10;
  } while (u != 0);
  if (is_negative) *--p = '-';
  return p;
}

static char is_equal(const char *a, const char *b) {
  for (; *a == *b && *a != '\0'; ++a, ++b) {}
  return *a == *b;
}

static int check_equal(const char *prefix, long long v, const char *b) {
  const char *a = format_ll_dec(v);
  if (!is_equal(a, b)) {
    (void)!mini_write(1, prefix, mini_strlen(prefix));
    (void)!mini_write(1, a, mini_strlen(a));
    (void)!mini_write(1, " != ", 4);
    (void)!mini_write(1, b, mini_strlen(b));
    (void)!mini_write(1, "\n", 1);
    return 1;
  }
  return 0;
}

static int check_equal2(const char *prefix, long long v, long long w) {
  const char *tmp = format_ll_dec(w);
  char buf[sizeof(w) == 8 ? 22 : sizeof(w) * 3 + 2], *p;
  for (p = buf; *tmp != '\0'; *p++ = *tmp++) {}
  *p = '\0';
  return check_equal(prefix, v, buf);
}

/* !! SUXX: tcc generates code for memcpy (not mini_memcpy). */
#ifdef __TINYC__
__attribute__((__weak__)) void *memcpy(void *dst, const void *src, size_t n) {
  for (; n > 0; *(char*)dst = *(char*)src, dst = (char*)dst + 1, src = (char*)src + 1, --n) {}
  return dst;
}
#endif

int main(int argc, char **argv) {
  int errc = 0;
  div_t dr;
  ldiv_t ldr;
  lldiv_t lldr;
  const long long lla = 1234567890123456789LL;
  const long long llb = 9876543210LL;
  const long long llq = 124999998LL;
  const long long llr = 8626543209LL;
  const long la = 2109876543L;
  const long lb = 65432L;
  const long lq = 32245L;
  const long lr = 21703L;
  (void)argc; (void)argv;

  errc += check_equal("lla ", lla, "1234567890123456789");
  errc += check_equal("llb ", llb, "9876543210");
  errc += check_equal("llq ", llq, "124999998");
  errc += check_equal("llr ", llr, "8626543209");
  errc += check_equal("-lla ", -lla, "-1234567890123456789");
  errc += check_equal("-llb ", -llb, "-9876543210");
  errc += check_equal("~llq ", ~llq, "-124999999");
  errc += check_equal("~llr ", ~llr, "-8626543210");
  errc += check_equal2("/ ", lla / llb, llq);
  errc += check_equal2("% ", lla % llb, llr);
  lldr.quot = lldr.rem = 0;
  lldr = mini_lldiv(lla, llb);
  errc += check_equal2("lldiv/ ", lldr.quot, llq);
  errc += check_equal2("lldiv% ", lldr.rem,  llr);
  lldr.quot = lldr.rem = 0;
  lldr = mini_lldiv(-lla, llb);
  errc += check_equal2("lldiv-/ ", lldr.quot, -lla / llb);
  errc += check_equal2("lldiv-% ", lldr.rem,  -lla % llb);
  lldr.quot = lldr.rem = 0;
  lldr = mini_lldiv(lla, -llb);
  errc += check_equal2("lldiv/- ", lldr.quot, lla / -llb);
  errc += check_equal2("lldiv%- ", lldr.rem,  lla % -llb);
  lldr.quot = lldr.rem = 0;
  lldr = mini_lldiv(-lla, -llb);
  errc += check_equal2("lldiv-/- ", lldr.quot, -lla / -llb);
  errc += check_equal2("lldiv-%- ", lldr.rem,  -lla % -llb);

  errc += check_equal("la ", la, "2109876543");
  errc += check_equal("lb ", lb, "65432");
  errc += check_equal("lq ", lq, "32245");
  errc += check_equal("lr ", lr, "21703");
  errc += check_equal("-la ", -la, "-2109876543");
  errc += check_equal("-lb ", -lb, "-65432");
  errc += check_equal("~lq ", ~lq, "-32246");
  errc += check_equal("~lr ", ~lr, "-21704");
  errc += check_equal2("/ ", la / lb, lq);
  errc += check_equal2("% ", la % lb, lr);
  ldr.quot = ldr.rem = 0;
  ldr = mini_ldiv(la, lb);
  errc += check_equal2("ldiv/ ", ldr.quot, lq);
  errc += check_equal2("ldiv% ", ldr.rem,  lr);
  ldr.quot = ldr.rem = 0;
  ldr = mini_ldiv(-la, lb);
  errc += check_equal2("ldiv-/ ", ldr.quot, -la / lb);
  errc += check_equal2("ldiv-% ", ldr.rem,  -la % lb);
  ldr.quot = ldr.rem = 0;
  ldr = mini_ldiv(la, -lb);
  errc += check_equal2("ldiv/- ", ldr.quot, la / -lb);
  errc += check_equal2("ldiv%- ", ldr.rem,  la % -lb);
  ldr.quot = ldr.rem = 0;
  ldr = mini_ldiv(-la, -lb);
  errc += check_equal2("ldiv-/- ", ldr.quot, -la / -lb);
  errc += check_equal2("ldiv-%- ", ldr.rem,  -la % -lb);

  dr.quot = dr.rem = 0;
  dr = mini_div(la, lb);
  errc += check_equal2("ldiv/ ", dr.quot, lq);
  errc += check_equal2("ldiv% ", dr.rem,  lr);
  dr.quot = dr.rem = 0;
  dr = mini_div(-la, lb);
  errc += check_equal2("ldiv-/ ", dr.quot, -la / lb);
  errc += check_equal2("ldiv-% ", dr.rem,  -la % lb);
  dr.quot = dr.rem = 0;
  dr = mini_div(la, -lb);
  errc += check_equal2("ldiv/- ", dr.quot, la / -lb);
  errc += check_equal2("ldiv%- ", dr.rem,  la % -lb);
  dr.quot = dr.rem = 0;
  dr = mini_div(-la, -lb);
  errc += check_equal2("ldiv-/- ", dr.quot, -la / -lb);
  errc += check_equal2("ldiv-%- ", dr.rem,  -la % -lb);

  return errc;
}
