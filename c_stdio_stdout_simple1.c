/*
 * c_stdio_stdout_simple1.c: a simple partial stdio implementation: just mini_stdout + mini_fputc(...), unbuffered
 * by pts@fazekas.h at Wed May 17 16:29:17 CEST 2023
 */

typedef unsigned size_t;
typedef int ssize_t;
typedef struct _FILE {
  int fd;
} FILE;
#define EOF (-1)

extern ssize_t mini_write(int fd, const void *buf, size_t count);

/* Called by mini__start(...) after main(...) has returned. */
void mini___M_flushall(void) {}

int mini_fputc(int c, FILE *filep) {
  unsigned char cc = c;
  const ssize_t got = mini_write(filep->fd, &cc, 1);
  if (got <= 0) return EOF;
  return cc;  /* Cast as unsigned char. */
}

static FILE struct_stdout = { /* .fd = */ 1 };
FILE *mini_stdout = &struct_stdout;
