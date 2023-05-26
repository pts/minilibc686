#include "stdio_medium.h"

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

