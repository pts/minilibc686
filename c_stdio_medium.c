/*
 * c_stdio_medium.c: a medium-partial, buffered stdio implementation for files and standard streams (stdin, stdout or stderr)
 * by pts@fazekas.h at Mon May 22 15:20:04 CEST 2023
 *
 * Features:
 *
 * * Open files are flushed at mini_exit(...) time, including when returning
 *   from main(...).
 * * File I/O is buffered.
 * * !! stdout line buffering is autodetected at program startup.
 *
 * Limitations:
 *
 * * Only these functions are implemented: fopen, fclose, fread, fwrite,
 *   fseek, ftell, fgetc.
 * * !! Implement stdin, stdout and stderr.
 * * !! TODO(pts): Implement printf, fprintf, vfprintf.
 * * !! TODO(pts): Implement sprintf, vsprintf snprintf, vsnprintf.
 * * !! mini_fseek(...) doesn't work (can do anything) if the file size is
 *   larger than 4 GiB - 4 KiB. That's because the return value of lseek(2)
 *   (without errno) doesn't fit to 32 bits.
 * * !! mini_ftell(...) returns garbage if the file size is larger than 4 GiB -
 *   4 KiB.
 * * Only full buffering (_IOFBF) is implemented for files opened with
 *   fopen(...). For stdin and stdout, it's linue buffering (_IOLBF) if it
 *   is a TTY (terminal), otherwise it's full buffering.
 * * fread(...) and fwrite(...) always do full buffering. To get line buffering,
 *   use fprintf(...), vfprintf(...), puts(...), fputs(...), putchar(...),
 *   putc(...), getchar(...), getc(...), fgetc(...) or fgets(...).
 * * !! Implement puts.
 * * !! Implement fgets.
 * * !! Implement getchar.
 * * !! Implement putchar.
 * * !! Implement getc as an alias for fgetc, also at the C header level.
 * * !! Implement gets as an alias for fgets, also at the C header level.
 * * !! Implement line buffering for stdin.
 * * !! Implement line buffering for stdout.
 * * Only fopen modes "rb" (same as "r", for reading) and "wb" (same as "w",
 *   for writing) are implemented. Thus the file can be opened only in one
 *   direction at a time.
 * * !! There is no error indicator bit, subsequent read(2) and write(2) will
 *   be attempted even after an I/O error.
 * * Only up to a compile-time fixed number of files (default:
 *   FILE_CAPACITY == 2) can be open at the same time.
 * * Buffer size is fixed at compile time (default: BUF_SIZE == 0x1000).
 *   stdin, stdout and stderr have a default, smaller buffer size.
 * * !! Currently functions are not split to multiple .c files, thus unneeded
 *   functions will also be linked.
 * * The behavior is undefined if `size * nmemb' is overflows (i.e. at
 *   least 2 ** 32 == 4 GiB).
 */

/* See the public API in <stdio.h>. */

#define EOF -1  /* Indicates end-of-file (EOF) or error. */

/* fseek(..., ..., whence) constants. */
#define SEEK_SET 0
#define SEEK_CUR 1
#define SEEK_END 2

typedef unsigned size_t;
typedef int ssize_t;
typedef long off_t;  /* Still 32 bits only. */

typedef struct _SMS_FILE FILE;  /* Different from _FILE. */

#define FILE_CAPACITY 2  /* TODO(pts): Make this configurable: CONFIG_FILE_CAPACTIY etc. */
#define BUF_SIZE 0x1000  /* glibc has 0x2000, uClibc has BUFSIZ == 0x1000. */

#define NULL ((void*)0)

/* _FILE.dire (direction) constant. */
#define FD_CLOSED 0
#define FD_READ 1
#define FD_WRITE 2

#define _STDIO_SUPPORTS_EMPTY_BUFFERS 0
#define _STDIO_SUPPORTS_LINE_BUFFERING 0

struct _SMS_FILE {
  char dire;  /* Direction. One of FD_... . FD_CLOSED by default. */
  char gap1, gap2, gap3;
  int fd;
  /* Invariant: buf_start <= buf_ptr <= buf_last <= buf_end. */
  char *buf_ptr;  /* For reading: points to the first unreturned byte in buf. For writing: points to the first available byte in buf. */
  char *buf_end;  /* Points to the end of the buffer (i.e. byte after the buffer). */
  char *buf_start;  /* Points to the start of the buffer. */
  char *buf_last;  /* For reading: points after the last byte read from file. */
  off_t buf_off;  /* Points to the file offset of buf. */
};

static FILE global_files[FILE_CAPACITY];
static char global_file_bufs[FILE_CAPACITY * BUF_SIZE];

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
  filep->buf_ptr = filep->buf_last = filep->buf_start;
}

FILE *mini_fopen(const char *pathname, const char *mode) {
  FILE *filep;
  char *buf = global_file_bufs;
  int fd;
  char is_write;
#if FILE_CAPACITY > 0
  is_write = mode[0] == 'w';
  for (filep = global_files; filep != global_files + sizeof(global_files) / sizeof(global_files[0]); ++filep, buf += BUF_SIZE) {
    if (filep->dire == FD_CLOSED) {
      fd = mini_open(pathname, is_write ? O_WRONLY | O_TRUNC | O_CREAT : O_RDONLY, 0666);
      if (fd < 0) return NULL;  /* open(2) has failed. */
      filep->dire = 1 + is_write;
      filep->fd = fd;
      filep->buf_off = 0;
      filep->buf_start = buf;
      filep->buf_end = buf + BUF_SIZE;
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
  p = filep->buf_start;
  while (p != filep->buf_ptr) {
    if ((got = mini_write(filep->fd, p, filep->buf_ptr - p)) + 1U <= 1U) {
      got = EOF;
      goto done; /* Silently ignore rest of the buffer not written. */
    }
    p += got;
  }
  got = 0;  /* Success. */
 done:
  filep->buf_off += p - filep->buf_start;
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
    filep->buf_off += filep->buf_last - filep->buf_start;
    discard_buf(filep);
    if ((size_t)(got = mini_read(filep->fd, filep->buf_start, filep->buf_end - filep->buf_start)) + 1U <= 1U) break;
    filep->buf_last += got;
  }
  return (size_t)(p - (char*)ptr) / size;
}

size_t mini_fwrite(const void *ptr, size_t size, size_t nmemb, FILE *filep) {
  size_t bc = size * nmemb;  /* Byte count. We don't care about overflow. */
  ssize_t got;
  const char *p = (char*)ptr;
  if (filep->dire != FD_WRITE || bc == 0) return 0;
  if (filep->buf_ptr == filep->buf_start && bc >= (size_t)(filep->buf_end - filep->buf_start)) {
    /* Buffer is empty and too small. As a speed optimization, write directly to filep->fd. */
  } else {
    while (filep->buf_ptr != filep->buf_end) {  /* TODO(pts): Is it faster or smaller with memcpy(3)? */
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
      filep->buf_off += filep->buf_ptr - filep->buf_start;
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
  return filep->buf_off + (filep->buf_ptr - filep->buf_start);
}

int mini_fgetc(FILE *filep) {
  unsigned char uc;
  /*if (filep->dire != FD_READ) return EOF;*/  /* No need to check, mini_fread(...) below checks it. */
  if (filep->buf_ptr != filep->buf_last) return (unsigned char)*filep->buf_ptr++;
  return mini_fread(&uc, 1, 1, filep) ? uc : EOF;
}

int mini_fputc(int c, FILE *filep) {
  const unsigned char uc = c;
  if (filep->dire != FD_WRITE) return EOF;  /* !! Add sentinel, and make mini_fflush(...) check it. No need to check, mini_fflush(...) below checks it. */
  while (filep->buf_ptr == filep->buf_end) {
    if (mini_fflush(filep)) return EOF;  /* Also returns EOF if filep->dire != FD_WRITE. Good, because we don't want to write. */
    if (_STDIO_SUPPORTS_EMPTY_BUFFERS && filep->buf_ptr == filep->buf_end) {
      return mini_fwrite(&uc, 1, 1, filep) ? uc : EOF;
    }
  }
  *filep->buf_ptr++ = uc;
  if (_STDIO_SUPPORTS_LINE_BUFFERING && uc == '\n') mini_fflush(filep);
  return uc;
}

/* Called from mini_exit(...). */
void mini___M_flushall(void) {
#if FILE_CAPACITY <= 0
#else
#if FILE_CAPACITY == 1
  mini_fflush(global_files);
#else
#if FILE_CAPACITY == 2  /* Size optimization. */
  mini_fflush(global_files);
  mini_fflush(global_files + 1);
#else
  FILE *filep;
  for (filep = global_files; filep != global_files + sizeof(global_files) / sizeof(global_files[0]); ++filep) {
    mini_fflush(filep);
  }
#endif
#endif
#endif
}
