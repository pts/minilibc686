#include "stdio_medium.h"

static int REGPARM1 toggle_relaxed(FILE *filep) {
  char *p;
  const int result = filep->dire == FD_WRITE_RELAXED ? mini_fflush(filep) : 0;
  filep->dire ^= 1;  /* Toggle FD_WRITE and FD_WRITE_RELAXED. */
  p = filep->buf_capacity_end;
  filep->buf_capacity_end = filep->buf_end;
  filep->buf_end = p;
  return result;
}

/* We need this only for autoflush-but-not-empty-buffer streams such as
 * stderr.
 *
 * TODO(pts): Use smart linking to eplace this with a no-op if mini_stderr
 * and mini_setvbuf(...). are not linked.
 */
void REGPARM1 mini___M_writebuf_relax_RP1(FILE *filep) {
  if (filep->dire == FD_WRITE && filep->buf_capacity_end > filep->buf_end) toggle_relaxed(filep);
}

/* TODO(pts): Use smart linking to eplace this with a no-op if mini_stderr
 * and mini_setvbuf(...). are not linked.
 */
int REGPARM1 mini___M_writebuf_unrelax_RP1(FILE *filep) {
  return filep->dire == FD_WRITE_RELAXED ? toggle_relaxed(filep) : 0;
}
