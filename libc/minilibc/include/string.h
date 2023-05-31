#ifndef _STRING_H
#define _STRING_H

#include <sys/types.h>

int strcasecmp(const char *l, const char *r) __asm__("mini_strcasecmp");
int strncasecmp(const char *l, const char *r, size_t n) __asm__("mini_strncasecmp");
char *strchr(const char *s, int c) __asm__("mini_strchr");
char *index(const char *s, int c) __asm__("mini_index");
size_t strlen(const char *s) __asm__("mini_strlen");
/* Limitation: it doesn't set errno on overflow in minilibc686. */
double strtod(const char *str, char **endptr) __asm__("mini_strtod");
char *strtok(char *__restrict__ s, const char *__restrict__ sep) __asm__("mini_strtok");
/* Limitation: it doesn't set errno on overflow in minilibc686. */
long strtol(const char *nptr, char **endptr, int base) __asm__("mini_strtol");
char *strcpy(char *dest, const char *src) __asm__("mini_strcpy");
char *strcat(char *dest, const char *src) __asm__("mini_strcat");
int strcmp(const char *s1, const char *s2) __asm__("mini_strcmp");
char *strstr(const char *haystack, const char *needle) __asm__("mini_strstr");
#ifdef __MINILIBC686__
/* It is like strstr(...), but scanning haystack for needle[0] is much faster. */
char *strstr_faster(const char *haystack, const char *needle) __asm__("mini_strstr_faster");
#endif  /* __MINILIBC686__ */
void *memcpy(void *dest, const void *src, size_t n) __asm__("mini_memcpy");
void *memmove(void *dest, const void *src, size_t n) __asm__("mini_memmove");
int memcmp(const void *s1, const void *s2, size_t n) __asm__("mini_memcmp");
void *memset(void *s, int c, size_t n) __asm__("mini_memset");

#endif  /* _STRING_H */
