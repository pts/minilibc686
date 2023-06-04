#ifndef _MATH_H
#define _MATH_H
#include <_preincl.h>

__LIBC_FUNC(double, log, (double x), __LIBC_NOATTR);
#if defined(__UCLIBC__) || defined(__GLIBC__)
  __LIBC_FUNC(int, __isnanf, (float x), __LIBC_NOATTR);
  __LIBC_FUNC(int, __isnan, (double x), __LIBC_NOATTR);
#  define isnan(x) (sizeof (x) == sizeof (float) ? __isnanf (x) : __isnan (x))
  __LIBC_FUNC(int, __isinff, (float x), __LIBC_NOATTR);
  __LIBC_FUNC(int, __isinf, (double x), __LIBC_NOATTR);
#  define isinf(x) (sizeof (x) == sizeof (float) ? __isinff (x) : __isinf (x))
#else  /* __MINILIBC686__ and __dietlibc__. */
  __LIBC_FUNC(int, isnan, (double x), __LIBC_NOATTR);
  __LIBC_FUNC(int, isinf, (double x), __LIBC_NOATTR);
#endif

#endif  /* _MATH_H */
