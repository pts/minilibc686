#ifndef _FCNTL_H
#define _FCNTL_H

#include <sys/types.h>

#define O_RDONLY 0
#define O_WRONLY 1
#define O_RDWR   2
#define O_CREAT 0100
#define O_EXCL  0200
#define O_TRUNC 01000

int open(const char *pathname, int flags, ...) __asm__("mini_open");  /* Optional 3rd argument: mode_t mode */
static __inline__ int creat(const char *pathname, mode_t mode) {  /* TODO(pts): Add with __NR_creat == 8. */
  return open(pathname, O_CREAT | O_WRONLY | O_TRUNC, mode);
}

#endif  /* _FCNTL_H */
