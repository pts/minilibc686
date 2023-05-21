#ifndef _UNISTD_H
#define _UNISTD_H

#include <sys/types.h>

/* lseek(..., ..., whence) constants. */
#define SEEK_SET 0
#define SEEK_CUR 1
#define SEEK_END 2

void _exit(int exit_code) __asm__("mini__exit") __attribute__((__noreturn__));  /* Doesn't flush stdio streams first. */
void exit(int exit_code) __asm__("mini_exit") __attribute__((__noreturn__));  /* Flushes stdio streams first. */
int close(int fd) __asm__("mini_close");
ssize_t read(int fd, void *buf, size_t count) __asm__("mini_read");
ssize_t write(int fd, const void *buf, size_t count) __asm__("mini_write");
off_t lseek(int fd, off_t offset, int whence) __asm__("mini_lseek");
off64_t lseek64(int fd, off64_t offset, int whence) __asm__("mini_lseek64");
long syscall(long nr, ...) __asm__("mini_syscall");
int unlink(const char *pathname) __asm__("mini_unlink");

#ifndef __UCLIBC__
long syscall0(long nr) __asm__("mini_syscall3_RP1") __attribute__((__regparm__(1)));
long syscall1(long nr, long arg1) __asm__("mini_syscall3_RP1") __attribute__((__regparm__(1)));
long syscall2(long nr, long arg1, long arg2) __asm__("mini_syscall3_RP1") __attribute__((__regparm__(1)));
long syscall3(long nr, long arg1, long arg2, long arg3) __asm__("mini_syscall3_RP1") __attribute__((__regparm__(1)));
/*long syscall_upto_3(long nr, ...) __asm__("mini_syscall3_RP1") __attribute__((__regparm__(1)));*/  /* Unfortunately this doesn't work, __regparm__(1) is ignored. */
/* Returns 0 on success, anything else (and sets errno) on error. The
 * implementation quite shorter than lseek64(...).
 */
int lseek64_set(int fd, off64_t offset) __asm__("mini_lseek64_set_RP3") __attribute__((__regparm__(3)));
#endif  /* !__UCLIBC__ */

#endif  /* _UNISTD_H */
