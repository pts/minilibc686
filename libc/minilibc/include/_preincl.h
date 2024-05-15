/* Only autoincluded by OpenWatcom C compiler because the filename is _preincl.h.
 *
 * This header works for minilibc686 (-D__MINILIBC686__), uClibc
 * (nonstandard -D__UCLIBC__), diet libc (-D__dietlibc__), glibc
 * (-D__GLIBC__) and EGLIBC (-D__GLIBC__).
 *
 * `gcc -include _preincl.h' is useful, but pts-tcc doesn't have it. owcc386
 * does it by default for _preincl.h.
 *
 * This is the correct way to define a packed struct:
 *
 *   #ifdef __WATCOMC__
 *   _Packed  / * OpenWatcom requires _Packed in front of the struct to take effect. * /
 *   #endif
 *   typedef struct S {
 *     char a;
 *     __attribute__((__packed__) int b;  / * TinyCC requires it here, GCC and Clang also respect it. * /
 *     char c;
 *   } / *__attribute__((__packed__))* / SS;  / * TinyCC ignores this, GCC and Clang respect it. * /
 *
 * With the __LIBC_... below:
 *
 *   __LIBC_PACKED_STRUCT typedef struct S {
 *     char a;
 *     __LIBC_PACKED int b;
 *     char c;
 *   } SS;
 *
 * FYI GCC has these predefined macros:
 *
 *  * The default is -std=gnu89.
 *  * Specifying -pedantic doesn't change the predefined macros.
 *  * -D__STDC__=1 unless -traditional is specified.
 *  * -D__STRICT_ANSI__=1 if -ansi (same as -std=c89) or -std=c.. is specified.
 *  * -D__STDC_VERSION__=199901L if -std=c99 or -std=gnu99 is specified (please note that inlining behavior has also changed).
 *  * -D__STDC_VERSION__=201112L if -std=c11 or -std=gnu11 is specified.
 *  * -D__STDC_VERSION__=201710L if -std=c17 or -std=gnu17 is specified.
 */
#ifndef _PREINCL_H
#  define _PREINCL_H
#  ifdef __WATCOMC__  /* Try to make the OpenWatcom C compiler (wcc386) behave more like GCC (gcc). */
     /* See: https://open-watcom.github.io/open-watcom-v2-wikidocs/cguide.html , also search for my_stdcall. */
     /* See: https://open-watcom.github.io/open-watcom-v2-wikidocs/clpr.html */
#    pragma once
#    if !defined(__i386__) && (defined(_M_I386) || defined(__386__))
#      define __i386__ 1  /* Matches __GNUC__. */
#    endif
#    if _M_IX86 >= 400 && !defined(__i486__) && _M_IX86 < 500
#      define __i486__ 1  /* Matches __GNUC__. */
#    endif
#    if _M_IX86 >= 500 && !defined(__i586__) && _M_IX86 < 600
#      define __i586__ 1  /* Matches __GNUC__. */
#    endif
#    if _M_IX86 >= 600 && !defined(__i686__)
#      define __i686__ 1  /* Matches __GNUC__. */
#    endif
#    if !defined(__i386__) || !defined(__FLAT__)
#      error This libc requires flat memory model and i386.
#    endif
    /* TODO(pts): Add inline functions for getc(...) and putc(...), check __inline. How does it work? */
    /* TODO(pts): `wcc386 -oi' + #include <string.h>: does it generate strlen(3) inline? */
    /* TODO(pts): Use __declspec(noreturn) for exit. */
    /* TODO(pts): #pragma off (check_stack) */
    /* TODO(pts): #pragma alias (alias, subst) [;] */
    /* TODO(pts): #pragma disable_message ( msg_num {, msg_num} ) [;] */
    /* TODO(pts): #pragma extref name [;] */
    /* TODO(pts): #pragma aux ( sym, alias ) [;] */
    /*#define __asm__(x)*/  /* Not needed. */
#    define __extension__  /* Ignore __GNUC__ construct. */
#    define __restrict__  /* Ignore __GNUC__ construct. */
#    define __attribute__(x)  /* Ignore __GNUC__ construct. */
#    define __inline__ __inline  /* Use OpenWatcom symtax for __GNUC__ construct. */
#    define __signed__ signed
#    ifdef _NO_EXT_KEYS  /* wcc386 -za */
#      define __STRICT_ANSI__ 1  /* `gcc -ansi' == `gcc -std=c89'. */
#    endif
#    ifndef __SIZE_TYPE__  /* __GNUC__ predefined. */
#      define __SIZE_TYPE__ unsigned int
#    endif
#    ifndef __PTRDIFF_TYPE__  /* __GNUC__ predefined. */
#      define __PTRDIFF_TYPE__ int
#    endif
#    if !defined(__linux__) && defined(__LINUX__)
#      define __linux__ 1  /* __GNUC__ construct. */
#    endif
    /* `wcc386 -za' causes -D__STDC__=1, `wcc386 -za99' causes -D__STDC_VERSION=199901L */
    /* We use the strange names __syscall and __fortran because they are
     * predefined for OpenWatcom, and only predefined names can be used in
     * function declarations (without #pragma or _Pragma).
     */
#    pragma aux   __default   "_*"           __parm __caller [] __value __struct __caller [] __modify [__eax __ecx __edx]  /* GCC __regparm__(0) default. */
#    pragma aux   __cdecl     "_*"           __parm __caller [] __value __struct __caller [] __modify [__eax __ecx __edx]  /* Same as the default. */
#    pragma aux   __fastcall  "_*"           __parm __caller [__eax] [__edx] [__ecx] __value __struct __caller [] __modify [__eax __ecx __edx]  /* GCC __regparm__(1) .. __regparm(3). Returns struct address is passed in EAX. */
#    ifdef __MINILIBC686__
#      pragma aux __minirp1   "_mini_*_RP1"  __parm __caller [__eax] __value __struct __caller [] __modify [__eax __ecx __edx]  /* GCC __regparm__(1). Returns struct address is passed in EAX. */
#      pragma aux __syscall   "_mini_*"      __parm __caller [] __value __struct __caller [] __modify [__eax __ecx __edx]  /* Same as the default, with mini_ prefix. */
#      pragma aux __fortran   "_mini_*_RP3"  __parm __caller [__eax] [__edx] [__ecx] __value __struct __caller [] __modify [__eax __ecx __edx]  /* GCC __regparm__(1) .. __regparm(3). Returns struct address is passed in EAX. */
#    endif
#    pragma aux (__default) main
#    pragma aux main "_*"
#    ifdef __MINILIBC686__
#      define __LIBC_FUNC(type, name, args, gcc_attrs) type __syscall name args  /* `wcc386 -za' doesn't allow extra semicolons at the end. */
#      define __LIBC_FUNC_RP3(type, name, args, gcc_attrs) type __fortran name args  /* `wcc386 -za' doesn't allow extra semicolons at the end. */
#      /* Extra manual #pragma is needed by __WATCOMC__ for libc global variables, e.g. #pragma aux stdin "_mini_*". It's not possible to automate this with `wcc386 -za'. */
#    else
#      define __LIBC_FUNC(type, name, args, gcc_attrs) type name args
#    endif
#    define __LIBC_VAR(type, name) type name
#    define __LIBC_NORETURN __declspec(noreturn)
#    define __LIBC_NOATTR
#    define __LIBC_PACKED_STRUCT _Packed
#    define __LIBC_PACKED
#    define __GNUC_PREREQ(maj, min) 0
#  else  /* GCC, Clang, TinyCC. */
#    if defined(__GNUC__) && defined(__GNUC_MINOR__)
#      define __GNUC_PREREQ(maj, min) ((__GNUC__ << 16) + __GNUC_MINOR__ >= ((maj) << 16) + (min))
#    else
#      define __GNUC_PREREQ(maj, min) 0
#    endif
#    ifdef __MINILIBC686__
#      define __LIBC_FUNC(type, name, args, gcc_attrs) type name args __asm__("mini_" #name) gcc_attrs
#      define __LIBC_FUNC_RP3(type, name, args, gcc_attrs) type name args __asm__("mini_" #name "_RP3") __attribute__((__regparm__(3))) gcc_attrs
#      define __LIBC_VAR(type, name) type name __asm__("mini_" #name)
#      define __LIBC_MINI "mini_"
#    else
#      define __LIBC_FUNC(type, name, args, gcc_attrs) type name args gcc_attrs
#      define __LIBC_VAR(type, name) type name
#      define __LIBC_MINI ""
#    endif
#    define __LIBC_NORETURN __attribute__((noreturn, nothrow))
#    define __LIBC_NOATTR __attribute__(())  /* To prevent an empty `gcc_attrs' argument for `gcc -ansi'. */
#    define __LIBC_PACKED_STRUCT
#    define __LIBC_PACKED __attribute__((__packed__))
#  endif  /* C compiler */
#  ifdef __MINILIBC686__
#    define __LIBC_FUNC_MINIRP3(type, name, args, gcc_attrs) __LIBC_FUNC_RP3(type, name, args, gcc_attrs)
#    ifdef CONFIG_NO_RP3
#      define __LIBC_FUNC_MAYBE_MINIRP3(type, name, args, gcc_attrs) __LIBC_FUNC(type, name, args, gcc_attrs)
#    else
#      define __LIBC_FUNC_MAYBE_MINIRP3(type, name, args, gcc_attrs) __LIBC_FUNC_RP3(type, name, args, gcc_attrs)
#    endif
#  else
#    define __LIBC_FUNC_MINIRP3(type, name, args, gcc_attrs) __LIBC_FUNC(type, name, args, gcc_attrs)
#    define __LIBC_FUNC_MAYBE_MINIRP3(type, name, args, gcc_attrs) __LIBC_FUNC(type, name, args, gcc_attrs)
#  endif
#  define __LIBC_STATIC_ASSERT(name, value) typedef char __static_assert_##name[(value) ? 1 : -1]
#endif  /* _PREINCL_H */
