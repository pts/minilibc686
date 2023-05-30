#ifndef _SYS_TIME_H
#define _SYS_TIME_H

typedef long int time_t;
typedef long int suseconds_t;

struct timeval {
  time_t      tv_sec;     /* seconds */
  suseconds_t tv_usec;    /* microseconds */
};

struct timezone;

int utimes(const char *filename, const struct timeval *times) __asm__("mini_utimes");
int gettimeofday(struct timeval *tv, struct timezone *tz) __asm__("mini_gettimeofday");

#endif  /* _SYS_TIME_H */
