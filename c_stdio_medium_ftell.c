#include "stdio_medium.h"

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
