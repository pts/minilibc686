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

__LIBC_PACKED_STRUCT struct stat64 {
  __extension__ __LIBC_PACKED unsigned long long st_dev;
  unsigned char __pad0[4];
  unsigned long __st_ino;
  unsigned int  st_mode;
  unsigned int  st_nlink;
  unsigned long st_uid;
  unsigned long st_gid;
  __extension__ __LIBC_PACKED unsigned long long st_rdev;
  unsigned char __pad3[4];
  __extension__ __LIBC_PACKED unsigned long long st_size;
  unsigned long st_blksize;
  /* Number 512-byte blocks allocated. */
  __extension__ __LIBC_PACKED unsigned long long st_blocks;
  unsigned long st_atime;
  unsigned long st_atime_nsec;
  unsigned long st_mtime;
  unsigned int  st_mtime_nsec;
  unsigned long st_ctime;
  unsigned long st_ctime_nsec;
  __extension__ __LIBC_PACKED unsigned long long st_ino;
};
__LIBC_STATIC_ASSERT(sizeof_struct_stat64, sizeof(struct stat64) == 96);

__LIBC_FUNC(int, mkdir, (const char *pathname, mode_t mode), __LIBC_NOATTR);
__LIBC_FUNC(mode_t, umask, (mode_t mask), __LIBC_NOATTR);
__LIBC_FUNC(int, chmod, (const char *pathname, mode_t mode), __LIBC_NOATTR);
__LIBC_FUNC(int, fchmod, (int fd, mode_t mode), __LIBC_NOATTR);
__LIBC_FUNC(int, stat64, (const char *path, struct stat64 *buf), __LIBC_NOATTR);
__LIBC_FUNC(int, lstat64, (const char *path, struct stat64 *buf), __LIBC_NOATTR);
__LIBC_FUNC(int, fstat64, (int fd, struct stat64 *buf), __LIBC_NOATTR);

#endif  /* _SYS_STAT_H */
