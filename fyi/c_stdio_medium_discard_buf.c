#include "stdio_medium.h"

void mini___M_discard_buf(FILE *filep) {
  filep->buf_read_ptr = filep->buf_write_ptr = filep->buf_last = filep->buf_start;
  if (IS_FD_ANY_READ(filep->dire)) filep->buf_write_ptr = filep->buf_end;  /* Sentinel. */
}

