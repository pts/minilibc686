#ifndef _CTYPE_H
#define _CTYPE_H

#ifdef __UCLIBC__
int isalpha(int c) __asm__("mini_isalpha");
int isdigit(int c) __asm__("mini_isdigit");
int isxdigit(int c) __asm__("mini_isxdigit");
int isspace(int c) __asm__("mini_isspace");
#endif  /* __UCLIBC__ */

#endif  /* _CTYPE_H */
