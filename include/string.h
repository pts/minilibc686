#ifndef _STRING_H
#define _STRING_H

int strcasecmp(const char *l, const char *r) __asm__("mini_strcasecmp");
int strncasecmp(const char *l, const char *r, size_t n) __asm__("mini_strncasecmp");
char *strchr(const char *s, int c) __asm__("mini_strchr");
char *index(const char *s, int c) __asm__("mini_index");
size_t strlen(const char *s) __asm__("mini_strlen");
double strtod(const char *str, char **endptr) __asm__("mini_strtod");
char *strtok(char *__restrict__ s, const char *__restrict__ sep) __asm__("mini_strtok");
long strtol(const char *nptr, char **endptr, int base) __asm__("mini_strtol");

#endif  /* _STRING_H */
