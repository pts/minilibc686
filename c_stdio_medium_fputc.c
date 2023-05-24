#include "stdio_medium.h"

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

#if defined(__GNUC__) || defined(__TINYC__)  /* Copied from <stdio.h>. */
/* If the buffer is not full (filep->buf_write_ptr != filep->buf_end), append single byte, otherwise call fputc(...). */
static __inline__ __attribute__((__always_inline__)) __attribute__((__used__)) int putc(int c, FILE *filep) { return (((char**)filep)[0]/*->buf_write_ptr*/ == ((char**)filep)[1]/*->buf_end*/) || (_STDIO_SUPPORTS_LINE_BUFFERING && (unsigned char)c == '\n') ? mini___M_fputc_RP2(c, filep) : (unsigned char)(*((char**)filep)[0]/*->buf_write_ptr*/++ = c); }
#endif

int mini_fputc(int c, FILE *filep) {
  return mini___M_fputc_RP2(c, filep);
}
