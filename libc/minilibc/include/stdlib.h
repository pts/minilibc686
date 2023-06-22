#ifndef _STDLIB_H
#define _STDLIB_H
#include <_preincl.h>

#include <sys/types.h>

#define NULL ((void*)0)

__LIBC_VAR(extern char **, environ);
#ifdef __WATCOMC__  /* There is no other way with `wcc386 -za'. */
#  pragma aux environ "_mini_*"
#endif

__LIBC_FUNC(__LIBC_NORETURN void, exit, (int exit_code), __LIBC_NOATTR);   /* Flushes stdio streams first. To prevent flushing, _exit(...) instead. */
__LIBC_FUNC(__LIBC_NORETURN void, abort, (void), __LIBC_NOATTR);   /* Doesn't flush stdio streams. Both behaviors are OK according to POSIX. Limitation: it doesn't call the SIGABRT handler. */

__LIBC_FUNC(int, rand, (void), __LIBC_NOATTR);
__LIBC_FUNC(void, srand, (unsigned seed), __LIBC_NOATTR);

/* Limitation: it doesn't set errno on overflow in minilibc686. */
__LIBC_FUNC(long, strtol, (const char *nptr, char **endptr, int base), __LIBC_NOATTR);
/* Limitation: it doesn't set errno on overflow in minilibc686. */
__LIBC_FUNC(double, strtod, (const char *nptr, char **endptr), __LIBC_NOATTR);

/* The current implementation does an mmap(2) call for each allocation, and
 * it rounds up the size to 4 KiB boundary after adding 0x10. Thus it's
 * suitable for a few large allocations.
 */
__LIBC_FUNC(void *, malloc, (size_t size), __LIBC_NOATTR);
__LIBC_FUNC(void *, realloc, (void *ptr, size_t size), __LIBC_NOATTR);
__LIBC_FUNC(void, free, (void *ptr), __LIBC_NOATTR);

/* Short and stable, but slow: insertion sort with O(n**2) worst time.
 * It's not quicksort because the implementation of insertion sort is shorter.
 */
__LIBC_FUNC(void, qsort, (void *base, size_t n, size_t size, int (*cmp)(const void*, const void*)), __LIBC_NOATTR);

#ifdef __MINILIBC686__
  /* Returns an unaligned pointer. There is no API to free it. Suitable for
   * many small allocations.
   */
  __LIBC_FUNC(void *, malloc_simple_unaligned, (size_t size), __LIBC_NOATTR);
#endif  /* __MINiLIBC686__ */

#endif  /* _STDLIB_H */
