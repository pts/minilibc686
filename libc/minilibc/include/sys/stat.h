#ifndef _SYS_STAT_H
#define _SYS_STAT_H
#include <_preincl.h>

#include <sys/types.h>

#define S_IFMT  00170000
#define S_IFSOCK 0140000
#define S_IFLNK	 0120000
#define S_IFREG  0100000
#define S_IFBLK  0060000
#define S_IFDIR  0040000
#define S_IFCHR  0020000
#define S_IFIFO  0010000
#define S_ISUID  0004000
#define S_ISGID  0002000
#define S_ISVTX  0001000

#define S_ISLNK(m)	(((m) & S_IFMT) == S_IFLNK)
#define S_ISREG(m)	(((m) & S_IFMT) == S_IFREG)
#define S_ISDIR(m)	(((m) & S_IFMT) == S_IFDIR)
#define S_ISCHR(m)	(((m) & S_IFMT) == S_IFCHR)
#define S_ISBLK(m)	(((m) & S_IFMT) == S_IFBLK)
#define S_ISFIFO(m)	(((m) & S_IFMT) == S_IFIFO)
#define S_ISSOCK(m)	(((m) & S_IFMT) == S_IFSOCK)

/* These fields must be __LIBC_PACKED for amd64, because the default
 * alignment for `long long' is 8 there. __PCC__ fails with in internal
 * error `strmemb' if we add __LIBC_PACKED here.
 *
 * The struct matches glibc 2.1 and 2.2 and Linux i386 stat64(2). The padding around
 * st_dev and st_drev is useless, but this is how it was used in glibc 2.2.
 *
 * struct stat, struct stat64 and struct __old_kernel_stat are based on
 *  https://github.com/torvalds/linux/blob/c964ced7726294d40913f2127c3f185a92cb4a41/arch/x86/include/uapi/asm/stat.h
 *
 * struct stat64 is for i386 syscalls SYS_stat64, SYS_lstat64, SYS_fstat64, SYS_fstatat64.
 */
__LIBC_PACKED_STRUCT struct stat64 {
  __extension__ unsigned long long st_dev;
  unsigned char __pad0[4];
  unsigned long __st_ino;  /* Unused, see st_ino below. */
  unsigned int  st_mode;
  unsigned int  st_nlink;
  unsigned long st_uid;
  unsigned long st_gid;
  __extension__ unsigned long long st_rdev;
  unsigned char __pad3[4];
  __extension__ unsigned long long st_size;
  unsigned long st_blksize;
  /* Number 512-byte blocks allocated. */
  __extension__ unsigned long long st_blocks;
  unsigned long st_atime;
  unsigned long st_atime_nsec;
  unsigned long st_mtime;
  unsigned int  st_mtime_nsec;
  unsigned long st_ctime;
  unsigned long st_ctime_nsec;
  __extension__ unsigned long long st_ino;
};
__LIBC_STATIC_ASSERT(sizeof_struct_stat64, sizeof(struct stat64) == 96);

struct stat {  /* For i386 syscalls SYS_stat, SYS_lstat, SYS_fstat. */
  unsigned long  st_dev;
  unsigned long  st_ino;
  unsigned short st_mode;
  unsigned short st_nlink;
  unsigned short st_uid;  /* Special returned value 0xfffe means larger than 0xffff. */
  unsigned short st_gid;  /* Special returned value 0xfffe means larger than 0xffff. */
  unsigned long  st_rdev;
  unsigned long  st_size;  /* If file_size >= 0x80000000, then the syscall fails with EOVERFLOW == 75 == Value too large for defined data type. */
  unsigned long  st_blksize;  /* May be incorrect: 0x1000 reported here instead of 0x200 reported in struct stat64. */
  unsigned long  st_blocks;
  unsigned long  st_atime;
  unsigned long  st_atime_nsec;
  unsigned long  st_mtime;
  unsigned long  st_mtime_nsec;
  unsigned long  st_ctime;
  unsigned long  st_ctime_nsec;
  unsigned long  __unused4;
  unsigned long  __unused5;
};
__LIBC_STATIC_ASSERT(sizeof_struct_stat, sizeof(struct stat) == 64);

struct __old_kernel_stat {  /* For i386 syscalls SYS_oldstat, SYS_oldlstat, SYS_oldfstat. */
  unsigned short st_dev;
  unsigned short st_ino;
  unsigned short st_mode;
  unsigned short st_nlink;
  unsigned short st_uid;  /* Special returned value 0xfffe means larger than 0xffff. */
  unsigned short st_gid;  /* Special returned value 0xfffe means larger than 0xffff. */
  unsigned short st_rdev;
  unsigned short __pad1;
  unsigned long  st_size;  /* If file_size >= 0x80000000, then the syscall fails with EOVERFLOW == 75 == Value too large for defined data type. */
  unsigned long  st_atime;
  unsigned long  st_mtime;
  unsigned long  st_ctime;
};
__LIBC_STATIC_ASSERT(sizeof_struct___old_kernel_stat, sizeof(struct __old_kernel_stat) == 32);

__LIBC_FUNC(int, mkdir, (const char *pathname, mode_t mode), __LIBC_NOATTR);
__LIBC_FUNC(mode_t, umask, (mode_t mask), __LIBC_NOATTR);
__LIBC_FUNC(int, chmod, (const char *pathname, mode_t mode), __LIBC_NOATTR);
__LIBC_FUNC(int, fchmod, (int fd, mode_t mode), __LIBC_NOATTR);
__LIBC_FUNC(int, stat64, (const char *path, struct stat64 *buf), __LIBC_NOATTR);
__LIBC_FUNC(int, lstat64, (const char *path, struct stat64 *buf), __LIBC_NOATTR);
__LIBC_FUNC(int, fstat64, (int fd, struct stat64 *buf), __LIBC_NOATTR);
#ifdef __MINILIBC686__  /* glibc has a different `struct stat' layout. */
  __LIBC_FUNC(int, stat, (const char *path, struct stat *buf), __LIBC_NOATTR);
  __LIBC_FUNC(int, lstat, (const char *path, struct stat *buf), __LIBC_NOATTR);
  __LIBC_FUNC(int, fstat, (int fd, struct stat *buf), __LIBC_NOATTR);
#endif
#ifdef __MINILIBC686__  /* Other libs don't have oldstat(2) etc. */
  __LIBC_FUNC(int, sys_oldstat, (const char *path, struct __old_kernel_stat *buf), __LIBC_NOATTR);
  __LIBC_FUNC(int, sys_oldlstat, (const char *path, struct __old_kernel_stat *buf), __LIBC_NOATTR);
  __LIBC_FUNC(int, sys_oldfstat, (int fd, struct __old_kernel_stat *buf), __LIBC_NOATTR);
#endif

#endif  /* _SYS_STAT_H */
