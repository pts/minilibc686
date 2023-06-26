#ifndef _STDDEF_H
#define _STDDEF_H
#include <_preincl.h>

#include <sys/types.h>

#define NULL ((void*)0)  /* Defined in multiple .h files: https://en.cppreference.com/w/c/types/NULL */

#undef offsetof
#if defined(__GNUC__) && __GNUC__ >= 3  /* __PCC__ has it (and it is used here). __TINYC__ and __WATCOMC__ don't have it. */
#  define offsetof(type,member) __builtin_offsetof(type,member)
#else
#  define offsetof(type,member) ((size_t) &((type*)0)->member)
#endif

#endif  /* _STDDEF_H */
