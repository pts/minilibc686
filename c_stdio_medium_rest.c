#include "stdio_medium.h"

/* !! Split it to smaller .c files. */

int mini_fputc(int c, FILE *filep) {
  return mini___M_fputc_RP2(c, filep);
}

size_t mini_fwrite(const void *ptr, size_t size, size_t nmemb, FILE *filep) {
  size_t bc = size * nmemb;  /* Byte count. We don't care about overflow. */
  ssize_t got;
  const char *p = (char*)ptr;
  const char *q;
  if (!IS_FD_ANY_WRITE(filep->dire) || bc == 0) return 0;
  if (filep->buf_end == filep->buf_start) {
    goto write_remaining;
  } else if (filep->dire == FD_WRITE_LINEBUF) {
    /* !! This is a bit different from glibc 2.27: both flush until and
     * including the last '\n', but for glibc 2.27 if buf_end is also reached,
     * then it flushes all the buffer. It looks like it unconditionally copies
     * to the buffer first.
     */
    for (q = p + bc; q != p && q[-1] != '\n'; --q) {}  /* Find the last '\n'. */
    do {
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
    /* We could flush the buffer 1 byte earlier (i.e. when it's full but not
     * yet overfull). However, none of uClibc 0.9.30.1, glibc 2.19 and glibc
     * 2.27. So we don't flush earlier either (here and elsewhere).
     */
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
static __inline__ __attribute__((__always_inline__)) __attribute__((__used__)) int fileno(FILE *filep) { return *(int*)(void*)(((char**)(filep))+4); }
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
    if (_STDIO_EARLY_FREAD_ON_NL && filep->dire == FD_READ_LINEBUF) {
      while (bc != 0 && filep->buf_read_ptr != filep->buf_last) {
        *p++ = c = *filep->buf_read_ptr++;
        --bc;
        if (c == '\n') goto done;
      }
    } else {
      while (bc != 0 && filep->buf_read_ptr != filep->buf_last) {  /* TODO(pts): Is it faster or smaller with memcpy(3)? */
        *p++ = *filep->buf_read_ptr++;
        --bc;
      }
    }
    if (bc == 0) break;
    filep->buf_off += filep->buf_last - filep->buf_start;
    mini___M_discard_buf(filep);
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
    mini___M_discard_buf(filep);  /* The caller expects us to discard the buffer, even if mini_lseek(...) below fails. */
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
static __inline__ __attribute__((__always_inline__)) __attribute__((__used__)) int getc(FILE *filep) { return (((char**)filep)[2]/*->buf_read_ptr*/ == ((char**)filep)[3]/*->buf_last*/) ? mini___M_fgetc_fallback_RP1(filep) : (unsigned char)*((char**)filep)[2]/*->buf_read_ptr*/++; }
#endif

int mini_fgetc(FILE *filep) {
  unsigned char uc;
  /*if (!IS_FD_ANY_READ(filep->dire)) return EOF;*/  /* No need to check, mini_fread(...) below checks it. */
  if (filep->buf_read_ptr != filep->buf_last) return (unsigned char)*filep->buf_read_ptr++;
  return mini_fread(&uc, 1, 1, filep) ? uc : EOF;
}

#if defined(__GNUC__) || defined(__TINYC__)  /* Copied from <stdio.h>. */
/* If the buffer is not full (filep->buf_write_ptr != filep->buf_end), append single byte, otherwise call fputc(...). */
static __inline__ __attribute__((__always_inline__)) __attribute__((__used__)) int putc(int c, FILE *filep) { return (((char**)filep)[0]/*->buf_write_ptr*/ == ((char**)filep)[1]/*->buf_end*/) || (_STDIO_SUPPORTS_LINE_BUFFERING && (unsigned char)c == '\n') ? mini___M_fputc_RP2(c, filep) : (unsigned char)(*((char**)filep)[0]/*->buf_write_ptr*/++ = c); }
#endif
