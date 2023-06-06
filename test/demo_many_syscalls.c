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

static __inline__ int sys__llseek_syscall(int fd, int offset_high, int offset_low, loff_t *result, int whence) {
  return syscall(SYS__llseek, fd, offset_high, offset_low, /*(int)*/result, whence);
}
static __inline__ void *sys_mmap2_syscall(void *addr, size_t length, int prot, int flags, int fd, off_t offset) {
  return (void*)syscall(SYS_mmap2, /*(int)*/addr, length, prot, flags, fd, offset);
}
static __inline__ void *sys_brk_syscall(void *addr) {
  return (void*)syscall(SYS_brk, /*(int)*/addr);
}

#ifdef __MINILIBC686__
static __inline__ int sys__llseek_syscalln(int fd, int offset_high, int offset_low, loff_t *result, int whence) {
  return syscall5(SYS__llseek, fd, offset_high, offset_low, (int)result, whence);
}
static __inline__ void *sys_mmap2_syscalln(void *addr, size_t length, int prot, int flags, int fd, off_t offset) {
  return (void*)syscall6(SYS_mmap2, (int)addr, length, prot, flags, fd, offset);
}
static __inline__ void *sys_brk_syscalln(void *addr) {
  return (void*)syscall1(SYS_brk, (int)addr);
}
#else
#  define sys__llseek_syscalln sys__llseek_syscall
#  define sys_mmap2_syscalln sys_mmap2_syscall
#  define sys_brk_syscalln sys_brk_syscall
#endif

#ifndef __MINILIBC686__
static __inline__ int sys__llseek(int fd, int offset_high, int offset_low, loff_t *result, int whence) {
  return syscall(SYS__llseek, fd, offset_high, offset_low, /*(int)*/result, whence);
}
static __inline__ void *sys_mmap2(void *addr, size_t length, int prot, int flags, int fd, off_t offset) {
  return (void*)syscall(SYS_mmap2, /*(int)*/addr, length, prot, flags, fd, offset);
}
static __inline__ void *sys_brk(void *addr) {
  return (void*)syscall(SYS_brk, /*(int)*/addr);
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
    sys__llseek(0, 0, 0, 0, 0);
    sys__llseek_syscall(0, 0, 0, 0, 0);
    sys__llseek_syscalln(0, 0, 0, 0, 0);
    sys_mmap2(0, 0, 0, 0, 0, 0);
    sys_mmap2_syscalln(0, 0, 0, 0, 0, 0);
    sys_mmap2_syscall(0, 0, 0, 0, 0, 0);
    mmap(0, 0, 0, 0, 0, 0);
    mremap(0, 0, 0, 0, 0);
    munmap(0, 0);
    sys_brk(0);
    sys_brk_syscall(0);
    sys_brk_syscalln(0);
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
