/*
 * c_stdio_file_simple_buffered.c: a simple, partial, buffered stdio implementation for files (not stdin, stdout or stderr)
 * by pts@fazekas.h at Fri May 19 16:23:16 CEST 2023
 *
 * Features:
 *
 * * Open files are flushed at mini_exit(...) time, including when returning
 *   from main(...).
 * * File I/O is buffered.
 *
 *
 * Limitations:
 *
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
#define BUF_SIZE 0x1000  /* glibc has 0x2000, uClibc has BUFSIZ == 0x1000. */

#define NULL ((void*)0)

/* _FILE.dire (direction) constant. */
#define FD_CLOSED 0
#define FD_READ 1
#define FD_WRITE 2

struct _SFS_FILE {
  char dire;  /* Direction. One of FD_... . FD_CLOSED by default. */
  char gap1, gap2, gap3;
  int fd;
  /* For reading: buf <= buf_ptr <= buf_last <= buf + BUF_SIZE. */
  /* For writing: buf <= buf_ptr <= buf + BUF_SIZE. */
  char *buf_ptr;  /* For reading: points to the first unreturned byte in buf. For writing: points to the first available byte in buf. */
  char *buf_last;  /* For reading: points after the last byte read from file. */
  off_t buf_off;  /* Points to the file offset of buf. */
  char buf[BUF_SIZE];
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

static void discard_buf(FILE *filep) {
  filep->buf_ptr = filep->buf_last = filep->buf;
}

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
      filep->buf_off = 0;
      discard_buf(filep);
      return filep;
    }
  }
#endif
  return NULL;  /* No free slots in global_files. */
}

int mini_fflush(FILE *filep) {
  const char *p;
  ssize_t got;
  if (filep->dire != FD_WRITE) return EOF;
  p = filep->buf;
  while (p != filep->buf_ptr) {
    if ((got = mini_write(filep->fd, p, filep->buf_ptr - p)) + 1U <= 1U) {
      got = EOF;
      goto done; /* Silently ignore rest of the buffer not written. */
    }
    p += got;
  }
  got = 0;  /* Success. */
 done:
  filep->buf_off += p - filep->buf;
  discard_buf(filep);
  return got;
}

int mini_fclose(FILE *filep) {
  int got;
  if (filep->dire == FD_CLOSED) return EOF;
  got = (filep->dire == FD_READ) ? 0 : mini_fflush(filep);
  mini_close(filep->fd);
  filep->dire = FD_CLOSED;
  /*filep->fd = 0;*/  /* Unnecessary work. */
  return got;
}

size_t mini_fread(void *ptr, size_t size, size_t nmemb, FILE *filep) {
  size_t bc = size * nmemb;  /* Byte count. We don't care about overflow. */
  ssize_t got;
  char *p = (char*)ptr;
  if (filep->dire != FD_READ || bc == 0) return 0;
  for (;;) {
    while (bc != 0 && filep->buf_ptr != filep->buf_last) {  /* TODO(pts): Is it faster or smaller with memcpy(3)? */
      *p++ = *filep->buf_ptr++;
      --bc;
    }
    if (bc == 0) break;
    filep->buf_off += filep->buf_last - filep->buf;
    discard_buf(filep);
    if ((size_t)(got = mini_read(filep->fd, filep->buf, sizeof(filep->buf))) + 1U <= 1U) break;
    filep->buf_last += got;
  }
  return (size_t)(p - (char*)ptr) / size;
}

size_t mini_fwrite(const void *ptr, size_t size, size_t nmemb, FILE *filep) {
  size_t bc = size * nmemb;  /* Byte count. We don't care about overflow. */
  ssize_t got;
  const char *p = (char*)ptr;
  if (filep->dire != FD_WRITE || bc == 0) return 0;
  if (filep->buf_ptr == filep->buf && bc >= sizeof(filep->buf)) {
    /* Buffer is empty and too small. As a speed optimization, write directly to filep->fd. */
  } else {
    while (filep->buf_ptr != filep->buf + sizeof(filep->buf)) {  /* TODO(pts): Is it faster or smaller with memcpy(3)? */
      *filep->buf_ptr++ = *p++;
      if (--bc == 0) goto done;
    }
  }
  if (!mini_fflush(filep)) {  /* Successfully flushed. */
    while ((size_t)(got = mini_write(filep->fd, p, bc)) + 1U > 1U) {  /* Written at least 1 byte. */
      p += got;
      bc -= got;
      filep->buf_off += got;
    }
  }
 done:
  return (size_t)(p - (const char*)ptr) / size;
}

int mini_fseek(FILE *filep, off_t offset, int whence) {
  off_t got;
  if (filep->dire == FD_READ) {
    if (whence == SEEK_CUR) {
      filep->buf_off += filep->buf_ptr - filep->buf;
      whence = SEEK_SET;
      offset += filep->buf_off;
    }
    discard_buf(filep);  /* The caller expects us to discard the buffer, even if mini_lseek(...) below fails. */
  } else if (filep->dire == FD_WRITE) {
    if (mini_fflush(filep)) return EOF;
  } else {
    return EOF;
  }
  got = mini_lseek(filep->fd, offset, whence);
  if (got == (off_t)-1) return EOF;
  filep->buf_off = got;
  return 0;
}

off_t mini_ftell(FILE *filep) {
  if (filep->dire != FD_READ && filep->dire != FD_WRITE) return 0;
  return filep->buf_off + (filep->buf_ptr - filep->buf);
}

int mini_fgetc(FILE *filep) {
  unsigned char uc;
  /*if (filep->dire != FD_READ) return 0;*/  /* No need to check, mini_fread(...) below checks it. */
  if (filep->buf_ptr != filep->buf_last) return (unsigned char)*filep->buf_ptr++;
  return mini_fread(&uc, 1, 1, filep) ? uc : EOF;
}

/* Called from mini_exit(...). */
void mini___M_flushall(void) {
  FILE *filep;
  for (filep = global_files; filep != global_files + sizeof(global_files) / sizeof(global_files[0]); ++filep) {
    mini_fflush(filep);
  }
}
