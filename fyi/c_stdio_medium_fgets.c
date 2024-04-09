#include "stdio_medium.h"

char *fgets(char *s, int size, FILE *filep) {
  unsigned char uc;
  int l;
  if (size <= 0) return 0;
  for (l = 0; l + 1 < size; ) {
    if (filep->buf_read_ptr != filep->buf_last) {  /* Fast path. */
      uc = *filep->buf_read_ptr++;
    } else {
      if (mini_fread(&uc, 1, 1, filep) == 0) {  /* This will fill up the buffer. */
	if (!l) return 0;  /* Indicate EOF. */
	break;
      }
    }
    s[l++] = uc;
    if (uc == '\n') break;
  }
  s[l] = 0;
  return s;
}
