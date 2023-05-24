#include "stdio_medium.h"

#if defined(__GNUC__) || defined(__TINYC__)  /* Copied from <stdio.h>. */
static __inline__ __attribute__((__always_inline__)) __attribute__((__used__)) int fileno(FILE *filep) { return *(int*)(void*)(((char**)(filep))+4); }
#endif

int mini_fileno(FILE *filep) {
  return filep->fd;  /* EOF if closed. */
}

