#define _GNU_SOURCE 1  /* For mremap(1) in uClibc. */
#include <fcntl.h>
#include <sys/ioctl.h>
#include <sys/mman.h>
#include <sys/stat.h>
#include <sys/syscall.h>
#include <sys/time.h>
#include <time.h>
#include <unistd.h>

#ifdef __MINILIBC686__
#  define MINI_NAME(name) mini_ ## name
#else
#  define MINI_NAME(name) name
#endif

int MINI_NAME(sys__llseek)(int fd, int offset_high, int offset_low, loff_t *result, int whence);
void *MINI_NAME(sys_mmap2)(void *addr, size_t length, int prot, int flags, int fd, off_t offset);
void *MINI_NAME(sys_brk)(void *addr);

#if !defined(__MINILIBC686__)
__inline__ int MINI_NAME(sys__llseek)(int fd, int offset_high, int offset_low, loff_t *result, int whence) {
  return syscall(SYS__llseek, fd, offset_high, offset_low, result, whence);
}
__inline__ void *MINI_NAME(sys_mmap2)(void *addr, size_t length, int prot, int flags, int fd, off_t offset) {
  return (void*)syscall(SYS_mmap2, addr, length, prot, flags, fd, offset);
}
__inline__ void *MINI_NAME(sys_brk)(void *addr) {
  return (void*)syscall(SYS_brk, addr);
}
#endif

int main(int argc, char **argv) {
  struct timeval tv;
  struct stat64 st64;
  (void)argv;
  if (argc < 0) {  /* Never happens. */
    /* TODO(pts): Add __attribute((__nonnull__(argi))) to minilibc386 .h fles. */
    fork();
    read(0, 0, 0);
    write(0, 0, 0);
    open("", 0, 0);
    close(0);
    creat("", 0);
    unlink("");
    lseek(0, 0, 0);
    (void)!getpid();
    geteuid();
    ioctl(0, TCGETS, 0);
    ftruncate(0, 0);
    MINI_NAME(sys__llseek)(0, 0, 0, 0, 0);
    MINI_NAME(sys_mmap2)(0, 0, 0, 0, 0, 0);
    mmap(0, 0, 0, 0, 0, 0);
    mremap(0, 0, 0, 0, 0);
    munmap(0, 0);
    MINI_NAME(sys_brk)(0);
    time(0);
    gettimeofday(&tv, 0);
    chmod("", 0);
    fchmod(0, 0);
    mkdir("", 0);
    lstat64("", &st64);
    symlink("", "");
    umask(0);
    utimes("", 0);
  }
  return 0;
}
