/*
 * c_stdio_file_simple_unbuffered.c: a simple, partial, unbuffered stdio implementation for files (not stdin, stdout or stderr)
 * by pts@fazekas.h at Fri May 19 16:23:16 CEST 2023
 *
 * Features:
 *
 * * Open files are flushed at mini_exit(...) time, including when returning
 *   from main(...).
 *
 * Limitations:
 *
 * * File I/O is unbuffered, goes directly to syscalls.
 *   See also c_stdio_file_simple_buffered.nasm for a buffered variant.
 * * Only these functions are implemented: fopen, fclose, fread, fwrite,
 *   fseek, ftell, fgetc.
 * * It's not possible to use it with printf, fprintf, vfprintf etc.
 * * mini_fseek(...) doesn't work (can do anything) if the file size is
 *   larger than 4 GiB - 4 KiB. That's because the return value of lseek(2)
 *   (without errno) doesn't fit to 32 bits.
 * * mini_ftell(...) returns garbage if the file size is larger than 4 GiB -
 *   4 KiB.
 * * Only full buffering (_IOFBF) is implemented.
 * * Only fopen modes "rb" (same as "r", for reading) and "wb" (same as "w",
 *   for writing) are implemented. Thus the file can be opened only in one
 *   direction at a time.
 * * There is no error indicator bit, subsequent read(2) and write(2) will
 *   be attempted even after an I/O error.
 * * Only up to a compile-time fixed number of files (default:
 *   FILE_CAPACITY == 2) can be open at the same time.
 * * Buffer size is fixed at compile time (default: BUF_SIZE == 0x1000).
 * * Currently functions are not split to multiple .c files, thus unneeded
 *   functions will also be linked.
 * * The behavior is undefined if `size * nmemb' is overflows (i.e. at
 *   least 2 ** 32 == 4 GiB).
 */

#include "stdio_file_simple.h"  /* This is the public API. */

#define FILE_CAPACITY 2  /* TODO(pts): Make this configurable: CONFIG_FILE_CAPACTIY etc. */

#define NULL ((void*)0)

/* _FILE.dir constant. */
#define FD_CLOSED 0
#define FD_READ 1
#define FD_WRITE 2

struct _SFS_FILE {
  char dire;  /* Direction. One of FD_... . FD_CLOSED by default. */
  char gap1, gap2, gap3;
  int fd;
};

static FILE global_files[FILE_CAPACITY];

/* Underlying syscall API. */
#define O_RDONLY 0
#define O_WRONLY 1
#define O_RDWR 2
#define O_CREAT 0100  /* Linux-specific. */
#define O_EXCL  0200  /* Linux-specific. */
#define O_TRUNC 01000  /* Linux-specific. */
typedef unsigned mode_t;
extern int mini_open(const char *pathname, int flags, mode_t mode);
extern int mini_close(int fd);
extern ssize_t mini_read(int fd, void *buf, size_t count);
extern ssize_t mini_write(int fd, const void *buf, size_t count);
extern off_t mini_lseek(int fd, off_t offset, int whence);

FILE *mini_fopen(const char *pathname, const char *mode) {
  FILE *filep;
  int fd;
  char is_write = mode[0] == 'w';
  for (filep = global_files; filep != global_files + sizeof(global_files) / sizeof(global_files[0]); ++filep) {
    if (filep->dire == FD_CLOSED) {
      fd = mini_open(pathname, is_write ? O_WRONLY | O_TRUNC | O_CREAT : O_RDONLY, 0666);
      if (fd < 0) return NULL;  /* open(2) has failed. */
      filep->dire = 1 + is_write;
      filep->fd = fd;
      return filep;
    }
  }
  return NULL;  /* No free slots in global_files. */
}

int fflush(FILE *filep) {
  (void)filep;
  return 0;  /* Always succeeds. */
}

int mini_fclose(FILE *filep) {
  if (filep->dire == FD_CLOSED) return EOF;
  mini_close(filep->fd);
  filep->dire = FD_CLOSED;
  /*filep->fd = 0;*/  /* Unnecessary work. */
  return 0;
}

size_t mini_fread(void *ptr, size_t size, size_t nmemb, FILE *filep) {
  size_t bc = size * nmemb;  /* Byte count. We don't care about overflow. */
  ssize_t got;
  char *p = (char*)ptr;
  if (filep->dire != FD_READ || bc == 0) return 0;
  while ((size_t)(got = mini_read(filep->fd, p, bc)) + 1U > 1U) {  /* Read at least 1 byte. */
    p += got;
    bc -= got;
  }
  return (size_t)(p - (char*)ptr) / size;
}

size_t mini_fwrite(const void *ptr, size_t size, size_t nmemb, FILE *filep) {
  size_t bc = size * nmemb;  /* Byte count. We don't care about overflow. */
  ssize_t got;
  const char *p = (char*)ptr;
  if (filep->dire != FD_WRITE || bc == 0) return 0;
  while ((size_t)(got = mini_write(filep->fd, p, bc)) + 1U > 1U) {  /* Written at least 1 byte. */
    p += got;
    bc -= got;
  }
  return (size_t)(p - (const char*)ptr) / size;
}

int mini_fseek(FILE *filep, off_t offset, int whence) {
  off_t got;
  if (filep->dire != FD_READ && filep->dire != FD_WRITE) return EOF;
  got = mini_lseek(filep->fd, offset, whence);
  return (got == (off_t)-1) ? EOF : 0;
}

off_t mini_ftell(FILE *filep) {
  if (filep->dire != FD_READ && filep->dire != FD_WRITE) return 0;
  return mini_lseek(filep->fd, 0, SEEK_CUR);  /* EOF and (off_t)-1 are the same. */
}

int mini_fgetc(FILE *filep) {
  unsigned char uc;
  if (filep->dire != FD_READ) return 0;
  if ((size_t)mini_read(filep->fd, &uc, 1) != 1U) return EOF;
  return uc;
}

/* Called from mini_exit(...). */
void mini___M_flushall(void) {
  /* There is nothing to flush. */
}

/* !! Retry reads and writes to fill the buffer. */
