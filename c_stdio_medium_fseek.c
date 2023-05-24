#include "stdio_medium.h"

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

