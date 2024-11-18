#define _LARGEFILE64_SOURCE
#include <stdio.h>
#include <sys/stat.h>

typedef char assert_sizeof_stat[sizeof(struct stat64) > sizeof(struct stat)];

#if defined(__GLIBC__) && !defined(__UCLIBC__)
#  define st_mtimensec st_mtim.tv_nsec
#endif
#ifdef __MINILIBC686__
#  define st_mtimensec st_mtime_nsec
#endif
#ifdef __diet__
#  define st_mtimensec st_mtime_nsec  /* It doesn't work yet for i386! */
#endif

int main(int argc, char **argv) {
  (void)argc; (void)argv;
  {
    struct stat st;
    if (stat("..", &st) != 0) return 2;
    /* glibc tends to cut st.st_dev to 16 bits, even in `struct stat64'. */
    fprintf(stdout, "st_dev=0x%llx st_ino=%lld st_mode=%lld st_nlink=%lld st_uid=%lld st_gid=%lld st_rdev=%lld st_size=%lld st_blksize=%lld st_blocks=%lld st_atime=%lld st_mtime=%lld st_mtimensec=%lld st_ctime=%lld\n",
            (long long)st.st_dev, (long long)st.st_ino, (long long)st.st_mode, (long long)st.st_nlink, (long long)st.st_uid, (long long)st.st_gid, (long long)st.st_rdev, (long long)st.st_size, (long long)st.st_blksize, (long long)st.st_blocks, (long long)st.st_atime, (long long)st.st_mtime, (long long)st.st_mtimensec, (long long)st.st_ctime);
  }
  {
    struct stat64 st;
    if (stat64("..", &st) != 0) return 2;
    fprintf(stdout, "st_dev=0x%llx st_ino=%lld st_mode=%lld st_nlink=%lld st_uid=%lld st_gid=%lld st_rdev=%lld st_size=%lld st_blksize=%lld st_blocks=%lld st_atime=%lld st_mtime=%lld st_mtimensec=%lld st_ctime=%lld\n",
            (long long)st.st_dev, (long long)st.st_ino, (long long)st.st_mode, (long long)st.st_nlink, (long long)st.st_uid, (long long)st.st_gid, (long long)st.st_rdev, (long long)st.st_size, (long long)st.st_blksize, (long long)st.st_blocks, (long long)st.st_atime, (long long)st.st_mtime, (long long)st.st_mtimensec, (long long)st.st_ctime);
  }
  return 0;
}
