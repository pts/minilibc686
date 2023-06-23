#ifndef _SYS_TIME_H
#define _SYS_TIME_H
#include <_preincl.h>

typedef long int time_t;
typedef long int suseconds_t;

struct timeval {
  time_t tv_sec;  /* seconds */
  suseconds_t tv_usec;  /* microseconds */
};

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

struct timezone;

__LIBC_FUNC(time_t, time, (time_t *tloc), __LIBC_NOATTR);  /* <time.h> in other libcs. For __MINILIBC686__, both include all. */
__LIBC_FUNC(int, utimes, (const char *filename, const struct timeval *times), __LIBC_NOATTR);
__LIBC_FUNC(int, gettimeofday, (struct timeval *tv, struct timezone *tz), __LIBC_NOATTR);
__LIBC_FUNC(struct tm *, gmtime_r, (const time_t *timep, struct tm *tm), __LIBC_NOATTR);
__LIBC_FUNC(struct tm *, localtime_r, (const time_t *timep, struct tm *tm), __LIBC_NOATTR);  /* No concept of time zones, everything is GMT, same as gmtime_r(...). */
__LIBC_FUNC(struct tm *, gmtime, (const time_t *timep), __LIBC_NOATTR);
__LIBC_FUNC(struct tm *, localtime, (const time_t *timep), __LIBC_NOATTR);  /* No concept of time zones, everything is GMT, same as gmtime_r(...). */

#endif  /* _SYS_TIME_H */
