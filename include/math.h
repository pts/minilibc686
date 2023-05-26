#ifndef _MATH_H
#define _MATH_H

double log(double x) __asm__("mini_log");
#ifdef __UCLIBC__
  int __isnanf(float x);
  int __isnan(double x);
#  define isnan(x) (sizeof (x) == sizeof (float) ? __isnanf (x) : __isnan (x))
#else
  int isnan(double x) __asm__("mini_isnan");
#endif

#endif  /* _MATH_H */
