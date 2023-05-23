#include "stdio_medium.h"

void mini___M_discard_buf(FILE *filep) {
  filep->buf_read_ptr = filep->buf_write_ptr = filep->buf_last = filep->buf_start;
  if (IS_FD_ANY_READ(filep->dire)) filep->buf_write_ptr = filep->buf_end;  /* Sentinel. */
}

/* Always calls mini___M_discard_buf(...). !! TODO(pts): Try __regparm__(1). */
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
  mini___M_discard_buf(filep);
  return got;
}

__attribute__((__regparm__(2))) int mini___M_fputc_RP2(int c, FILE *filep) {
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

static __attribute__((__regparm__(1))) int toggle_relaxed(FILE *filep) {
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
