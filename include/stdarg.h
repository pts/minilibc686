#ifndef _STDARG_H
#define _STDARG_H


/* This is a size optimization. It only works on i386 and if the function
 * taking the `...' arguments is __attribute__((noinline)).
 */
#ifdef __i386__
  typedef char *small_va_list;
#  define small_va_start(ap, last) ((ap) = (char*)&(last) + ((sizeof(last)+3)&~3), (void)0)  /* i386 only. */
#  define small_va_arg(ap, type) ((ap) += (sizeof(type)+3)&~3, *(type*)((ap) - ((sizeof(type)+3)&~3)))  /* i386 only. */
#  define small_va_copy(dest, src) ((dest) = (src), (void)0)  /* i386 only. */
#  define small_va_end(ap) /*((ap) = 0, (void)0)*/  /* i386 only. Adding the `= 0' back doesn't make a difference. */
#endif

#ifdef __GNUC__
  typedef __builtin_va_list va_list;
#  define va_start(v,l)	__builtin_va_start(v,l)
#  define va_end(v)	__builtin_va_end(v)
#  define va_arg(v,l)	__builtin_va_arg(v,l)
#  define va_copy(d,s)	__builtin_va_copy(d,s)
#else
#  ifdef __i386__
    typedef small_va_list va_list;
#    define va_start(ap, last) small_va_start(ap, last)
#    define va_arg(ap, type)   small_va_arg(ap, type)
#    define va_copy(dest, src) small_va_copy(dest, src)
#    define va_end(ap)         small_va_end(ap)
#  endif
#endif

#endif  /* _STDARG_H */
