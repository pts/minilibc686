#ifndef _MATH_H
#define _MATH_H

double log(double x) __asm__("mini_log");
#ifdef __UCLIBC__
  int __isnanf(float x);
  int __isnan(double x);
#  define isnan(x) (sizeof (x) == sizeof (float) ? __isnanf (x) : __isnan (x))
  int __isinff(float x);
  int __isinf(double x);
#  define isinf(x) (sizeof (x) == sizeof (float) ? __isinff (x) : __isinf (x))
#else
  int isnan(double x) __asm__("mini_isnan");
  int isinf(double x) __asm__("mini_isinf");
#endif

#endif  /* _MATH_H */
