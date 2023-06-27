#ifndef _STDBOOL_H
#  define _STDBOOL_H
#  define __bool_true_false_are_defined 1
#  ifdef __cplusplus
    typedef bool __stdbool_bool;  /* Just for unconditional completeness. */
#    undef _Bool
#    define _Bool bool
#    define bool bool
#    define true true
#    define false false
#  elif defined(__WATCOMC__) && !(__STDC_VERSION__ >= 199901L)
    typedef unsigned char __stdbool_bool;
#    undef _Bool
#    define _Bool __stdbool_bool
#    define bool _Bool
#    define true 1
#    define false 0
#  else  /* GCC, Clang, TinyCC, PCC. */
    __extension__ typedef _Bool __stdbool_bool;
#    undef _Bool
#    define _Bool __stdbool_bool  /* Pacify GCC warnings. */
#    define bool _Bool
#    define true 1
#    define false 0
#  endif
#endif  /* _STDBOOL_H */
