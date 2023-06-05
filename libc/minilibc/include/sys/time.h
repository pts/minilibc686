#ifndef _SYS_TIME_H
#define _SYS_TIME_H
#include <_preincl.h>

typedef long int time_t;
typedef long int suseconds_t;

struct timeval {
  time_t tv_sec;  /* seconds */
  suseconds_t tv_usec;  /* microseconds */
};

struct timezone;

__LIBC_FUNC(time_t, time, (time_t *tloc), __LIBC_NOATTR);  /* <time.h> in other libcs. For __MINILIBC686__, both include all. */
__LIBC_FUNC(int, utimes, (const char *filename, const struct timeval *times), __LIBC_NOATTR);
__LIBC_FUNC(int, gettimeofday, (struct timeval *tv, struct timezone *tz), __LIBC_NOATTR);

#endif  /* _SYS_TIME_H */
