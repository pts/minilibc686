#include "stdio_medium.h"

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
