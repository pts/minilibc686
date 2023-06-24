#ifndef _STDINT_H
#define _STDINT_H
#include <_preincl.h>

#ifndef __int8_t_defined
#  define __int8_t_defined
#endif
#ifndef __uint32_t_defined
#  define __uint32_t_defined
#endif
#ifndef __intptr_t_defined
#  define __intptr_t_defined
#endif

typedef signed char int8_t;
typedef short int int16_t;
typedef int int32_t;
__extension__ typedef long long int int64_t;  /* __extension__ is to make it work with `gcc -ansi -pedantic'. */
typedef unsigned char uint8_t;
typedef unsigned short int uint16_t;
typedef unsigned int uint32_t;
__extension__ typedef unsigned long long int uint64_t;  /* __extension__ is to make it work with `gcc -ansi -pedantic'. */

typedef signed char int_least8_t;
typedef short int int_least16_t;
typedef int int_least32_t;
__extension__ typedef long long int int_least64_t;
typedef unsigned char uint_least8_t;
typedef unsigned short int uint_least16_t;
typedef unsigned int uint_least32_t;
__extension__ typedef unsigned long long int uint_least64_t;
typedef signed char int_fast8_t;
typedef int int_fast16_t;
typedef int int_fast32_t;
__extension__ typedef long long int int_fast64_t;
typedef unsigned char uint_fast8_t;
typedef unsigned int uint_fast16_t;
typedef unsigned int uint_fast32_t;
__extension__ typedef unsigned long long int uint_fast64_t;
typedef int intptr_t;
typedef unsigned int uintptr_t;
__extension__ typedef long long int intmax_t;
__extension__ typedef unsigned long long int uintmax_t;

#if !defined(__INT64_C)
#  define __INT64_C(c) c ##LL
#endif
#if !defined(__UINT64_C)
#  define __UINT64_C(c) c ##ULL
#endif

#define INT8_MIN (-128)
#define INT16_MIN (-32767-1)
#define INT32_MIN (-2147483647-1)
#define INT64_MIN (-__INT64_C(9223372036854775807)-1)
#define INT8_MAX (127)
#define INT16_MAX (32767)
#define INT32_MAX (2147483647)
#define INT64_MAX (__INT64_C(9223372036854775807))
#define UINT8_MAX (255)
#define UINT16_MAX (65535)
#define UINT32_MAX (4294967295U)
#define UINT64_MAX (__UINT64_C(18446744073709551615))
#define INT_LEAST8_MIN (-128)
#define INT_LEAST16_MIN (-32767-1)
#define INT_LEAST32_MIN (-2147483647-1)
#define INT_LEAST64_MIN (-__INT64_C(9223372036854775807)-1)
#define INT_LEAST8_MAX (127)
#define INT_LEAST16_MAX (32767)
#define INT_LEAST32_MAX (2147483647)
#define INT_LEAST64_MAX (__INT64_C(9223372036854775807))
#define UINT_LEAST8_MAX (255)
#define UINT_LEAST16_MAX (65535)
#define UINT_LEAST32_MAX (4294967295U)
#define UINT_LEAST64_MAX (__UINT64_C(18446744073709551615))
#define INT_FAST8_MIN (-128)
#define INT_FAST16_MIN (-2147483647-1)
#define INT_FAST32_MIN (-2147483647-1)
#define INT_FAST64_MIN (-__INT64_C(9223372036854775807)-1)
#define INT_FAST8_MAX (127)
#define INT_FAST16_MAX (2147483647)
#define INT_FAST32_MAX (2147483647)
#define INT_FAST64_MAX (__INT64_C(9223372036854775807))
#define UINT_FAST8_MAX (255)
#define UINT_FAST16_MAX (4294967295U)
#define UINT_FAST32_MAX (4294967295U)
#define UINT_FAST64_MAX (__UINT64_C(18446744073709551615))
#define INTPTR_MIN (-2147483647-1)
#define INTPTR_MAX (2147483647)
#define UINTPTR_MAX (4294967295U)
#define INTMAX_MIN (-LONG_LONG_MAX-1)
#define INTMAX_MAX (LONG_LONG_MAX)
#define UINTMAX_MAX (LONG_LONG_MAX<<1+1)
#define PTRDIFF_MIN (-2147483647-1)
#define PTRDIFF_MAX (2147483647)
#define SIG_ATOMIC_MIN (-2147483647-1)
#define SIG_ATOMIC_MAX (2147483647)
#define SIZE_MAX (4294967295U)
#define INT8_C(c) c
#define INT16_C(c) c
#define INT32_C(c) c
#define INT64_C(c) c ##LL
#define UINT8_C(c) c ##U
#define UINT16_C(c) c ##U
#define UINT32_C(c) c ##U
#define UINT64_C(c) c ##ULL
#define INTMAX_C(c) c ##LL
#define UINTMAX_C(c) c ##ULL

#endif  /* _STDINT_H */
