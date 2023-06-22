#ifndef _SETJMP_H
#define _SETJMP_H
#include <_preincl.h>

typedef struct { unsigned __saved_regs[6]; } jmp_buf[1];

__LIBC_FUNC(int, setjmp, (jmp_buf env), __LIBC_NOATTR);  /* It doesn't save the signal mask. */
__LIBC_FUNC(__LIBC_NORETURN void, longjmp, (jmp_buf env, int val), __LIBC_NOATTR);  /* It doesn't restore the signal mask. */

#endif  /* _SETJMP_H */
