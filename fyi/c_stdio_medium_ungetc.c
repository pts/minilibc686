#include "stdio_medium.h"

int mini_ungetc(int c, FILE *filep) {
  if (c < 0 || !IS_FD_ANY_READ(filep->dire) || filep->buf_read_ptr == filep->buf_start) return EOF;
  *--filep->buf_read_ptr = c;
  return c;
}
