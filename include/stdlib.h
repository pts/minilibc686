#ifndef _STDLIB_H
#define _STDLIB_H

#define NULL ((void*)0)

int rand(void) __asm__("mini_rand");
void srand(unsigned seed) __asm__("mini_srand");

/* The current implementation does an mmap(2) call for each allocation, and
 * it rounds up the size to 4 KiB boundary after adding 0x10. Thus it's
 * suitable for a few large allocations.
 */
void *malloc(size_t size) __asm__("mini_malloc");
void *realloc(void *ptr, size_t size) __asm__("mini_realloc");
void free(void *ptr) __asm__("mini_free");

/* Returns an unaligned pointer. There is no API to free it. Suitable for
 * many small allocations.
 */
void *malloc_simple_unaligned(size_t size) __asm__("mini_malloc_simple_unaligned");

#endif  /* _STDLIB_H */
