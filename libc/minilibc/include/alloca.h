#ifndef _ALLOCA_H
#  define _ALLOCA_H
#  if defined(__GNUC__)
#    define alloca(x) __builtin_alloca(x)
#  elif defined(__WATCOMC__)
    /* Based on OpenWatcom lh/alloca.h. It also calls stackavail(...) in the
     * OpenWatcom libc, but this libc doesn't have that.
     */
    extern void *alloca(unsigned long /*size_t*/ __size);
#    pragma aux alloca = "sub esp, eax" "and esp, -4" __parm __nomemory [__eax] __value [__esp] __modify __exact __nomemory [__esp]
#    define alloca(x) alloca(x)
#    define __builtin_alloca(x) alloca(x)  /* For compatibility with GCC. */
#  elif defined(__builtin_alloca)
#    ifndef alloca
#      define alloca(x) __builtin_alloca(x)
#    endif
#  else  /* __TINYC__, also random others. */
    extern void *alloca(unsigned long /*size_t*/ __size);
#    define alloca(x) alloca(x)
#    define __builtin_alloca(x) alloca(x)  /* For compatibility with GCC. */
#  endif
#endif  /* _ALLOCA_H */
