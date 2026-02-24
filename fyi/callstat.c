/* by pts@fazekas.hu at Tue Feb 24 17:17:02 CET 2026 */

#ifndef __i386__
#  error i386 architecture required.
#endif
#include <sys/stat.h>
int mystatsize(void) { return sizeof(struct stat); }
int  mystat(const char *pathname, struct stat *statbuf) { return  stat(pathname, statbuf); }
int mylstat(const char *pathname, struct stat *statbuf) { return lstat(pathname, statbuf); }
int myfstat(int fd, struct stat *statbuf) { return fstat(fd, statbuf); }

/*
$ echo $(gcc -m32 -fno-pic -c -o t.o fyi/callstat.c && nm t.o | perl -lne 'print($1) if m@^\s+U\s+(\w+)$@' | sort && objdump -d t.o | grep -C5 -F '<mystatsize>' | perl -lne 'print hex($1) if m@\s+mov\s+\$0x([0-9A-Fa-f]+),%eax@')  # glibc-2.27 on Ubuntu 18.04.
fstat lstat stat 88
$ echo $(pathbin/minicc --gcc=4.8 --minilibc -c -o t.o fyi/callstat.c && nm t.o | perl -lne 'print($1) if m@^\s+U\s+(\w+)$@' | sort && objdump -d t.o | grep -C5 -F '<mystatsize>' | perl -lne 'print hex($1) if m@\s+mov\s+\$0x([0-9A-Fa-f]+),%eax@')
mini_fstat mini_lstat mini_stat 64
$ echo $(pathbin/minicc --gcc=4.8 -D_FILE_OFFSET_BITS=64 --minilibc -c -o t.o fyi/callstat.c && nm t.o | perl -lne 'print($1) if m@^\s+U\s+(\w+)$@' | sort && objdump -d t.o | grep -C5 -F '<mystatsize>' | perl -lne 'print hex($1) if m@\s+mov\s+\$0x([0-9A-Fa-f]+),%eax@')
mini_fstat64 mini_lstat64 mini_stat64 96
$ echo $(pathbin/minicc --gcc=4.8 --uclibc -c -o t.o fyi/callstat.c && nm t.o | perl -lne 'print($1) if m@^\s+U\s+(\w+)$@' | sort && objdump -d t.o | grep -C5 -F '<mystatsize>' | perl -lne 'print hex($1) if m@\s+mov\s+\$0x([0-9A-Fa-f]+),%eax@')
fstat lstat stat 88
$ echo $(pathbin/minicc --gcc=4.8 -D_FILE_OFFSET_BITS=64 --uclibc -c -o t.o fyi/callstat.c && nm t.o | perl -lne 'print($1) if m@^\s+U\s+(\w+)$@' | sort && objdump -d t.o | grep -C5 -F '<mystatsize>' | perl -lne 'print hex($1) if m@\s+mov\s+\$0x([0-9A-Fa-f]+),%eax@')
fstat64 lstat64 stat64 96
$ echo $(pathbin/minicc --gcc=4.8 --eglibc -c -o t.o fyi/callstat.c && nm t.o | perl -lne 'print($1) if m@^\s+U\s+(\w+)$@' | sort && objdump -d t.o | grep -C5 -F '<mystatsize>' | perl -lne 'print hex($1) if m@\s+mov\s+\$0x([0-9A-Fa-f]+),%eax@')
fstat lstat stat 88
$ echo $(pathbin/minicc --gcc=4.8 -D_FILE_OFFSET_BITS=64 --eglibc -c -o t.o fyi/callstat.c && nm t.o | perl -lne 'print($1) if m@^\s+U\s+(\w+)$@' | sort && objdump -d t.o | grep -C5 -F '<mystatsize>' | perl -lne 'print hex($1) if m@\s+mov\s+\$0x([0-9A-Fa-f]+),%eax@')
fstat64 lstat64 stat64 96
*/

#undef st_atime
#undef st_mtime
#undef st_ctime

/* $ pathbin/minicc --gcc=4.8 --minilibc -E t.o fyi/callstat.c | grep '^[^#]' | indent | ... */
struct minilibc_stat {  /* 64 bytes */  /* For i386 syscalls SYS_stat, SYS_lstat, SYS_fstat == 108. Already supported by Linux 1.0. */
  unsigned long  st_dev;
  unsigned long  st_ino;
  unsigned short st_mode;
  unsigned short st_nlink;
  unsigned short st_uid;  /* Special returned value 0xfffe means larger than 0xffff. */
  unsigned short st_gid;  /* Special returned value 0xfffe means larger than 0xffff. */
  unsigned long  st_rdev;
  unsigned long  st_size;  /* If file_size >= 0x80000000, then the syscall fails with EOVERFLOW == 75 == Value too large for defined data type. */
  unsigned long  st_blksize;  /* Maybe incorrect: 0x1000 reported here instead of 0x200 reported in struct stat64. */
  unsigned long  st_blocks;  /* Number of 512-byte blocks allocated. */
  long st_atime;
  unsigned long  st_atime_nsec;
  long st_mtime;
  unsigned long  st_mtime_nsec;
  long st_ctime;
  unsigned long  st_ctime_nsec;
  unsigned long  __unused4;
  unsigned long  __unused5;
};
typedef char assert_sizeof_minilibc_stat[sizeof(struct minilibc_stat) == 64 ? 1 : -1];

/* $ pathbin/minicc --gcc=4.8 --minilibc -D_FILE_OFFSET_BITS=64 -E t.o fyi/callstat.c | grep '^[^#]' | indent | ... */
struct minilibc_stat64 {  /* 96 bytes */  /* For i386 syscalls SYS_stat64, SYS_lstat64, SYS_fstat64 == 197 (needs Linux >=2.4), SYS_fstatat64 == 300 (needs Linux >=2.6.16). */
  unsigned long long st_dev;
  unsigned char __pad0[4];
  unsigned long __st_ino;  /* Unused, st_ino below is used instead. */
  unsigned      st_mode;
  unsigned      st_nlink;
  unsigned      st_uid;
  unsigned      st_gid;
  unsigned long long st_rdev;
  unsigned char __pad3[4];
  unsigned long long st_size;
  unsigned long st_blksize;
  unsigned long long st_blocks;  /* Number of 512-byte blocks allocated. */
  long st_atime;
  unsigned long st_atime_nsec;
  long st_mtime;
  unsigned long st_mtime_nsec;
  long st_ctime;
  unsigned long st_ctime_nsec;
  unsigned long long st_ino;
};
typedef char assert_sizeof_minilibc_stat64[sizeof(struct minilibc_stat64) == 96 ? 1 : -1];

/* $ pathbin/minicc --gcc=4.8 --uclibc -E t.o fyi/callstat.c | grep '^[^#]' | indent | ... */
struct uclibc_stat {  /* 88 bytes */
  /*__dev_t*/ /*__u_quad_t*/ unsigned long long st_dev;
  unsigned short __pad1;
  /*__ino_t*/ unsigned long st_ino;
  /*__mode_t*/ unsigned st_mode;
  /*__nlink_t*/ unsigned st_nlink;
  /*__uid_t*/ unsigned st_uid;
  /*__gid_t*/ unsigned st_gid;
  /*__dev_t*/ /*__u_quad_t*/ unsigned long long st_rdev;
  unsigned short __pad2;
  /*__off_t*/ long st_size;
  /*__blksize_t*/ long st_blksize;
  /*__blkcnt_t*/ long st_blocks;
  /*__time_t*/ long st_atime;
  unsigned long st_atimensec;
  /*__time_t*/ long st_mtime;
  unsigned long st_mtimensec;
  /*__time_t*/ long st_ctime;
  unsigned long st_ctimensec;
  unsigned long __unused4;
  unsigned long __unused5;
};
typedef char assert_sizeof_uclibc_stat[sizeof(struct uclibc_stat) == 88 ? 1 : -1];

/* $ pathbin/minicc --gcc=4.8 --uclibc -D_FILE_OFFSET_BITS=64 -E t.o fyi/callstat.c | grep '^[^#]' | indent | ... */
struct uclibc_stat64 {  /* 96 bytes */
  /*__dev_t*/ /*__u_quad_t*/ unsigned long long st_dev;
  unsigned __pad1;
  /*__ino_t*/ unsigned long __st_ino;  /* Unused, st_ino below is used instead. */
  /*__mode_t*/ unsigned st_mode;
  /*__nlink_t*/ unsigned st_nlink;
  /*__uid_t*/ unsigned st_uid;
  /*__gid_t*/ unsigned st_gid;
  /*__dev_t*/ /*__u_quad_t*/ unsigned long long st_rdev;
  unsigned __pad2;
  /*__off64_t*/ /*__quad_t*/ long long st_size;
  /*__blksize_t*/ long st_blksize;
  /*__blkcnt64_t*/ /*__quad_t*/ long long st_blocks;
  /*__time_t*/ long st_atime;
  unsigned long st_atimensec;
  /*__time_t*/ long st_mtime;
  unsigned long st_mtimensec;
  /*__time_t*/ long st_ctime;
  unsigned long st_ctimensec;
  /*__ino64_t*/ /*__u_quad_t*/ unsigned long long st_ino;
};
typedef char assert_sizeof_uclibc_stat64[sizeof(struct uclibc_stat64) == 96 ? 1 : -1];

/* $ pathbin/minicc --gcc=4.8 --eglibc -E t.o fyi/callstat.c | grep '^[^#]' | indent | ... */
#if 0
#  define st_atime st_atim.tv_sec
#  define st_mtime st_mtim.tv_sec
#  define st_ctime st_ctim.tv_sec
#endif
struct eglibc_stat_timespec {  /* 88 bytes */
  /*__time_t*/ long tv_sec;
  /*__syscall_slong_t*/ long tv_nsec;
};
struct eglibc_stat {
  /*__dev_t*/  /*__u_quad_t*/ unsigned long long st_dev;
  unsigned short __pad1;
  /*__ino_t*/ unsigned long st_ino;
  /*__mode_t*/ unsigned st_mode;
  /*__nlink_t*/ unsigned st_nlink;
  /*__uid_t*/ unsigned st_uid;
  /*__gid_t*/ unsigned st_gid;
  /*__dev_t*/ /*__u_quad_t*/ unsigned long long st_rdev;
  unsigned short __pad2;
  /*__off_t*/ long st_size;
  /*__blksize_t*/ long st_blksize;
  /*__blkcnt_t*/ long st_blocks;
  struct eglibc_stat_timespec st_atim;
  struct eglibc_stat_timespec st_mtim;
  struct eglibc_stat_timespec st_ctim;
  unsigned long __glibc_reserved4;
  unsigned long __glibc_reserved5;
};
typedef char assert_sizeof_eglibc_stat[sizeof(struct eglibc_stat) == 88 ? 1 : -1];

/* pathbin/minicc --gcc=4.8 --eglibc -D_POSIX_SOURCE -E t.o fyi/callstat.c | grep '^[^#]' | indent | ... */
struct eglibc_posix_stat {  /* 88 bytes */
  /*__dev_t*/ /*__u_quad_t*/ unsigned long long st_dev;
  unsigned short __pad1;
  /*__ino_t*/ unsigned long st_ino;
  /*__mode_t*/ unsigned st_mode;
  /*__nlink_t*/ unsigned st_nlink;
  /*__uid_t*/ unsigned st_uid;
  /*__gid_t*/ unsigned st_gid;
  /*__dev_t*/ /*__u_quad_t*/ unsigned long long st_rdev;
  unsigned short __pad2;
  /*__off_t*/ long st_size;
  /*__blksize_t*/ long st_blksize;
  /*__blkcnt_t*/ long st_blocks;
  /*__time_t*/ long st_atime;
  /*__syscall_ulong_t*/ unsigned long st_atimensec;
  /*__time_t*/ long st_mtime;
  /*__syscall_ulong_t*/ unsigned long st_mtimensec;
  /*__time_t*/ long st_ctime;
  /*__syscall_ulong_t*/ unsigned long st_ctimensec;
  unsigned long __glibc_reserved4;
  unsigned long __glibc_reserved5;
};
typedef char assert_sizeof_eglibc_posix_stat[sizeof(struct eglibc_posix_stat) == 88 ? 1 : -1];

/* $ pathbin/minicc --gcc=4.8 --eglibc -D_FILE_OFFSET_BITS=64 -E t.o fyi/callstat.c | grep '^[^#]' | indent | ... */
#if 0
#  define st_atime st_atim.tv_sec
#  define st_mtime st_mtim.tv_sec
#  define st_ctime st_ctim.tv_sec
#endif
struct eglibc_stat64_timespec {
  /*__time_t*/ long tv_sec;
  /*__syscall_slong_t*/ long tv_nsec;
};
struct eglibc_stat64 {  /* 96 bytes */
  /*__dev_t*/  /*__u_quad_t*/ unsigned long long st_dev;
  unsigned short __pad1;
  /*__ino_t*/ unsigned long __st_ino;  /* Unused, st_ino below is used instead. */
  /*__mode_t*/ unsigned st_mode;
  /*__nlink_t*/ unsigned st_nlink;
  /*__uid_t*/ unsigned st_uid;
  /*__gid_t*/ unsigned st_gid;
  /*__dev_t*/  /*__u_quad_t*/ unsigned long long st_rdev;
  unsigned short __pad2;
  /*__off64_t*/ /*__quad_t*/ long long st_size;
  /*__blksize_t*/ long st_blksize;
  /*__blkcnt64_t*/ /*__quad_t*/ long long st_blocks;
  struct eglibc_stat64_timespec st_atim;
  struct eglibc_stat64_timespec st_mtim;
  struct eglibc_stat64_timespec st_ctim;
  /*__ino64_t*/ /*__u_quad_t*/ unsigned long long st_ino;
};
typedef char assert_sizeof_eglibc_stat64[sizeof(struct eglibc_stat64) == 96 ? 1 : -1];

/* $ pathbin/minicc --gcc=4.8 --eglibc -D_POSIX_SOURCE -D_FILE_OFFSET_BITS=64 -E t.o fyi/callstat.c | grep '^[^#]' | indent | ... */
struct eglibc_posix_stat64 {
  /*__dev_t*/  /*__u_quad_t*/ unsigned long long st_dev;
  unsigned short __pad1;
  /*__ino_t*/ unsigned long __st_ino;  /* Unused, st_ino below is used instead. */
  /*__mode_t*/ unsigned st_mode;
  /*__nlink_t*/ unsigned st_nlink;
  /*__uid_t*/ unsigned st_uid;
  /*__gid_t*/ unsigned st_gid;
  /*__dev_t*/  /*__u_quad_t*/ unsigned long long st_rdev;
  unsigned short __pad2;
  /*__off64_t*/ /*__quad_t*/ long long st_size;
  /*__blksize_t*/ long st_blksize;
  /*__blkcnt64_t*/ /*__quad_t*/ long long st_blocks;
  /*__time_t*/ long st_atime;
  /*__syscall_ulong_t*/ unsigned long st_atimensec;
  /*__time_t*/ long st_mtime;
  /*__syscall_ulong_t*/ unsigned long st_mtimensec;
  /*__time_t*/ long st_ctime;
  /*__syscall_ulong_t*/ unsigned long st_ctimensec;
  /*__ino64_t*/ /*__u_quad_t*/ unsigned long long st_ino;
};
typedef char assert_sizeof_eglibc_posix_stat64[sizeof(struct eglibc_posix_stat64) == 96 ? 1 : -1];

/* __END__ */
