#ifndef _LIMITS_H
#define _LIMITS_H

#define PATH_MAX 4096  /* uClibc has 4096, diet libc has 4095, EGLIBC has 4096. */
#define PASS_MAX 256
#define NR_OPEN 1024
#define NGROUPS_MAX 32
#define ARG_MAX 131072
#define CHILD_MAX 999
#define OPEN_MAX 256
#define LINK_MAX 127
#define MAX_CANON 255
#define MAX_INPUT 255
#define NAME_MAX 255
#define PIPE_BUF 4096
#define RTSIG_MAX 32
#define LINE_MAX 2048
#define _POSIX_PATH_MAX PATH_MAX
#define MB_LEN_MAX 16
#define IOV_MAX 1024

#if !(defined(__i386__) || defined(__386__) || defined(_M_IX86))
#  error This <limits.h> needs i386 target.  /* Because of the defines below. */
#endif

#if !defined(__SIZEOF_SHORT__)  /* GCC and Clang, but not TinyCC, OpenWatcom or PCC. */
#  define __SIZEOF_SHORT__ 2
#endif
#if !defined(__SIZEOF_INT__)  /* GCC and Clang, but not TinyCC, OpenWatcom or PCC. */
#  define __SIZEOF_INT__ 4
#endif
#if !defined(__SIZEOF_LONG__)  /* GCC and Clang, but not TinyCC, OpenWatcom or PCC. */
#  define __SIZEOF_LONG__ 4
#endif
#if !defined(__SIZEOF_LONG_LONG__)  /* GCC and Clang, but not TinyCC, OpenWatcom or PCC. */
#  define __SIZEOF_LONG_LONG__ 8
#endif
#if !defined(__SIZEOF_POINTER__)  /* GCC and Clang, but not TinyCC, OpenWatcom or PCC. */
#  define __SIZEOF_POINTER__ 4
#endif
#if !defined(__SIZEOF_PTRDIFF_T__)  /* GCC and Clang, but not TinyCC, OpenWatcom or PCC. */
#  define __SIZEOF_PTRDIFF_T__ 4
#endif
#if !defined(__SIZEOF_SIZE_T__)  /* GCC and Clang, but not TinyCC, OpenWatcom or PCC. */
#  define __SIZEOF_SIZE_T__ 4
#endif
#if !defined(__SIZEOF_WCHAR_T__)  /* GCC and Clang, but not TinyCC, OpenWatcom or PCC. */
#  define __SIZEOF_WCHAR_T__ 4
#endif
#if !defined(__SIZEOF_WINT_T__)  /* GCC and Clang, but not TinyCC, OpenWatcom or PCC. */
#  define __SIZEOF_WINT_T__ 4
#endif

#ifndef __SCHAR_MAX__
#  define __SCHAR_MAX__ 0x7f
#endif
#ifndef __SHRT_MAX__
#  define __SHRT_MAX__ ((short)((unsigned short)~0U >> 1))
#endif
#ifndef __INT_MAX__
#  define __INT_MAX__ ((int)(~0U >> 1))
#endif
#ifndef __LONG_MAX__
#  define __LONG_MAX__ ((long)(~0UL >> 1))
#endif
#define CHAR_BIT 8
#define SCHAR_MIN (-1 - SCHAR_MAX)
#define SCHAR_MAX (__SCHAR_MAX__)
#define UCHAR_MAX (SCHAR_MAX * 2 + 1)
#define SHRT_MIN (-1 - SHRT_MAX)
#define SHRT_MAX (__SHRT_MAX__)
#define USHRT_MAX (SHRT_MAX * 2 + 1)
#define INT_MIN (-1 - INT_MAX)
#define INT_MAX (__INT_MAX__)
#define UINT_MAX (INT_MAX * 2U + 1)
#define LONG_MIN (-1l - LONG_MAX)
#define LONG_MAX (__LONG_MAX__)
#define ULONG_MAX (LONG_MAX * 2UL + 1)
#define LLONG_MAX ((long long)(~0ULL >> 1))
#define LLONG_MIN (-1LL - LLONG_MAX)
#define ULLONG_MAX (~0ULL)
#if defined(__SIZEOF_SIZE_T__) && __SIZEOF_SIZE_T__ == __SIZEOF_LONG__  /* Always true for i386. */
#  define SSIZE_MIN LONG_MIN
#  define SSIZE_MAX LONG_MAX
#endif

#ifdef __CHAR_UNSIGNED__
#  undef  CHAR_MIN
#  define CHAR_MIN 0
#  undef  CHAR_MAX
#  define CHAR_MAX UCHAR_MAX
#else
#  undef  CHAR_MIN
#  define CHAR_MIN SCHAR_MIN
#  undef  CHAR_MAX
#  define CHAR_MAX SCHAR_MAX
#endif

#endif  /* _LIMITS_H */
