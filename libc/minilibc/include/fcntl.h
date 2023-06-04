#ifndef _FCNTL_H
#define _FCNTL_H
#include <_preincl.h>

#include <sys/types.h>

#define O_RDONLY 0
#define O_WRONLY 1
#define O_RDWR   2
#define O_CREAT 0100
#define O_EXCL  0200
#define O_TRUNC 01000

__LIBC_FUNC(int, open, (const char *pathname, int flags, ...), __LIBC_NOATTR);  /* Optional 3rd argument: mode_t mode */
__LIBC_FUNC(int, creat, (const char *pathname, mode_t mode), __LIBC_NOATTR);  /* Optional 3rd argument: mode_t mode */
/*static __inline__ int creat(const char *pathname, mode_t mode) { return open(pathname, O_CREAT | O_WRONLY | O_TRUNC, mode); }*/  /* This would also work. */

#endif  /* _FCNTL_H */
