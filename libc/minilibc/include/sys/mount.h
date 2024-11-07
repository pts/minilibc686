#ifndef _SYS_MOUNT_H
#define _SYS_MOUNT_H
#include <_preincl.h>
#include <sys/ioctl.h>  /* _IO etc. */

#define BLOCK_SIZE 1024
#define BLOCK_SIZE_BITS 10
enum {
  MS_RDONLY = 1,
#define MS_RDONLY MS_RDONLY
  MS_NOSUID = 2,
#define MS_NOSUID MS_NOSUID
  MS_NODEV = 4,
#define MS_NODEV MS_NODEV
  MS_NOEXEC = 8,
#define MS_NOEXEC MS_NOEXEC
  MS_SYNCHRONOUS = 16,
#define MS_SYNCHRONOUS MS_SYNCHRONOUS
  MS_REMOUNT = 32,
#define MS_REMOUNT MS_REMOUNT
  MS_MANDLOCK = 64,
#define MS_MANDLOCK MS_MANDLOCK
  S_WRITE = 128,
#define S_WRITE S_WRITE
  S_APPEND = 256,
#define S_APPEND S_APPEND
  S_IMMUTABLE = 512,
#define S_IMMUTABLE S_IMMUTABLE
  MS_NOATIME = 1024,
#define MS_NOATIME MS_NOATIME
  MS_NODIRATIME = 2048,
#define MS_NODIRATIME MS_NODIRATIME
  MS_BIND = 4096,
#define MS_BIND MS_BIND
  MS_MOVE = 8192,
#define MS_MOVE		MS_MOVE
  MS_REC = 16384,
#define MS_REC		MS_REC
  MS_SILENT = 32768,
#define MS_VERBOSE	MS_SILENT
#define MS_SILENT	MS_SILENT
  MS_POSIXACL = (1<<16),
#define MS_POSIXACL	MS_POSIXACL
  MS_UNBINDABLE = (1<<17),
#define MS_UNBINDABLE	MS_UNBINDABLE
  MS_PRIVATE = (1<<18),
#define MS_PRIVATE	MS_PRIVATE
  MS_SLAVE = (1<<19),
#define MS_SLAVE	MS_SLAVE
  MS_SHARED = (1<<20),
#define MS_SHARED	MS_SHARED
  MS_RELATIME = (1<<21),
#define MS_RELATIME	MS_RELATIME
  MS_KERNMOUNT = (1<<22),
#define MS_KERNMOUNT	MS_KERNMOUNT
  MS_I_VERSION = (1<<23),
#define MS_I_VERSION	MS_I_VERSION
  MS_STRICTATIME = (1<<24),
#define MS_STRICTATIME	MS_STRICTATIME
  MS_NOSEC = (1<<28),
#define MS_NOSEC	MS_NOSEC
  MS_BORN = (1<<29),
#define MS_BORN		MS_BORN
  MS_ACTIVE = (1<<30),
#define MS_ACTIVE	MS_ACTIVE
  MS_NOUSER = (1<<31)
#define MS_NOUSER	MS_NOUSER
};

/* Flags that can be altered by MS_REMOUNT. */
#define MS_RMT_MASK (MS_RDONLY|MS_SYNCHRONOUS|MS_MANDLOCK|MS_NOATIME|MS_NODIRATIME)

/* Magic mount flag number. Has to be or-ed to the flag values.  */
#define MS_MGC_VAL 0xc0ed0000
#define MS_MGC_MSK 0xffff0000

#define BLKROSET _IO(0x12, 93)
#define BLKROGET _IO(0x12, 94)
#define BLKRRPART _IO(0x12, 95)
#define BLKGETSIZE _IO(0x12, 96)
#define BLKFLSBUF _IO(0x12, 97)
#define BLKRASET _IO(0x12, 98)
#define BLKRAGET _IO(0x12, 99)
#define BLKFRASET _IO(0x12,100)
#define BLKFRAGET _IO(0x12,101)
#define BLKSECTSET _IO(0x12,102)
#define BLKSECTGET _IO(0x12,103)
#define BLKSSZGET _IO(0x12,104)
#define BLKBSZGET _IOR(0x12,112,size_t)
#define BLKBSZSET _IOW(0x12,113,size_t)
#define BLKGETSIZE64 _IOR(0x12,114,size_t)
enum {
  MNT_FORCE = 1,
#define MNT_FORCE MNT_FORCE  /* Force unmounting.  */
  MNT_DETACH = 2  /* Just detach, unmount when last reference dies.  */
#define MNT_DETACH MNT_DETACH
};
__LIBC_FUNC(int, mount, (const char *special_file, const char *dir, const char *fstype, unsigned long rwflag, const void *data), __LIBC_NOATTR);
__LIBC_FUNC(int, umount, (const char *special_file), __LIBC_NOATTR);
__LIBC_FUNC(int, umount2, (const char *special_file, int flags), __LIBC_NOATTR);

#endif  /* _SYS_MOUNT_H */
