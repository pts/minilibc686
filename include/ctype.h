#ifndef _CTYPE_H
#define _CTYPE_H

#ifdef __UCLIBC__
int isalpha(int c) __asm__("mini_isalpha");
int isdigit(int c) __asm__("mini_isdigit");
int isxdigit(int c) __asm__("mini_isxdigit");
int isspace(int c) __asm__("mini_isspace");
#else  /* __UCLIBC__ */
int isalpha(int c) __asm__("mini_isalpha_RP1") __attribute__((__regparm__(1)));
int isdigit(int c) __asm__("mini_isdigit_RP1") __attribute__((__regparm__(1)));
int isxdigit(int c) __asm__("mini_isxdigit_RP1") __attribute__((__regparm__(1)));
int isspace(int c) __asm__("mini_isspace_RP1") __attribute__((__regparm__(1)));
#endif  /* else __UCLIBC__ */

#endif  /* _CTYPE_H */
