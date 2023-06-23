struct tm {
  int tm_sec;		/* Seconds.	[0-60] (1 leap second) */
  int tm_min;		/* Minutes.	[0-59] */
  int tm_hour;		/* Hours.	[0-23] */
  int tm_mday;		/* Day.		[1-31] */
  int tm_mon;		/* Month.	[0-11] */
  int tm_year;		/* Year - 1900. */
  int tm_wday;		/* Day of week.	[0-6] */
  int tm_yday;		/* Days in year.[0-365]	*/
  int tm_isdst;		/* DST.		[-1/0/1]*/
#if 0
  long int tm_gmtoff;	/* Seconds east of UTC.  */
  const char *tm_zone;	/* Timezone abbreviation.  */
#endif
};

typedef long time_t;

typedef char static_assert_time_size[sizeof(time_t) == 4 ? 1 : -1];

typedef signed char int8_t;
typedef short int16_t;
typedef int int32_t;
typedef unsigned char uint8_t;
typedef unsigned short uint16_t;
typedef unsigned int uint32_t;

struct tm *mini_gmtime_r(const time_t *timep, struct tm *tm) {
  /* We assume that time_t is int32_t. If that breaks, not only the int
   * sizes change, but also the algorithm, because the `t' becomes incorrect
   * in `yday = t - ...'.
   */
  const int ts = *timep;
  int16_t t = ts / 86400;
  uint32_t hms = ts % 86400;
  uint8_t c, h;
  uint16_t yday, a;
  if ((int32_t)hms < 0) { --t; hms += 86400; }
  tm->tm_sec = hms % 60;
  hms /= 60;
  tm->tm_min = hms % 60;
  tm->tm_hour = hms / 60;
  tm->tm_wday = (uint16_t)(t + 24861) % 7;  /* t + 24861 >= 0. */
  /* Now: -24856 <= t <= 24855. */
  /*int32_t f = (t * 4 + 102032) // 146097 - 1;*/  /* Only if ts is 64 bits. */
  /*t += f - (f >> 2);*/  /* Only if ts is 64 bits. */
  c = (t * 20 + 510178) / 7305;
  /* Now: 1 <= c <= 137. */
  yday = t - 365 * c - (c >> 2) + 25568;
  /* Now: 0 <= yday <= 425. */
  a = yday * 100 + 178;
  /* Now: 178 <= a <= 32678. */
  tm->tm_mon = a / 3061;
  a %= 3061;
  /* Now: 3 <= m <= 14. */
  /* Now: 0 <= a <= 3060. */
  tm->tm_mday = 1 + a / 100;
  /* Now: 1 <= tm->tm_mday <= 31. */
  if (tm->tm_mon >= 12) {
    tm->tm_mon -= 12;
    ++c;
    yday -= 366;
  } else {  /* Check for leap year (in c). */
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
