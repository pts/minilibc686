#ifndef _SYS_IOCTL_H
#define _SYS_IOCTL_H
#include <_preincl.h>

#define TCGETS 0x5401

__LIBC_FUNC(int, ioctl, (int fd, unsigned long request, ...), __LIBC_NOATTR);

#endif  /* _SYS_IOCTL_H */
