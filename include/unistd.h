#ifndef _UNISTD_H
#define _UNISTD_H

#define NULL ((void*)0)

void _exit(int exit_code) __asm__("mini__exit");  /* Doesn't flush stdio streams first. */
void exit(int exit_code) __asm__("mini_exit");  /* Flushes stdio streams first. */
int close(int fd) __asm__("mini_close");
ssize_t read(int fd, void *buf, size_t count) __asm__("mini_read");
ssize_t write(int fd, const void *buf, size_t count) __asm__("mini_write");
off_t lseek(int fd, off_t offset, int whence) __asm__("mini_lseek");

#endif  /* _UNISTD_H */
