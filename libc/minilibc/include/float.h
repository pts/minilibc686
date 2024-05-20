#ifndef _FLOAT_H
#  define _FLOAT_H

#  define FLT_RADIX 2

#  ifndef __SIZEOF_FLOAT__  /* GCC and Clang has it defined, but not TinyCC, OpenWatcom or PCC. */
#    define __SIZEOF_FLOAT__ 4
#  endif
#  ifndef __SIZEOF_DOUBLE__  /* GCC and Clang has it defined, but not TinyCC, OpenWatcom or PCC. */
#    define __SIZEOF_DOUBLE__ 8
#  endif
#  ifndef __SIZEOF_LONG_DOUBLE__  /* GCC and Clang has it defined, but not TinyCC, OpenWatcom or PCC. */
#    ifdef __WATCOMC__
#      define __SIZEOF_LONG_DOUBLE__ 8
#    elif defined(__i386__) || defined(__386__) || defined(_M_IX86)
#      define __SIZEOF_LONG_DOUBLE__ 12
#    elif defined(__amd64__) || defined(__x86_64__) || defined(_M_X64) || defined(_M_AMD64) || defined(__X86_64__)
#      define __SIZEOF_LONG_DOUBLE__ 16
#    endif
#  endif

#  if __SIZEOF_FLOAT__ == 4  /* IEEE f32. */
#    undef  FLT_MANT_DIG
#    define FLT_MANT_DIG 24
#    undef  FLT_DIG
#    define FLT_DIG 6
#    undef  FLT_ROUNDS
#    define FLT_ROUNDS 1
#    undef  FLT_EPSILON
#    define FLT_EPSILON 1.19209290e-07F
#    undef  FLT_MIN_EXP
#    define FLT_MIN_EXP (-125)
#    undef  FLT_MIN
#    define FLT_MIN 1.17549435e-38F
#    undef  FLT_MIN_10_EXP
#    define FLT_MIN_10_EXP (-37)
#    undef  FLT_MAX_EXP
#    define FLT_MAX_EXP 128
#    undef  FLT_MAX
#    define FLT_MAX 3.40282347e+38F
#    undef  FLT_MAX_10_EXP
#    define FLT_MAX_10_EXP 38
#  endif

#  if __SIZEOF_DOUBLE__ == 8  /* IEEE f64. */
#    undef  DBL_MANT_DIG
#    define DBL_MANT_DIG 53
#    undef  DBL_DIG
#    define DBL_DIG 15
#    undef  DBL_EPSILON
#    define DBL_EPSILON 2.2204460492503131e-16
#    undef  DBL_MIN_EXP
#    define DBL_MIN_EXP (-1021)
#    undef  DBL_MIN
#    define DBL_MIN 2.2250738585072014e-308
#    undef  DBL_MIN_10_EXP
#    define DBL_MIN_10_EXP (-307)
#    undef  DBL_MAX_EXP
#    define DBL_MAX_EXP 1024
#    undef  DBL_MAX
#    define DBL_MAX 1.7976931348623157e+308
#    undef  DBL_MAX_10_EXP
#    define DBL_MAX_10_EXP 308
#  endif
#

#  if defined(__SIZEOF_LONG_DOUBLE__) && __SIZEOF_LONG_DOUBLE__ >= 10  /* x86 f80. */
#    undef  LDBL_MANT_DIG
#    define LDBL_MANT_DIG 64
#    undef  LDBL_DIG
#    define LDBL_DIG 18
#    undef  LDBL_EPSILON
#    define LDBL_EPSILON 1.0842021724855044340e-19L
#    undef  LDBL_MIN_EXP
#    define LDBL_MIN_EXP (-16381)
#    undef  LDBL_MIN
#    define LDBL_MIN 3.3621031431120935062e-4932L
#    undef  LDBL_MIN_10_EXP
#    define LDBL_MIN_10_EXP (-4931)
#    undef  LDBL_MAX_EXP
#    define LDBL_MAX_EXP 16384
#    undef  LDBL_MAX
#    define LDBL_MAX 1.1897314953572317650e+4932L
#    undef  LDBL_MAX_10_EXP
#    define LDBL_MAX_10_EXP 4932
#  endif

#  if defined(__SIZEOF_LONG_DOUBLE__) && __SIZEOF_LONG_DOUBLE__ < 10  /* Same as IEEE f64. */
#    undef  LDBL_MANT_DIG
#    define LDBL_MANT_DIG 53
#    undef  LDBL_DIG
#    define LDBL_DIG 15
#    undef  LDBL_EPSILON
#    define LDBL_EPSILON 2.2204460492503131e-16
#    undef  LDBL_MIN_EXP
#    define LDBL_MIN_EXP (-1021)
#    undef  LDBL_MIN
#    define LDBL_MIN 2.2250738585072014e-308
#    undef  LDBL_MIN_10_EXP
#    define LDBL_MIN_10_EXP (-307)
#    undef  LDBL_MAX_EXP
#    define LDBL_MAX_EXP 1024
#    undef  LDBL_MAX
#    define LDBL_MAX 1.7976931348623157e+308
#    undef  LDBL_MAX_10_EXP
#    define LDBL_MAX_10_EXP 308
#  endif

#endif /* _FLOAT_H */
