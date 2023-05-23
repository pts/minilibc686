/*
 * c_stdio_medium.c: a medium-partial, buffered stdio implementation for files and standard streams (stdin, stdout or stderr)
 * by pts@fazekas.h at Mon May 22 15:20:04 CEST 2023
 *
 * Features:
 *
 * * Open files are flushed at mini_exit(...) time, including when returning
 *   from main(...).
 * * File I/O is buffered.
 * * stdin and stdout line buffering is autodetected at program startup.
 *
 * Limitations:
 *
 * * Only these functions are implemented: fopen, fclose, fread, fwrite,
 *   fseek, ftell, fileno, fgetc, getc (defined in <stdio.h>), fputc, putc
 *   (defined in <stdio.h>), printf, fprintf, vfprintf.
 * * !! TODO(pts): Implement sprintf, vsprintf snprintf, vsnprintf.
 * * !! mini_fseek(...) doesn't work (can do anything) if the file size is
 *   larger than 4 GiB - 4 KiB. That's because the return value of lseek(2)
 *   (without errno) doesn't fit to 32 bits.
 * * !! mini_ftell(...) returns garbage if the file size is larger than 4 GiB -
 *   4 KiB.
 * * Only full buffering (_IOFBF) is implemented for files opened with
 *   fopen(...). For stdin and stdout, it's linue buffering (_IOLBF) if it
 *   is a TTY (terminal), otherwise it's full buffering.
 * * !! Implement puts.
 * * !! Implement fgets.
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
#define FD_WRITE 4  /* Must be even, so that `^= 1' can toggle between FD_WRITE and FD_WRITE_RELAXED. */
#define FD_WRITE_RELAXED (FD_WRITE+1)  /* Like FD_WRITE, but the buffer size will be set to 0 by mini___M_writebuf_unrelax(...). */
#define FD_READ_LINEBUF (FD_READ+2)  /* Line buffered, for reading. */
#define FD_WRITE_LINEBUF (FD_WRITE+2)  /* Line buffered, for writing. */

#define IS_FD_ANY_READ(dire) ((unsigned char)((dire) - FD_READ) < (unsigned char)(FD_WRITE - FD_READ + 0U))
#define IS_FD_ANY_WRITE(dire) ((unsigned char)(dire) >= (unsigned char)FD_WRITE)

#define _STDIO_SUPPORTS_EMPTY_BUFFERS 1
#define _STDIO_SUPPORTS_LINE_BUFFERING 1  /* If changed, also update include/stdio.h. */

struct _SMS_FILE {  /* Layout must match stdio_medium_*.nasm. */
  /* The first two pointers must be buf_write_ptr and buf_end, for the putc(c, filep) macro to work. */
  char *buf_write_ptr;  /* For writing: points to the first available byte in buf. */
  char *buf_end;  /* Points to the end of the buffer (i.e. byte after the buffer). */
  /* The next two pointers must be buf_write_ptr and buf_end, for the getc(filep) macro to work. */
  char *buf_read_ptr;  /* For reading: points to the first unreturned byte in buf. */
  char *buf_last;  /* For reading: points after the last byte read from file. */
  /* fd must come right after the 4 pointers above, for the fileno(filep) macro to work. */
  int fd;
  /* dire must come right after fd above, for mini___M_init_isatty(...) to work. */
  unsigned char dire;  /* Direction. One of FD_... . FD_CLOSED by default. */
  char padding[sizeof(int) - 1];
  /* Invariant: buf_start <= buf_write_ptr <= buf_end <= buf_capacity_end (unless FD_WRITE_RELAXED). */
  /* Invariant: buf_start <= buf_read_ptr <= buf_last <= buf_end. <= buf_capacity. */
  char *buf_start;  /* Points to the start of the buffer. */
  char *buf_capacity_end;  /* Indicates the end of the buffer data available (unless FD_WRITE_RELAXED). The region buf_end...buf_capacity_end is currently disabled. */
  off_t buf_off;  /* Points to the file offset of buf. */
};

extern FILE mini___M_global_files[], mini___M_global_files_end[];
extern char mini___M_global_file_bufs[];

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
  filep->buf_read_ptr = filep->buf_write_ptr = filep->buf_last = filep->buf_start;
  if (IS_FD_ANY_READ(filep->dire)) filep->buf_write_ptr = filep->buf_end;  /* Sentinel. */
}

/* Always calls discard_buf(...). */
int mini_fflush(FILE *filep) {
  const char *p;
  ssize_t got;
  if (!IS_FD_ANY_WRITE(filep->dire)) return EOF;
  p = filep->buf_start;
  while (p != filep->buf_write_ptr) {
    if ((got = mini_write(filep->fd, p, filep->buf_write_ptr - p)) + 1U <= 1U) {
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

int mini_fputc(int c, FILE *filep) {
  const unsigned char uc = c;
  /*if (!IS_FD_ANY_WRITE(filep->dire)) return EOF;*/  /* No need to check, the while condition is true, and mini_fflush(...) below checks it. */
  if (filep->buf_write_ptr == filep->buf_end) {
    if (mini_fflush(filep)) return EOF;  /* Also returns EOF if !IS_FD_ANY_WRITE(filep->dire). Good, because we don't want to write. */
    if (_STDIO_SUPPORTS_EMPTY_BUFFERS && filep->buf_write_ptr == filep->buf_end) {
      /* return mini_fwrite(&uc, 1, 1, filep) ? uc : EOF; */
      if (mini_write(filep->fd, &uc, 1) != 1) return EOF;
      ++filep->buf_off;
    }
  }
  *filep->buf_write_ptr++ = uc;
  if (uc == '\n' && filep->dire == FD_WRITE_LINEBUF) mini_fflush(filep);
  return uc;
}

__attribute__((__regparm__(2))) int mini___M_fputc_RP2(int c, FILE *filep) {  /* A trampoline for shorter inlining of putc(...) below. */
  return mini_fputc(c, filep);
}

#ifndef CONFIG_STDIO_MEDIUM_PRINTF_ONLY  /* Only the functionality needed by mini_vfprintf(...). */
size_t mini_fwrite(const void *ptr, size_t size, size_t nmemb, FILE *filep) {
  size_t bc = size * nmemb;  /* Byte count. We don't care about overflow. */
  ssize_t got;
  const char *p = (char*)ptr;
  const char *q;
  if (!IS_FD_ANY_WRITE(filep->dire) || bc == 0) return 0;
  if (filep->buf_end == filep->buf_start) {
    goto write_remaining;
  } else if (filep->dire == FD_WRITE_LINEBUF) {
    for (q = p + bc; q != p && q[-1] != '\n'; --q) {}  /* Find the last '\n'. */
    do {
      /* !! TODO(pts): Flush the buffer if full (but not overfull)? What does glibc do? */
      if (filep->buf_write_ptr == filep->buf_end) {
        if (mini_fflush(filep)) goto done;  /* Error flushing, so stop. */
      }
      *filep->buf_write_ptr++ = *p++;
      if (p == q) {  /* Last newline ('\n') found. */
        if (mini_fflush(filep)) goto done;  /* Error flushing, so stop. */
      }
    } while (--bc != 0);
    goto done;
  } else if (filep->buf_write_ptr == filep->buf_start && bc >= (size_t)(filep->buf_end - filep->buf_start)) {
    /* Buffer is empty and too small. As a speed optimization, write directly to filep->fd. */
  } else {
    /* !! TODO(pts): Flush the buffer if full (but not overfull)? What does glibc do? */
    while (filep->buf_write_ptr != filep->buf_end) {  /* !! TODO(pts): Is it faster or smaller with memcpy(3)? */
      *filep->buf_write_ptr++ = *p++;
      if (--bc == 0) goto done;
    }
  }
  if (!mini_fflush(filep)) {  /* Successfully flushed. */
   write_remaining:
    while ((size_t)(got = mini_write(filep->fd, p, bc)) + 1U > 1U) {  /* Written at least 1 byte. */
      p += got;
      filep->buf_off += got;
      if ((bc -= got) == 0) break;
    }
  }
 done:
  return (size_t)(p - (const char*)ptr) / size;
}

#if 0
/* With smart linking, we could use this if mini_write(...) is also linked. */
int mini_fputc_calling_fwrite(int c, FILE *filep) {
  const unsigned char uc = c;
  /*if (!IS_FD_ANY_WRITE(filep->dire)) return EOF;*/  /* No need to check, the while condition is true, and mini_fflush(...) below checks it. */
  while (filep->buf_write_ptr == filep->buf_end) {
    if (mini_fflush(filep)) return EOF;  /* Also returns EOF if !IS_FD_ANY_WRITE(filep->dire). Good, because we don't want to write. */
    if (_STDIO_SUPPORTS_EMPTY_BUFFERS && filep->buf_write_ptr == filep->buf_end) {
      return mini_fwrite(&uc, 1, 1, filep) ? uc : EOF;
    }
  }
  *filep->buf_write_ptr++ = uc;
  if (uc == '\n' && filep->dire == FD_WRITE_LINEBUF) mini_fflush(filep);
  return uc;
}
#endif

extern void mini___M_flushall(void);
__extension__ void *mini___M_flushall_ptr = (void*)mini___M_flushall;  /* Force `extern' declaration, for mini_fopen(...). In .nasm source we won't need this hack. */

FILE *mini_fopen(const char *pathname, const char *mode) {
  FILE *filep;
  char *buf = mini___M_global_file_bufs;
  int fd;
  char is_write;
  is_write = mode[0] == 'w';  /* !! Add 'a'. */
  for (filep = mini___M_global_files; filep != mini___M_global_files_end; ++filep, buf += BUF_SIZE) {
    if (filep->dire == FD_CLOSED) {
      fd = mini_open(pathname, is_write ? O_WRONLY | O_TRUNC | O_CREAT : O_RDONLY, 0666);
      if (fd < 0) return NULL;  /* open(2) has failed. */
      filep->dire = is_write ? FD_WRITE : FD_READ;
      filep->fd = fd;
      filep->buf_off = 0;
      filep->buf_start = buf;
      filep->buf_capacity_end = filep->buf_end = buf + BUF_SIZE;
      discard_buf(filep);
      return filep;
    }
  }
  return NULL;  /* No free slots in global_files. */
}

int mini_fclose(FILE *filep) {
  int got;
  if (filep->dire == FD_CLOSED) return EOF;
  got = (IS_FD_ANY_READ(filep->dire)) ? 0 : mini_fflush(filep);
  mini_close(filep->fd);
  filep->dire = FD_CLOSED;
  filep->fd = EOF;  /* Sentinel for future calls to fileno(filep) etc. */
  return got;
}

#if defined(__GNUC__) || defined(__TINYC__)  /* Copied from <stdio.h>. */
static __inline__ __attribute__((__always_inline__)) int fileno(FILE *filep) { return *(int*)(void*)(((char**)(filep))+4); }
#endif

int mini_fileno(FILE *filep) {
  return filep->fd;  /* EOF if closed. */
}

size_t mini_fread(void *ptr, size_t size, size_t nmemb, FILE *filep) {
  size_t bc = size * nmemb;  /* Byte count. We don't care about overflow. */
  ssize_t got;
  char *p = (char*)ptr;
  char c;
  if (!IS_FD_ANY_READ(filep->dire) || bc == 0) return 0;
  for (;;) {
    if (filep->dire == FD_READ_LINEBUF) {
      while (bc != 0 && filep->buf_read_ptr != filep->buf_last) {
        *p++ = c = *filep->buf_read_ptr++;
        --bc;
        if (c == '\n') goto done;  /* !! Is this consistent with glibc and uClibc? */
      }
    } else {
      while (bc != 0 && filep->buf_read_ptr != filep->buf_last) {  /* TODO(pts): Is it faster or smaller with memcpy(3)? */
        *p++ = *filep->buf_read_ptr++;
        --bc;
      }
    }
    if (bc == 0) break;
    filep->buf_off += filep->buf_last - filep->buf_start;
    discard_buf(filep);
    if ((size_t)(got = mini_read(filep->fd, filep->buf_start, filep->buf_end - filep->buf_start)) + 1U <= 1U) break;
    filep->buf_last += got;
  }
 done:
  return (size_t)(p - (char*)ptr) / size;
}

int mini_fseek(FILE *filep, off_t offset, int whence) {
  off_t got;
  if (IS_FD_ANY_READ(filep->dire)) {
    if (whence == SEEK_CUR) {
      filep->buf_off += filep->buf_read_ptr - filep->buf_start;
      whence = SEEK_SET;
      offset += filep->buf_off;
    }
    discard_buf(filep);  /* The caller expects us to discard the buffer, even if mini_lseek(...) below fails. */
  } else if (IS_FD_ANY_WRITE(filep->dire)) {
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
  const char *p;
  if (IS_FD_ANY_READ(filep->dire)) {
    p = filep->buf_read_ptr;
  } else if (IS_FD_ANY_WRITE(filep->dire)) {
    p = filep->buf_write_ptr;
  } else {
    return EOF;
  }
  return filep->buf_off + (p - filep->buf_start);
}

__attribute__((__regparm__(1))) int mini___M_fgetc_fallback_RP1(FILE *filep) {
  unsigned char uc;
  return mini_fread(&uc, 1, 1, filep) ? uc : EOF;
}

#if defined(__GNUC__) || defined(__TINYC__)  /* Copied from <stdio.h>. */
/* If the there are bytes to read from the buffer (filep->buf_read_ptr != filep->buf_last), get and return a byte, otherwise call mini___M_fgetc_fallback_RP1(...). */
static __inline__ __attribute__((__always_inline__)) int getc(FILE *filep) { return (((char**)filep)[2]/*->buf_read_ptr*/ == ((char**)filep)[3]/*->buf_last*/) ? mini___M_fgetc_fallback_RP1(filep) : (unsigned char)*((char**)filep)[2]/*->buf_read_ptr*/++; }
#endif

int mini_fgetc(FILE *filep) {
  unsigned char uc;
  /*if (!IS_FD_ANY_READ(filep->dire)) return EOF;*/  /* No need to check, mini_fread(...) below checks it. */
  if (filep->buf_read_ptr != filep->buf_last) return (unsigned char)*filep->buf_read_ptr++;
  return mini_fread(&uc, 1, 1, filep) ? uc : EOF;
}

#if defined(__GNUC__) || defined(__TINYC__)  /* Copied from <stdio.h>. */
/* If the buffer is not full (filep->buf_write_ptr != filep->buf_end), append single byte, otherwise call fputc(...). */
static __inline__ __attribute__((__always_inline__)) int putc(int c, FILE *filep) { return (((char**)filep)[0]/*->buf_write_ptr*/ == ((char**)filep)[1]/*->buf_end*/) || (_STDIO_SUPPORTS_LINE_BUFFERING && (unsigned char)c == '\n') ? mini___M_fputc_RP2(c, filep) : (unsigned char)(*((char**)filep)[0]/*->buf_write_ptr*/++ = c); }
#endif

#endif  /* !CONFIG_STDIO_MEDIUM_PRINTF_ONLY */

static int toggle_relaxed(FILE *filep) {
  char *p;
  const int result = filep->dire == FD_WRITE_RELAXED ? mini_fflush(filep) : 0;
  filep->dire ^= 1;  /* Toggle FD_WRITE and FD_WRITE_RELAXED. */
  p = filep->buf_capacity_end;
  filep->buf_capacity_end = filep->buf_end;
  filep->buf_end = p;
  return result;
}

/* We need this only for autoflush-but-not-empty-buffer streams such as
 * stderr.
 *
 * TODO(pts): Use smart linking to eplace this with a no-op if mini_stderr
 * and mini_setvbuf(...). are not linked.
 */
__attribute__((__regparm__(1))) void mini___M_writebuf_relax_RP1(FILE *filep) {
  if (filep->dire == FD_WRITE && filep->buf_capacity_end > filep->buf_end) toggle_relaxed(filep);
}

/* TODO(pts): Use smart linking to eplace this with a no-op if mini_stderr
 * and mini_setvbuf(...). are not linked.
 */
__attribute__((__regparm__(1))) int mini___M_writebuf_unrelax_RP1(FILE *filep) {
  return filep->dire == FD_WRITE_RELAXED ? toggle_relaxed(filep) : 0;
}
