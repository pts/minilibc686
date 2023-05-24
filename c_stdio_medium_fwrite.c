#include "stdio_medium.h"

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
