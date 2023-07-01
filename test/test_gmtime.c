#include <time.h>
#include <stdio.h>
#include <sys/time.h>
#include <string.h>

struct tm *gmtime(const time_t *timep);
extern struct tm *mini_gmtime_r(const time_t *timep, struct tm *tm);  /* Function under test. */
extern struct tm *mini_gmtime(const time_t *timep);

typedef char static_assert_int_is_at_least_32_bits[sizeof(int) >= 4];
typedef char static_assert_time_t_is_signed[(time_t)-1 < 0 ? 1 : -1];

/* This is the reference implementation (without optimizations) works, and
 * doesn't overflow for any sizeof(time_t). It checks for overflow/underflow
 * in tm->tm_year output. Other than that, it never overflows or underflows.
 * It assumes that that time_t is signed.
 *
 * See fyi/c_gmtime.c for a size-optimized implementation.
 *
 * This implements the inverse of the POSIX formula
 * (http://pubs.opengroup.org/onlinepubs/9699919799/basedefs/V1_chap04.html#tag_04_15)
 * for all time_t values, no matter the size, as long as tm->tm_year dowsn't
 * overflow or underflow. The formula is: tm_sec + tm_min*60 + tm_hour*3600
 * + tm_yday*86400 + (tm_year-70)*31536000 + ((tm_year-69)/4)*86400 -
 * ((tm_year-1)/100)*86400 + ((tm_year+299)/400)*86400.
 */
struct tm *reference_gmtime_r(const time_t *timep, struct tm *tm) {
  const time_t ts = *timep;
  time_t t = ts / 86400;
  unsigned hms = ts % 86400;  /* -86399 <= hms <= 86399. */
  time_t c, f;
  unsigned yday;  /* 0 <= yday <= 426. Also fits to an `unsigned short', but `int' is faster. */
  unsigned a;  /* 0 <= a <= 2133. Also fits to an `unsigned short', but `int' is faster. */
  if ((int)hms < 0) { --t; hms += 86400; }  /* Fix quotient and negative remainder if ts was negative (i.e. before year 1970 CE). */
  /* Now: -24856 <= t <= 24855. */
  tm->tm_sec = hms % 60;
  hms /= 60;
  tm->tm_min = hms % 60;
  tm->tm_hour = hms / 60;
  f = (t + 4) % 7;
  if (f < 0) f += 7;  /* Fix negative remainder if (t + 4) was negative. */
  /* Now 0 <= f <= 6. */
  tm->tm_wday = f;
  c = (t << 2) + 102032;
  f = c / 146097;
  if (c % 146097 < 0) --f;  /* Fix negative remainder if c was negative. */
  --f;
  t += f;
  f >>= 2;
  t -= f;
  f = (t << 2) + 102035;
  c = f / 1461;
  if (f % 1461 < 0) --c;  /* Fix negative remainder if f was negative. */
  yday = t - 365 * c - (c >> 2) + 25568;
  /* Now: 0 <= yday <= 425. */
  a = yday * 5 + 8;
  /* Now: 8 <= a <= 2133. */
  tm->tm_mon = a / 153;
  a %= 153;  /* No need to fix if a < 0, because a cannot be negative here. */
  /* Now: 2 <= tm->tm_mon <= 13. */
  /* Now: 0 <= a <= 152. */
  tm->tm_mday = 1 + a / 5;  /* No need to fix if a < 0, because a cannot be negative here. */
  /* Now: 1 <= tm->tm_mday <= 31. */
  if (tm->tm_mon >= 12) {
    tm->tm_mon -= 12;
    /* Now: 0 <= tm->tm_mon <= 1. */
    ++c;
    yday -= 366;
  } else {  /* Check for leap year (in c). */
    /* Now: 2 <= tm->tm_mon <= 11. */
    /* 1903: not leap; 1904: leap, 1900: not leap; 2000: leap */
    if (!((c & 3) == 0 && (c % 100 != 0 || (c + 300) % 400 == 0))) --yday;  /* These `== 0' comparisons work even if c < 0. */
  }
  /* Now: sizeof(time_t) != 4 || 1 <= c <= 138. */
  tm->tm_year = (c == (int)c && (sizeof(tm->tm_year) >= sizeof(int) || (c & ((1U << (sizeof(tm->tm_year) * 8 - 1)) - 1U)) == 0U)) ? c : -1;  /* Indicate overflow and underflow as -1. */
  /* Now: sizeof(time_t) != 4 || 1901 <= tm->tm_year + 1900 <= 2038. */
  /* Now: 0 <= tm->tm_mon <= 11. */
  /* Now: 0 <= yday <= 365. */
  tm->tm_yday = yday;
  tm->tm_isdst = 0;
  return tm;
}

struct tm *mini_gmtime(const time_t *timep) {
  static struct tm tm;
  return mini_gmtime_r(timep, &tm);
}

#ifndef __WATCOMC__
  struct tm *mini_localtime_r(const time_t *timep, struct tm *tm) __asm__("mini_localtime");
  struct tm *mini_localtime(const time_t *timep) __asm__("mini_gmtime");
#endif


static char is_tm_equal(const struct tm *a, const struct tm *b) {
  return a->tm_sec == b->tm_sec && a->tm_min == b->tm_min && a->tm_hour == b->tm_hour &&
      a->tm_mday == b->tm_mday && a->tm_mon == b->tm_mon && a->tm_year == b->tm_year &&
      a->tm_wday == b->tm_wday && a->tm_yday == b->tm_yday && a->tm_isdst == b->tm_isdst;
}

static char expect(time_t ts, char is_verbose) {
  const struct tm expected = *gmtime(&ts);
  const struct tm value = *mini_gmtime(&ts);
  struct tm value2;
  char is_ok;
  reference_gmtime_r(&ts, &value2);
  is_ok = (is_tm_equal(&expected, &value) && is_tm_equal(&expected, &value2));
  if (is_verbose || !is_ok) printf("is_ok=%d ts=(%d)\n", is_ok, (int)ts);
  if (!is_ok) {
    printf("  < %04d-%02d/%02d %02d:%02d:%02d %d+%d+%d\n", expected.tm_year + 1900, expected.tm_mon + 1, expected.tm_mday, expected.tm_hour, expected.tm_min, expected.tm_sec, (expected.tm_wday + 6) & 7, expected.tm_yday + 1, expected.tm_isdst);
    printf("  | %04d-%02d/%02d %02d:%02d:%02d %d+%d+%d\n", value2.tm_year + 1900,   value2.tm_mon + 1,   value2.tm_mday,   value2.tm_hour,   value2.tm_min,   value2.tm_sec,   (value2.tm_wday   + 6) & 7, value2.tm_yday + 1,   value2.tm_isdst);
    printf("  > %04d-%02d/%02d %02d:%02d:%02d %d+%d+%d\n", value.tm_year + 1900,    value.tm_mon + 1,    value.tm_mday,    value.tm_hour,    value.tm_min,    value.tm_sec,    (value.tm_wday    + 6) & 7, value.tm_yday + 1,    value.tm_isdst);
  }
  return is_ok;
}

int main(int argc, char **argv) {
  time_t ts;
  int exit_code = 0;
  (void)argc; (void)argv;
  if (!expect(0, 1)) exit_code |= 1;
  if (!expect(15398 * 86400, 1)) exit_code |= 1;
  if (!expect(15399 * 86400, 1)) exit_code |= 1;
  if (!expect(15400 * 86400, 1)) exit_code |= 1;
  if (!expect(946684800 - 86400, 1)) exit_code |= 1;
  if (!expect(946684800, 1)) exit_code |= 1;
  if (!expect(951696000, 1)) exit_code |= 1;
  if (!expect(951696000 + 86400, 1)) exit_code |= 1;
  if (!expect(-0x80000000, 1)) exit_code |= 1;
  if (!expect(-0x70000000, 1)) exit_code |= 1;
  if (!expect(-0x60000000, 1)) exit_code |= 1;
  if (!expect(-0x50000000, 1)) exit_code |= 1;
  if (!expect(-0x40000000, 1)) exit_code |= 1;
  if (!expect(-0x30000000, 1)) exit_code |= 1;
  if (!expect(-0x20000000, 1)) exit_code |= 1;
  if (!expect(-0x10000000, 1)) exit_code |= 1;
  if (!expect(0x10000000, 1)) exit_code |= 1;
  if (!expect(0x20000000, 1)) exit_code |= 1;
  if (!expect(0x7fffffff, 1)) exit_code |= 1;
  for (ts = -10000 * 86400; ts < 10000 * 86400; ts += 86400) {
    if (!expect(ts, 0)) exit_code |= 2;
  }
  return exit_code;
}
