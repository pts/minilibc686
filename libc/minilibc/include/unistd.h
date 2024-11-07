#ifndef _UNISTD_H
#define _UNISTD_H
#include <_preincl.h>

#include <sys/types.h>

/* lseek(..., ..., whence) constants. */
#define SEEK_SET 0
#define SEEK_CUR 1
#define SEEK_END 2

/* access(...) constants. */
#define F_OK 0
#define X_OK 1
#define W_OK 2
#define R_OK 4

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
__LIBC_FUNC(int, rename, (const char *oldpath, const char *newpath), __LIBC_NOATTR);  /* Typically rename(2) is defined in <stdio.h>, bu we are lenient are and define in <unistd.h> as well. */
/* Limitation: it doesn't always set errno in minilibc686. */
__LIBC_FUNC(int, isatty, (int fd), __LIBC_NOATTR);
__LIBC_FUNC(int, ftruncate, (int fd, off_t length), __LIBC_NOATTR);  /* 32-bit length. */
__LIBC_FUNC(int, symlink, (const char *target, const char *linkpath), __LIBC_NOATTR);
__LIBC_FUNC(uid_t, getuid, (void), __LIBC_NOATTR);
__LIBC_FUNC(uid_t, geteuid, (void), __LIBC_NOATTR);
__LIBC_FUNC(gid_t, getgid, (void), __LIBC_NOATTR);
__LIBC_FUNC(gid_t, getegid, (void), __LIBC_NOATTR);
__LIBC_FUNC(pid_t, getpid, (void), __LIBC_NOATTR);
__LIBC_FUNC(pid_t, getppid, (void), __LIBC_NOATTR);
__LIBC_FUNC(pid_t, fork, (void), __LIBC_NOATTR);
__LIBC_FUNC(void *, sys_brk, (void *addr), __LIBC_NOATTR);
__LIBC_FUNC(int, execve, (const char *filename, char *const argv[], char *const envp[]), __LIBC_NOATTR);
__LIBC_FUNC(int, execvp, (const char *file, char *const argv[]), __LIBC_NOATTR);
__LIBC_FUNC(pid_t, setsid, (void), __LIBC_NOATTR);

__LIBC_FUNC(ssize_t, readlink, (const char *pathname, char *buf, size_t bufsiz), __LIBC_NOATTR);
__LIBC_FUNC(char *, getcwd, (char *buf, size_t size), __LIBC_NOATTR);  /* Limitation: if argument buf is NULL, then it returns NULL, it doesn't allocate memory dynamically. */
__LIBC_FUNC(int, access, (const char *name, int type), __LIBC_NOATTR);

__LIBC_VAR(extern int, optind);
__LIBC_VAR(extern int, opterr);
__LIBC_VAR(extern int, optopt);
__LIBC_VAR(extern char *, optarg);
#ifdef __WATCOMC__  /* There is no other way with `wcc386 -za'. */
#  pragma aux optind "_mini_*"
#  pragma aux opterr "_mini_*"
#  pragma aux optopt "_mini_*"
#  pragma aux optarg "_mini_*"
#endif
__LIBC_FUNC(int, getopt, (int argc, char *const argv[], const char *options), __LIBC_NOATTR);

static __inline__ int getpagesize(void) { return 0x1000; }  /* The .a file also contains mini_getpagesize(...), for binary compatibility. */
#ifdef __MINILIBC686__
  /* Returns 0 on success, anything else (and sets errno) on error. The
   * implementation quite shorter than lseek64(...).
   */
  __LIBC_FUNC_RP3(int, lseek64_set, (int fd, off64_t offset), __LIBC_NOATTR);
  __LIBC_FUNC(int, sys_llseek, (int fd, int offset_high, int offset_low, loff_t *result, int whence), __LIBC_NOATTR);  /* System call. Use lseek(...) or lseek64(...) above instead. */
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
    long syscall6(long nr, long arg1, long arg2, long arg3, long arg4, long arg5, long arg6) __asm__("mini_syscall6_RP1") __attribute__((__regparm__(1)));  /* It's imposible for a Linux i386 syscall to receive more than 6 arguments. */
    /*long syscall_upto_3(long nr, ...) __asm__("mini_syscall3_RP1") __attribute__((__regparm__(1)));*/  /* Unfortunately this doesn't work, __regparm__(1) is ignored. */
#  endif  /* else __WATCOMC__ */
#  if defined(CONFIG_MACRO_SYSCALL) && (defined(__WATCOMC__) || defined(__TINYC__) || (defined(__GNUC__) && (!defined(__STRICT_ANSI__) || __STDC_VERSION__ >= 199901L)))
     /* Using this (-DCONFIG_MACRO_SYSCALL) sometimes make the code longer,
      * sometimes shorter. The call site is 3 bytes longer for
      * small-numbered syscalls (because `mov eax, ...' is 5 bytes, and
      * `push byte ...' is 2 bytes), but if all syscalls have 0..3
      * arguments, then doesn't depend on mini_syscall(...),, but only
      * mini_syscall3_RP1(...), saving 0x27 bytes.
      *
      * Calling it with more than 6 arguments after `nr' is undefined.
      */
#    define __LIBC_SYSCALL0_CAST(nr) syscall0((nr))
#    define __LIBC_SYSCALL1_CAST(nr, a1) syscall1((nr), (int)(a1))  /* Limitation: it can't pass `double' (never needed) or `long long' arguments, but `...' can. */
#    define __LIBC_SYSCALL2_CAST(nr, a1, a2) syscall2((nr), (int)(a1), (int)(a2))
#    define __LIBC_SYSCALL3_CAST(nr, a1, a2, a3) syscall3((nr), (int)(a1), (int)(a2), (int)(a3))
#    define __LIBC_SYSCALL4_CAST(nr, a1, a2, a3, a4) syscall4((nr), (int)(a1), (int)(a2), (int)(a3), (int)(a4))
#    define __LIBC_SYSCALL5_CAST(nr, a1, a2, a3, a4, a5) syscall5((nr), (int)(a1), (int)(a2), (int)(a3), (int)(a4), (int)(a5))
#    define __LIBC_SYSCALL6_CAST(nr, a1, a2, a3, a4, a5, a6) syscall6((nr), (int)(a1), (int)(a2), (int)(a3), (int)(a4), (int)(a5), (int)(a6))
#    define __LIBC_SYSCALL_ARG12(a1, a2, a3, a4, a5, a6, a7, a8, a9, a10, a11, a12, ...) a12
#    define syscall(...) __LIBC_SYSCALL_ARG12(dummy, ## __VA_ARGS__, syscall9, syscall8, syscall7, __LIBC_SYSCALL6_CAST, __LIBC_SYSCALL5_CAST, __LIBC_SYSCALL4_CAST, __LIBC_SYSCALL3_CAST, __LIBC_SYSCALL2_CAST, __LIBC_SYSCALL1_CAST, __LIBC_SYSCALL0_CAST, __syscall_bad_noarg)(__VA_ARGS__)
#  endif  /* CONFIG_MACRO_SYSCALL */
#endif  /* __MINILIBC686__ */

#endif  /* _UNISTD_H */
