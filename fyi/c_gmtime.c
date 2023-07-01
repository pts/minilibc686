#ifdef __SOPTCC__
  struct tm {
    int tm_sec;   /* Seconds. [0-60] (1 leap second). */
    int tm_min;   /* Minutes. [0-59]. */
    int tm_hour;  /* Hours. [0-23]. */
    int tm_mday;  /* Day.  [1-31]. */
    int tm_mon;   /* Month. [0-11]. */
    int tm_year;  /* Year - 1900. */
    int tm_wday;  /* Day of week. [0-6, Sunday==0]. */
    int tm_yday;  /* Days in year.[0-365]. */
    int tm_isdst; /* DST. [-1/0/1]. */
#  if 0
    long tm_gmtoff; /* Seconds east of UTC.  */
    const char *tm_zone; /* Timezone abbreviation. */
#  endif
  };
  typedef long time_t;
#else
#  include <time.h>  /* time_t, struct tm. */
#  include <sys/time.h>
#endif

typedef char static_assert_time_t_is_signed[(time_t)-1 < 0 ? 1 : -1];

#ifdef __WATCOMC__
#  pragma warning 201 5  /* Disable the ``unreachable code'' warning. */
#endif

/* This implementation works, and doesn't overflow for any sizeof(time_t).
 * It doesn't check for overflow/underflow in tm->tm_year output. Other than
 * that, it never overflows or underflows. It assumes that that time_t is
 * signed.
 *
 * This implements the inverse of the POSIX formula
 * (http://pubs.opengroup.org/onlinepubs/9699919799/basedefs/V1_chap04.html#tag_04_15)
 * for all time_t values, no matter the size, as long as tm->tm_year dowsn't
 * overflow or underflow. The formula is: tm_sec + tm_min*60 + tm_hour*3600
 * + tm_yday*86400 + (tm_year-70)*31536000 + ((tm_year-69)/4)*86400 -
 * ((tm_year-1)/100)*86400 + ((tm_year+299)/400)*86400.
 */
struct tm *mini_gmtime_r(const time_t *timep, struct tm *tm) {
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
  if (sizeof(time_t) > 4) {  /* Optimization. For int32_t, this would keep t intact, so we won't have to do it. This produces unreachable code. */
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
  } else {
    tm->tm_wday = (t + 24861) % 7;  /* t + 24861 >= 0. */
    /* Now: -24856 <= t <= 24855. */
    c = ((t << 2) + 102035) / 1461;
  }
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
    /* With sizeof(time_t) == 4, we have 1901 <= year <= 2038; of these
     * years only 2000 is divisble by 100, and that's a leap year, no we
     * optimize the check to `(c & 3) == 0' only.
     */
    if (!((c & 3) == 0 && (sizeof(time_t) <= 4 || c % 100 != 0 || (c + 300) % 400 == 0))) --yday;  /* These `== 0' comparisons work even if c < 0. */
  }
  tm->tm_year = c;  /* This assignment may overflow or underflow, we don't check it. Example: time_t is a huge int64_t, tm->tm_year is int32_t. */
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
