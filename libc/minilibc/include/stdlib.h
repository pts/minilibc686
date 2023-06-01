#ifndef _STDLIB_H
#define _STDLIB_H

#include <sys/types.h>

#define NULL ((void*)0)

void exit(int exit_code) __asm__("mini_exit") __attribute__((__noreturn__));  /* Flushes stdio streams first. */

int rand(void) __asm__("mini_rand");
void srand(unsigned seed) __asm__("mini_srand");

long int strtol(const char *nptr, char **endptr, int base) __asm__("mini_strtol");
double strtod(const char *nptr, char **endptr) __asm__("mini_strtod");

/* The current implementation does an mmap(2) call for each allocation, and
 * it rounds up the size to 4 KiB boundary after adding 0x10. Thus it's
 * suitable for a few large allocations.
 */
void *malloc(size_t size) __asm__("mini_malloc");
void *realloc(void *ptr, size_t size) __asm__("mini_realloc");
void free(void *ptr) __asm__("mini_free");

/* Short and stable, but slow: insertion sort with O(n**2) worst time.
 * It's not quicksort because the implementation of insertion sort is shorter.
 */
void qsort(void *base, size_t n, size_t size,
           int (*cmp)(const void*, const void*)) __asm__("mini_qsort");

#ifdef __MINILIBC686__
  /* Returns an unaligned pointer. There is no API to free it. Suitable for
   * many small allocations.
   */
  void *malloc_simple_unaligned(size_t size) __asm__("mini_malloc_simple_unaligned");
#endif  /* __MINiLIBC686__ */

#endif  /* _STDLIB_H */
