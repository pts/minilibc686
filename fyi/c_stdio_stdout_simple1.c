/*
 * c_stdio_stdout_simple1.c: a simple partial stdio implementation: just mini_stdout + mini_fputc(...), unbuffered
 * by pts@fazekas.h at Wed May 17 16:29:17 CEST 2023
 */

#define FS_CLOSED 0
#define FS_READ   1
#define FS_WRITE  2
typedef unsigned size_t;
typedef int ssize_t;
typedef struct _FILE {
  int fd;  /* File descriptor, fileno. */
  unsigned char state;  /* FS_... */
  unsigned char indicators;  /* Bitmask of FI_... */
} FILE;
#define EOF (-1)

/* _FILE.state constants. */
#define FS_CLOSED 0
#define FS_READ   1
#define FS_WRITE  2

#define FI_EOF 1
#define FI_ERROR 2

extern ssize_t mini_write(int fd, const void *buf, size_t count);

int mini_fileno(FILE *filep) {
  return filep->fd;
}

void mini_clearerr(FILE *filep) {
  filep->indicators = 0;  /* Clears both FI_EOF and FI_ERROR. */
}

#if 0  /* We don't need this since we don't allow reading. */
int mini_feof(FILE *filep) {
  return filep->indicators & FI_EOF ? 1 : 0;
}
#endif

int mini_ferror(FILE *filep) {
  return filep->indicators & FI_ERROR ? 1 : 0;
}

int mini_fflush(FILE *filep) {
  return mini_ferror(filep);  /* We have nothing to flush. */
}

int mini_fputc(int c, FILE *filep) {
  unsigned char cc = c;
  ssize_t got;
  if (filep->indicators & FI_ERROR) return EOF;
  got = mini_write(filep->fd, &cc, 1);
  if (got <= 0) { filep->indicators |= FI_ERROR; return EOF; }
  return cc;  /* Cast as unsigned char. */
}

static FILE struct_stdout = { /* .fd = */ 1, /* .state = */ FS_WRITE, /* .indicators = */ 0 };
FILE *mini_stdout = &struct_stdout;

/* Called by mini__start(...) after main(...) has returned. */
void mini___M_flushall(void) {}
