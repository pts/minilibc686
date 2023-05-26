#include "stdio_medium.h"

int mini_fclose(FILE *filep) {
  int got;
  if (filep->dire == FD_CLOSED) return EOF;
  got = (IS_FD_ANY_READ(filep->dire)) ? 0 : mini_fflush(filep);
  mini_close(filep->fd);
  filep->dire = FD_CLOSED;
  filep->fd = EOF;  /* Sentinel for future calls to fileno(filep) etc. */
  return got;
}

