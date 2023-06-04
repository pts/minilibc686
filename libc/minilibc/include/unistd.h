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

__LIBC_FUNC(void, _exit, (int exit_code),/* !! __LIBC_NORETURN */);  /* Doesn't flush stdio streams first. See exit(...) for that. */
__LIBC_FUNC(int, close, (int fd),);
__LIBC_FUNC(ssize_t, read, (int fd, void *buf, size_t count),);
__LIBC_FUNC(ssize_t, write, (int fd, const void *buf, size_t count),);
__LIBC_FUNC(off_t, lseek, (int fd, off_t offset, int whence),);  /* 32-bit offset. See lseek64(...) for 64-bit offset. */
__LIBC_FUNC(off64_t, lseek64, (int fd, off64_t offset, int whence),);
__LIBC_FUNC(long, syscall, (long nr, ...),);
__LIBC_FUNC(int, unlink, (const char *pathname),);
/* Limitation: it doesn't always set errno in minilibc686. */
__LIBC_FUNC(int, isatty, (int fd),);
__LIBC_FUNC(int, ftruncate, (int fd, off_t length),);  /* 32-bit length. */
__LIBC_FUNC(int, symlink, (const char *target, const char *linkpath),);
__LIBC_FUNC(uid_t, geteuid, (void),);
__LIBC_FUNC(pid_t, getpid, (void),);

#ifdef __MINILIBC686__
#  ifdef __WATCOMC__
    long syscall0(long nr);
    long syscall1(long nr, long arg1);
    long syscall2(long nr, long arg1, long arg2);
    long syscall3(long nr, long arg1, long arg2, long arg3);
#    pragma aux (__minirp1) syscall0
#    pragma aux (__minirp1) syscall1
#    pragma aux (__minirp1) syscall2
#    pragma aux (__minirp1) syscall3
#  else  /* __WATCOMC__ */
    long syscall0(long nr) __asm__("mini_syscall3_RP1") __attribute__((__regparm__(1)));
    long syscall1(long nr, long arg1) __asm__("mini_syscall3_RP1") __attribute__((__regparm__(1)));
    long syscall2(long nr, long arg1, long arg2) __asm__("mini_syscall3_RP1") __attribute__((__regparm__(1)));
    long syscall3(long nr, long arg1, long arg2, long arg3) __asm__("mini_syscall3_RP1") __attribute__((__regparm__(1)));
    /*long syscall_upto_3(long nr, ...) __asm__("mini_syscall3_RP1") __attribute__((__regparm__(1)));*/  /* Unfortunately this doesn't work, __regparm__(1) is ignored. */
#  endif  /* else __WATCOMC__ */
#endif  /* __MINILIBC686__ */

#ifdef __MINILIBC686__
  /* Returns 0 on success, anything else (and sets errno) on error. The
   * implementation quite shorter than lseek64(...).
   */
  __LIBC_FUNC_RP3(int, lseek64_set, (int fd, off64_t offset),);
  __LIBC_FUNC(void *, sys_brk, (void *addr),);
#endif  /* __MINILIBC686__ */

#endif  /* _UNISTD_H */
