#ifndef _MATH_H
#define _MATH_H
#include <_preincl.h>

#define M_E 2.7182818284590452354
#define M_LOG2E 1.4426950408889634074
#define M_LOG10E 0.43429448190325182765
#define M_LN2 0.69314718055994530942
#define M_LN10 2.30258509299404568402
#define M_PI 3.14159265358979323846
#define M_PI_2 1.57079632679489661923
#define M_PI_4 0.78539816339744830962
#define M_1_PI 0.31830988618379067154
#define M_2_PI 0.63661977236758134308
#define M_2_SQRTPI 1.12837916709551257390
#define M_SQRT2 1.41421356237309504880
#define M_SQRT1_2 0.70710678118654752440
#define M_El 2.7182818284590452353602874713526625L
#define M_LOG2El 1.4426950408889634073599246810018922L
#define M_LOG10El 0.4342944819032518276511289189166051L
#define M_LN2l 0.6931471805599453094172321214581766L
#define M_LN10l 2.3025850929940456840179914546843642L
#define M_PIl 3.1415926535897932384626433832795029L
#define M_PI_2l 1.5707963267948966192313216916397514L
#define M_PI_4l 0.7853981633974483096156608458198757L
#define M_1_PIl 0.3183098861837906715377675267450287L
#define M_2_PIl 0.6366197723675813430755350534900574L
#define M_2_SQRTPIl 1.1283791670955125738961589031215452L
#define M_SQRT2l 1.4142135623730950488016887242096981L
#define M_SQRT1_2l 0.7071067811865475244008443621048490L

#if __GNUC_PREREQ(3, 3)
#  define HUGE_VAL  (__builtin_huge_val())
#  define HUGE_VALF (__builtin_huge_valf())
#  define HUGE_VALL (__builtin_huge_vall())
#  define INFINITY  (__builtin_inff())
#  define NAN (__builtin_nan(""))
#elif __GNUC_PREREQ(2, 96)
#  define HUGE_VAL  (__extension__ (double)0x1.0p2047L)  /* L to avoid -Woverflow warning. */
#  define HUGE_VALF (__extension__ (float)0x1.0p255)
#  define HUGE_VALL ((long double) HUGE_VAL)
#  define INFINITY  (__extension__ (float)0x1.0p255)
#  define NAN       (__extension__ ((union { unsigned __i;            float __f; })  { 0x7fc00000U }).__f)
#elif defined(__GNUC__) || defined(__TINYC__)
#  define HUGE_VAL  (__extension__ ((union { unsigned long long __ll; double __d; }) { 0x7ff0000000000000ULL }).__d)
#  define HUGE_VALF (__extension__ ((union { unsigned __i;            float __f; })  { 0x7f800000U }).__f)
#  define HUGE_VALL ((long double) HUGE_VAL)
#  define INFINITY  (__extension__ ((union { unsigned __i;            float __f; })  { 0x7f800000U }).__f)  /* Same as HUFE_VALF. */
#  define NAN       (__extension__ ((union { unsigned __i;            float __f; })  { 0x7fc00000U }).__f)
#else  /* E.g. __WATCOMC__ */
  extern float __float_huge_val, __float_infinity, __float_nan;
  extern double __double_huge_val;
#  define HUGE_VAL  __double_huge_val
#  define HUGE_VALF __float_huge_val
#  define HUGE_VALL ((long double) HUGE_VAL)
#  define INFINITY  __float_infinity
#  define NAN       __float_nan
#endif
#if 0 && defined(__i386__)  /* Works in __GNUC__, __TINYC__ and __WATCOMC__, but it is a bit inefficient. */
static __inline__ double __get_huge_val(void) { static union { unsigned long long __ll; double __d; } __u = { 0x7ff0000000000000ULL }; return __u.__d; }
static __inline__ float __get_huge_valf(void) { static union { unsigned __i; float __f; } __u = { 0x7f800000U }; return __u.__f; }
#  define HUGE_VAL  (__get_huge_val())
#  define HUGE_VALF (__get_huge_valf))
#  define HUGE_VALL ((long double) HUGE_VAL)
#  define INFINITY  (__get_huge_valf())
#endif

__LIBC_FUNC(float, logf, (float x), __LIBC_NOATTR);
__LIBC_FUNC(double, log, (double x), __LIBC_NOATTR);
__LIBC_FUNC(long double, logl, (long double x), __LIBC_NOATTR);

__LIBC_FUNC(float, sqrtf, (float x), __LIBC_NOATTR);
__LIBC_FUNC(double, sqrt, (double x), __LIBC_NOATTR);
__LIBC_FUNC(long double, sqrtl, (long double x), __LIBC_NOATTR);

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
