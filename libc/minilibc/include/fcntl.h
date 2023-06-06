#ifndef _FCNTL_H
#define _FCNTL_H
#include <_preincl.h>

#include <sys/types.h>

#define O_RDONLY 0
#define O_WRONLY 1
#define O_RDWR   2
#define O_ACCMODE 3
#define O_CREAT 0100
#define O_EXCL  0200
#define O_TRUNC 01000
#define O_NOCTTY 0400
#define O_APPEND 02000
#define O_NONBLOCK 04000
#define O_NDELAY O_NONBLOCK
#define O_DSYNC 010000
#define FASYNC 020000
#define O_DIRECT 040000
#define O_LARGEFILE 0100000
#define O_DIRECTORY 0200000
#define O_NOFOLLOW 0400000
#define O_NOATIME 01000000
#define O_CLOEXEC 02000000
#define O_SYNC (O_DSYNC|04000000)
#define O_PATH 010000000

__LIBC_FUNC(int, open, (const char *pathname, int flags, ...), __LIBC_NOATTR);  /* Optional 3rd argument: mode_t mode */
__LIBC_FUNC(int, creat, (const char *pathname, mode_t mode), __LIBC_NOATTR);  /* Optional 3rd argument: mode_t mode */
/*static __inline__ int creat(const char *pathname, mode_t mode) { return open(pathname, O_CREAT | O_WRONLY | O_TRUNC, mode); }*/  /* This would also work. */

#endif  /* _FCNTL_H */
