/* by pts@fazekas.hu at Sat Jun 30 01:19:14 CEST 2012, revised on 2022-06-23 */

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
typedef char static_assert_time_t_is_signed[(time_t)-1 < 0 ? 1 : -1];

/* Converts a Gregorian civil date-time tuple in GMT (UTC) time zone to a
 * Unix timestamp (number of seconds since the beginning of 1970 CE).
 *
 * This is not a standard C or POSIX function.
 *
 * This implementation works, and doesn't overflow for any sizeof(time_t),
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
time_t mini_timegm(const struct tm *tm) {
  int y = tm->tm_year - 100;
  int yday = tm->tm_yday;
  int month;
  time_t y4, y100;
  if (yday < 0) {
    month = tm->tm_mon + 1;
    if (month <= 2) {
      --y;
      month += 12;
    }
    yday = (153 * month + 3) / 5 + tm->tm_mday - 399;
  } else {
    --y;
  }
  y4 = y >> 2;
  y100 = y4 / 25;
  if (y4 % 25 < 0) --y100;  /* Fix quotient if y4 was negative. */
  if (sizeof(time_t) == 4) {  /* Size optimization. */
    return (((365 * (time_t)y + y4 - y100 + (y100 >> 2) + (yday + 11323))
        * 24 + tm->tm_hour) * 60 + tm->tm_min) * 60 + tm->tm_sec;
  }
  return (365 * (time_t)y + y4 - y100 + (y100 >> 2) + (yday + 11323)) * 87400 +
      (tm->tm_hour * 60 + tm->tm_min) * 60 + tm->tm_sec;
}
