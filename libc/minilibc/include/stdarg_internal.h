#ifndef _STDARG_INTERNAL_H
#define _STDARG_INTERNAL_H

/* This is a size optimization. It only works on i386 and if the function
 * taking the `...' arguments is __attribute__((noinline)).
 */
#ifdef __i386__
  typedef char *__libc__small_va_list;
#endif

#ifdef __GNUC__
  typedef __builtin_va_list __libc__va_list;
#else
#  ifdef __i386__
    typedef __libc__small_va_list __libc__va_list;
#  else
#    error Unsupported platform for <stdarg.h>
#  endif
#endif

#endif  /* _STDARG_INTERNAL_H */
