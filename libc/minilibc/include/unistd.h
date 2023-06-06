#ifndef _UNISTD_H
#define _UNISTD_H
#include <_preincl.h>

#include <sys/types.h>

/* lseek(..., ..., whence) constants. */
#define SEEK_SET 0
#define SEEK_CUR 1
#define SEEK_END 2

#define STDIN_FILENO 0
#define STDOUT_FILENO 1
#define STDERR_FILENO 2

__LIBC_VAR(extern char **, environ);
#ifdef __WATCOMC__  /* There is no other way with `wcc386 -za'. */
#  pragma aux environ "_mini_*"
#endif

__LIBC_FUNC(__LIBC_NORETURN void, _exit, (int exit_code), __LIBC_NOATTR);  /* Doesn't flush stdio streams first. See exit(...) for that. */
__LIBC_FUNC(int, close, (int fd), __LIBC_NOATTR);
__LIBC_FUNC(ssize_t, read, (int fd, void *buf, size_t count), __LIBC_NOATTR);
__LIBC_FUNC(ssize_t, write, (int fd, const void *buf, size_t count), __LIBC_NOATTR);
__LIBC_FUNC(off_t, lseek, (int fd, off_t offset, int whence), __LIBC_NOATTR);  /* 32-bit offset. See lseek64(...) for 64-bit offset. */
__LIBC_FUNC(off64_t, lseek64, (int fd, off64_t offset, int whence), __LIBC_NOATTR);
__LIBC_FUNC(long, syscall, (long nr, ...), __LIBC_NOATTR);
__LIBC_FUNC(int, unlink, (const char *pathname), __LIBC_NOATTR);
/* Limitation: it doesn't always set errno in minilibc686. */
__LIBC_FUNC(int, isatty, (int fd), __LIBC_NOATTR);
__LIBC_FUNC(int, ftruncate, (int fd, off_t length), __LIBC_NOATTR);  /* 32-bit length. */
__LIBC_FUNC(int, symlink, (const char *target, const char *linkpath), __LIBC_NOATTR);
__LIBC_FUNC(uid_t, geteuid, (void), __LIBC_NOATTR);
__LIBC_FUNC(pid_t, getpid, (void), __LIBC_NOATTR);
__LIBC_FUNC(pid_t, fork, (void), __LIBC_NOATTR);
__LIBC_FUNC(void *, sys_brk, (void *addr), __LIBC_NOATTR);
#ifdef __MINILIBC686__
  /* Returns 0 on success, anything else (and sets errno) on error. The
   * implementation quite shorter than lseek64(...).
   */
  __LIBC_FUNC_RP3(int, lseek64_set, (int fd, off64_t offset), __LIBC_NOATTR);
  __LIBC_FUNC(int, sys__llseek, (int fd, int offset_high, int offset_low, loff_t *result, int whence), __LIBC_NOATTR);  /* System call. Use lseek(...) or lseek64(...) above instead. */
#endif  /* __MINILIBC686__ */

#ifdef __MINILIBC686__
#  ifdef __WATCOMC__
    long syscall0(long nr);
    long syscall1(long nr, long arg1);
    long syscall2(long nr, long arg1, long arg2);
    long syscall3(long nr, long arg1, long arg2, long arg3);
    long syscall4(long nr, long arg1, long arg2, long arg3, long arg4);
    long syscall5(long nr, long arg1, long arg2, long arg3, long arg4, long arg5);
    long syscall6(long nr, long arg1, long arg2, long arg3, long arg4, long arg5, long arg6);
#    pragma aux (__minirp1) syscall0 "_mini_syscall3_RP1"
#    pragma aux (__minirp1) syscall1 "_mini_syscall3_RP1"
#    pragma aux (__minirp1) syscall2 "_mini_syscall3_RP1"
#    pragma aux (__minirp1) syscall3 "_mini_syscall3_RP1"  /* mini_syscall3_RP1 works for 0..3 arguments. */
#    pragma aux (__minirp1) syscall4 "_mini_syscall6_RP1"
#    pragma aux (__minirp1) syscall5 "_mini_syscall6_RP1"
#    pragma aux (__minirp1) syscall6 "_mini_syscall6_RP1"  /* mini_syscall6_RP1 works for 0..6 arguments. */
#  else  /* __WATCOMC__ */
    long syscall0(long nr) __asm__("mini_syscall3_RP1") __attribute__((__regparm__(1)));
    long syscall1(long nr, long arg1) __asm__("mini_syscall3_RP1") __attribute__((__regparm__(1)));
    long syscall2(long nr, long arg1, long arg2) __asm__("mini_syscall3_RP1") __attribute__((__regparm__(1)));
    long syscall3(long nr, long arg1, long arg2, long arg3) __asm__("mini_syscall3_RP1") __attribute__((__regparm__(1)));
    long syscall4(long nr, long arg1, long arg2, long arg3, long arg4) __asm__("mini_syscall6_RP1") __attribute__((__regparm__(1)));
    long syscall5(long nr, long arg1, long arg2, long arg3, long arg4, long arg5) __asm__("mini_syscall6_RP1") __attribute__((__regparm__(1)));
    long syscall6(long nr, long arg1, long arg2, long arg3, long arg4, long arg5, long arg6) __asm__("mini_syscall6_RP1") __attribute__((__regparm__(1)));
    /*long syscall_upto_3(long nr, ...) __asm__("mini_syscall3_RP1") __attribute__((__regparm__(1)));*/  /* Unfortunately this doesn't work, __regparm__(1) is ignored. */
#  endif  /* else __WATCOMC__ */
#endif  /* __MINILIBC686__ */

#endif  /* _UNISTD_H */
