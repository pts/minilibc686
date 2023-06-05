#ifndef _SYS_MMAN_H
#define _SYS_MMAN_H
#include <_preincl.h>

#include <sys/types.h>

#define MREMAP_MAYMOVE 1UL
#define MREMAP_FIXED 2UL
#define PROT_READ 0x1
#define PROT_WRITE 0x2
#define PROT_EXEC 0x4
#define PROT_SEM 0x8
#define PROT_NONE 0x0
#define PROT_GROWSDOWN 0x01000000
#define PROT_GROWSUP 0x02000000
#define MAP_SHARED 0x01
#define MAP_PRIVATE 0x02
#define MAP_TYPE 0xf
#define MADV_REMOVE 9
#define MADV_DONTFORK 10
#define MADV_DOFORK 11
#define MADV_MERGEABLE 12
#define MADV_UNMERGEABLE 13
#define MADV_HUGEPAGE 14
#define MADV_NOHUGEPAGE 15
#define MADV_DONTDUMP 16
#define MADV_DODUMP 17
#define MADV_HWPOISON 100
#define MADV_SOFT_OFFLINE 101
#define MLOCK_ONFAULT 1
#define MAP_FIXED 0x10
#define MAP_ANONYMOUS 0x20
#define MAP_GROWSDOWN 0x0100
#define MAP_DENYWRITE 0x0800
#define MAP_EXECUTABLE 0x1000
#define MAP_LOCKED 0x2000
#define MAP_NORESERVE 0x4000
#define MAP_POPULATE 0x8000
#define MAP_NONBLOCK 0x10000
#define MAP_STACK 0x20000
#define MAP_HUGETLB 0x40000
#define MS_ASYNC 1
#define MS_INVALIDATE 2
#define MS_SYNC 4
#define MCL_CURRENT 1
#define MCL_FUTURE 2
#define MCL_ONFAULT 4
#define MADV_NORMAL 0x0
#define MADV_RANDOM 0x1
#define MADV_SEQUENTIAL 0x2
#define MADV_WILLNEED 0x3
#define MADV_DONTNEED 0x4
#define MAP_ANON MAP_ANONYMOUS
#define MAP_FILE 0
#define MAP_FAILED ((void *) -1)

__LIBC_FUNC(void *, mmap, (void *addr, size_t length, int prot, int flags, int fd, off_t offset), __LIBC_NOATTR);  /* Not a syscall, `offset' needs processing. */
__LIBC_FUNC(void *, sys_mmap2, (void *addr, size_t length, int prot, int flags, int fd, off_t offset), __LIBC_NOATTR);
__LIBC_FUNC(void *, mremap, (void *old_address, size_t old_size, size_t new_size, int flags, ... /* void *new_address */), __LIBC_NOATTR);
__LIBC_FUNC(int, munmap, (void *addr, size_t length), __LIBC_NOATTR);

#endif  /* _SYS_MMAN_H */
