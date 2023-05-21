#ifndef _STDLIB_H
#define _STDLIB_H

#define NULL ((void*)0)

int rand(void) __asm__("mini_rand");
void srand(unsigned seed) __asm__("mini_srand");

void *malloc(size_t size) __asm__("mini_malloc");
void *realloc(void *ptr, size_t size) __asm__("mini_realloc");
void free(void *ptr) __asm__("mini_free");

#endif  /* _STDLIB_H */
