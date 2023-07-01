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

typedef char static_assert_int_is_at_least_32_bits[sizeof(int) >= 4];
typedef char static_assert_time_t_is_32_bits[sizeof(time_t) == 4];
typedef char static_assert_time_t_is_signed[(time_t)-1 < 0 ? 1 : -1];

/* We assume that time_t is int32_t. If that breaks, not only the int sizes
 * change, but also the algorithm, because the `t' becomes incorrect in
 * `yday = t - ...'. See fyi/c_gmtime.c for an implementation without a
 * constraint on sizeof(time_t).
 *
 * This implements the inverse of the POSIX formula
 * (http://pubs.opengroup.org/onlinepubs/9699919799/basedefs/V1_chap04.html#tag_04_15)
 * for 32-bit signed time_t values. The formula is: tm_sec + tm_min*60 + tm_hour*3600
 * + tm_yday*86400 + (tm_year-70)*31536000 + ((tm_year-69)/4)*86400 -
 * ((tm_year-1)/100)*86400 + ((tm_year+299)/400)*86400.
 */
struct tm *mini_gmtime_r(const time_t *timep, struct tm *tm) {
  const int ts = *timep;
  time_t t = ts / 86400;  /* Smaller code than uint16_t. Declaring it `unsigned' would make it 2 bytes larger. */
  unsigned hms = ts % 86400;  /* This needs sizeof(int) >= 4. */
  time_t c;  /* Smaller code than uint8_t. */
  unsigned yday;  /* Smaller code than uint16_t. */
  unsigned a;  /* Smaller code than uint16_t. */
  if ((int)hms < 0) { --t; hms += 86400; }
  tm->tm_sec = hms % 60;
  hms /= 60;
  tm->tm_min = hms % 60;
  tm->tm_hour = hms / 60;
  tm->tm_wday = (t + 24861) % 7;  /* t + 24861 >= 0. */
  /* Now: -24856 <= t <= 24855. */
  /*int32_t f = (t * 4 + 102032) // 146097 - 1;*/  /* Only if ts is 64 bits. */
  /*t += f - (f >> 2);*/  /* Only if ts is 64 bits. */
  c = ((t << 2) + 102035) / 1461;
  /* Now: 1 <= c <= 137. */
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
    /*if ((c & 3) != 0 || (h = (c >> 2) % 100) == 25 || h == 50 || h == 75) --yday;*/  /* Use this instead of the next line if ts is 64 bits. */
    /* In the year range 1901 <= year <= 2038, only 2000 is divisble by 100, and that's a leap year, no special treatment needed. */
    if ((c & 3) != 0) --yday;
  }
  /* Now: 1 <= c <= 138. */
  tm->tm_year = c;
  /* Now: 1901 <= tm->tm_year + 1900 <= 2038. */
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
