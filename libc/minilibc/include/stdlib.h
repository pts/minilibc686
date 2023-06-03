#ifndef _STDLIB_H
#define _STDLIB_H
#include <_preincl.h>

#include <sys/types.h>

#define NULL ((void*)0)

__LIBC_FUNC(__LIBC_NORETURN void, exit, (int exit_code),);   /* Flushes stdio streams first. To prevent flushing, _exit(...) instead. */

__LIBC_FUNC(int, rand, (void),);
__LIBC_FUNC(void, srand, (unsigned seed),);

/* Limitation: it doesn't set errno on overflow in minilibc686. */
__LIBC_FUNC(long, strtol, (const char *nptr, char **endptr, int base),);
/* Limitation: it doesn't set errno on overflow in minilibc686. */
__LIBC_FUNC(double, strtod, (const char *nptr, char **endptr),);

/* The current implementation does an mmap(2) call for each allocation, and
 * it rounds up the size to 4 KiB boundary after adding 0x10. Thus it's
 * suitable for a few large allocations.
 */
__LIBC_FUNC(void *, malloc, (size_t size),);
__LIBC_FUNC(void *, realloc, (void *ptr, size_t size),);
__LIBC_FUNC(void, free, (void *ptr),);

/* Short and stable, but slow: insertion sort with O(n**2) worst time.
 * It's not quicksort because the implementation of insertion sort is shorter.
 */
__LIBC_FUNC(void, qsort, (void *base, size_t n, size_t size, int (*cmp)(const void*, const void*)),);

#ifdef __MINILIBC686__
  /* Returns an unaligned pointer. There is no API to free it. Suitable for
   * many small allocations.
   */
  __LIBC_FUNC(void *, malloc_simple_unaligned, (size_t size),);
#endif  /* __MINiLIBC686__ */

#endif  /* _STDLIB_H */
