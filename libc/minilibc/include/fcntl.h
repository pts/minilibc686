#ifndef _FCNTL_H
#define _FCNTL_H
#include <_preincl.h>

#include <sys/types.h>

#define O_RDONLY 0
#define O_WRONLY 1
#define O_RDWR   2
#define O_ACCMODE 3
#ifdef CONFIG_NOT_LINUX
#  if defined(__MINILIBC686__) && defined(__FREEBSDOS__)  /* FreeBSD-specific. */
#    define O_CREAT 0x200
#    define O_TRUNC 0x400
#    define O_EXCL  0x800
#    define O_NOCTTY 0x8000
#    define O_APPEND 8
#  endif
#else  /* Linux-specifc. */
#  if defined(__MINILIBC686__) && defined(__FREEBSDOS__) && defined(__MULTIOS__)  /* Linux-specific, mini_open(...) will translate them to FreeBSD if needed. */
#    define O_CREAT 0100
#    define O_EXCL  0200
#    define O_TRUNC 01000
#    define O_NOCTTY 0400
#    define O_APPEND 02000
#    define O_LARGEFILE 0100000
#  else
#    define O_CREAT 0100
#    define O_EXCL  0200
#    define O_TRUNC 01000
#    define O_NOCTTY 0400
#    define O_APPEND 02000
#    define O_NONBLOCK 04000
#    define O_NDELAY O_NONBLOCK
#    define O_DSYNC 010000
#    define FASYNC 020000
#    define O_DIRECT 040000
#    define O_LARGEFILE 0100000
#    define O_DIRECTORY 0200000
#    define O_NOFOLLOW 0400000
#    define O_NOATIME 01000000
#    define O_CLOEXEC 02000000
#    define O_SYNC (O_DSYNC|04000000)
#    define O_PATH 010000000
#  endif
#endif

#if defined(__MINILIBC686__)
#  if _FILE_OFFSET_BITS == 64
    int open(const char *pathname, int flags, ...) __LIBC_MAYBE_ASM(__LIBC_MINI "open_largefile");  /* Optional 3rd argument: mode_t mode. */
#    ifdef __WATCOMC__
#      pragma aux open "_mini_open_largefile"
#    endif
#  else
    __LIBC_FUNC(int, open, (const char *pathname, int flags, ...), __LIBC_NOATTR);  /* Optional 3rd argument: mode_t mode */
#  endif
  __LIBC_FUNC(int, open_largefile, (const char *pathname, int flags, ...), __LIBC_NOATTR);  /* Optional 3rd argument: mode_t mode */
#else
  __LIBC_FUNC(int, open, (const char *pathname, int flags, ...), __LIBC_NOATTR);  /* Optional 3rd argument: mode_t mode */
#endif
#ifdef __MINILIBC686__
__LIBC_FUNC(int, __M_fopen_open, (const char *pathname, int flags, ...), __LIBC_NOATTR);  /* Optional 3rd argument: mode_t mode */
#endif
__LIBC_FUNC(int, creat, (const char *pathname, mode_t mode), __LIBC_NOATTR);  /* Optional 3rd argument: mode_t mode */
/*static __inline__ int creat(const char *pathname, mode_t mode) { return open(pathname, O_CREAT | O_WRONLY | O_TRUNC, mode); }*/  /* This would also work. */

#endif  /* _FCNTL_H */
