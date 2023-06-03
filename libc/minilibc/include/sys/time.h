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

__LIBC_FUNC(int, utimes, (const char *filename, const struct timeval *times),);
__LIBC_FUNC(int, gettimeofday, (struct timeval *tv, struct timezone *tz),);

#endif  /* _SYS_TIME_H */
