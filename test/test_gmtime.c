#include <time.h>
#include <stdio.h>
#include <sys/time.h>
#include <string.h>

struct tm *gmtime(const time_t *timep);  /* Another reference implementation (similar to reference_gmtime_r below), in uClibc. */

extern struct tm *mini_gmtime_r(const time_t *timep, struct tm *tm);  /* Function under test. */
extern struct tm *mini_gmtime(const time_t *timep);  /* Function under test. */
extern time_t mini_timegm(const struct tm *tm);  /* Function under test. */

typedef char static_assert_int_is_at_least_32_bits[sizeof(int) >= 4];
typedef char static_assert_time_t_is_signed[(time_t)-1 < 0 ? 1 : -1];

/* This is reference implementation (without optimizations) works, and
 * doesn't overflow for any sizeof(time_t). It checks for overflow/underflow
 * in tm->tm_year output. Other than that, it never overflows or underflows.
 * It assumes that that time_t is signed.
 *
 * See fyi/c_gmtime.c for a size-optimized implementation.
 *
 * This implements the inverse of the POSIX formula
 * (http://pubs.opengroup.org/onlinepubs/9699919799/basedefs/V1_chap04.html#tag_04_15)
 * for all time_t values, no matter the size, as long as tm->tm_year doesn't
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

/* Converts a Gregorian civil date-time tuple in GMT (UTC) time zone to a
 * Unix timestamp (number of seconds since the beginning of 1970 CE).
 *
 * This is not a standard C or POSIX function.
 *
 * This is reference implementation (without optimizations)
 * works, and doesn't overflow for any sizeof(time_t),
 * as long as the result fits. It doesn't check for overflow/underflow.
 * It assumes that that time_t is signed.
 *
 * If tm->yday >= 0, this implements the POSIX formula
 * (http://pubs.opengroup.org/onlinepubs/9699919799/basedefs/V1_chap04.html#tag_04_15)
 * for all time_t values, no matter the size, as long as it
 * overflow or underflow. The formula is: tm_sec + tm_min*60 + tm_hour*3600
 * + tm_yday*86400 + (tm_year-70)*31536000 + ((tm_year-69)/4)*86400 -
 * ((tm_year-1)/100)*86400 + ((tm_year+299)/400)*86400.
 *
 * It uses tm->tm_mon and tm->tm_mday iff tm->tm_yday < 0.
 */
time_t reference_timegm(const struct tm *tm) {
  int year = tm->tm_year + 1900;
  int yday = tm->tm_yday;
  int month;
  time_t y4, y100;
  if (yday < 0) {
    month = tm->tm_mon + 1;
    if (month <= 2) {
      --year;
      month += 12;
    }
    yday = (153 * month + 3) / 5 + tm->tm_mday - 398;
  } else {
    --year;
    ++yday;
  }
  y4 = year >> 2;
  y100 = y4 / 25;
  if (y4 % 25 < 0) --y100;  /* Fix quotient if y4 was negative. */
  return (365 * (time_t)year + y4 - y100 + (y100 >> 2) + (yday - 719163)) * 86400 +
      (tm->tm_hour * 60 + tm->tm_min) * 60 + tm->tm_sec;
}

static char is_tm_equal(const struct tm *a, const struct tm *b) {
  return a->tm_sec == b->tm_sec && a->tm_min == b->tm_min && a->tm_hour == b->tm_hour &&
      a->tm_mday == b->tm_mday && a->tm_mon == b->tm_mon && a->tm_year == b->tm_year &&
      a->tm_wday == b->tm_wday && a->tm_yday == b->tm_yday && a->tm_isdst == b->tm_isdst;
}

static char expect(time_t ts, char is_verbose) {
  const struct tm expected = *gmtime(&ts);
  const struct tm value = *mini_gmtime(&ts);
  const time_t ts2 = reference_timegm(&expected);
  const time_t ts3 = mini_timegm(&expected);
  struct tm expected4;
  time_t ts4, ts5;
  struct tm value2;
  char is_ok;
  reference_gmtime_r(&ts, &value2);
  expected4 = expected;
  expected4.tm_yday = -1;  /* Force tm->tm_mon and tm->tm_mday to be used in mini_timegm(...). */
  ts4 = reference_timegm(&expected4);
  ts5 = mini_timegm(&expected4);
  is_ok = (is_tm_equal(&expected, &value) && is_tm_equal(&expected, &value2) && ts2 == ts && ts3 == ts && ts4 == ts && ts5 == ts);
  if (is_verbose || !is_ok) printf("is_ok=%d ts=%d ts2=%d ts3=%d ts4=%d ts5=%d\n", is_ok, (int)ts, (int)ts2, (int)ts3, (int)ts4, (int)ts5);
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
