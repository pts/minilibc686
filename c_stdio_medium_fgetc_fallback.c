#include "stdio_medium.h"

__attribute__((__regparm__(1))) int mini___M_fgetc_fallback_RP1(FILE *filep) {
  unsigned char uc;
  return mini_fread(&uc, 1, 1, filep) ? uc : EOF;
}

