#include "stdio_medium.h"

int mini_fclose(FILE *filep) {
  int got;
  if (filep->dire == FD_CLOSED) return EOF;
  got = (IS_FD_ANY_READ(filep->dire)) ? 0 : mini_fflush(filep);
  mini_close(filep->fd);
  filep->dire = FD_CLOSED;
  filep->fd = EOF;  /* Sentinel for future calls to mini_fileno(filep) etc. */
  filep->buf_write_ptr = filep->buf_end;  /* Sentinel for future calls to mini_fputc(..., filep). */
  filep->buf_read_ptr = filep->buf_last;  /* Sentinel for future calls to mini_fgetc(filep). */
  return got;
}

