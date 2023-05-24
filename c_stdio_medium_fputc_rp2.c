#include "stdio_medium.h"

int REGPARM2 mini___M_fputc_RP2(int c, FILE *filep) {
  /* It's not allowed to call mini___M_fputc_RP2 with filep->dire ==
   * FD_WRITE_SATURATE, the caller has to handle it.
   */
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

