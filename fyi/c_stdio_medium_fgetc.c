#include "stdio_medium.h"

#if defined(__GNUC__) || defined(__TINYC__)  /* Copied from <stdio.h>. */
/* If the there are bytes to read from the buffer (filep->buf_read_ptr != filep->buf_last), get and return a byte, otherwise call mini___M_fgetc_fallback_RP1(...). */
static __inline__ __attribute__((__always_inline__)) __attribute__((__used__)) int getc(FILE *filep) { return (((char**)filep)[2]/*->buf_read_ptr*/ == ((char**)filep)[3]/*->buf_last*/) ? mini___M_fgetc_fallback_RP1(filep) : (unsigned char)*((char**)filep)[2]/*->buf_read_ptr*/++; }
#endif

int mini_fgetc(FILE *filep) {
  unsigned char uc;
  /*if (!IS_FD_ANY_READ(filep->dire)) return EOF;*/  /* No need to check, mini_fread(...) below checks it. */
  if (filep->buf_read_ptr != filep->buf_last) return (unsigned char)*filep->buf_read_ptr++;
  return mini_fread(&uc, 1, 1, filep) ? uc : EOF;
}

