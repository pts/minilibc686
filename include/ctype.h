#ifndef _CTYPE_H
#define _CTYPE_H

#ifdef __UCLIBC__
/* These functions are also included in minilibc686, but, the *_RP1 variants
 * are more efficient to use in newly compiled code.
 */
int isalpha(int c) __asm__("mini_isalpha");
int isdigit(int c) __asm__("mini_isdigit");
int isxdigit(int c) __asm__("mini_isxdigit");
int isspace(int c) __asm__("mini_isspace");
int tolower(int c) __asm__("mini_tolower");
int toupper(int c) __asm__("mini_toupper");
#else  /* __UCLIBC__ */
int isalpha(int c) __asm__("mini_isalpha_RP1") __attribute__((__regparm__(1)));
int isdigit(int c) __asm__("mini_isdigit_RP1") __attribute__((__regparm__(1)));
int isxdigit(int c) __asm__("mini_isxdigit_RP1") __attribute__((__regparm__(1)));
int isspace(int c) __asm__("mini_isspace_RP1") __attribute__((__regparm__(1)));
int tolower(int c) __asm__("mini_tolower_RP1") __attribute__((__regparm__(1)));
int toupper(int c) __asm__("mini_toupper_RP1") __attribute__((__regparm__(1)));
#endif  /* else __UCLIBC__ */

#endif  /* _CTYPE_H */
