/*
 * c_stdio_stdout_simple2.c: a simple partial stdio implementation: just mini_stdout (buffered) + mini_stderr (unbuffered) + mini_fputc(...)
 * by pts@fazekas.h at Wed May 17 17:29:07 CEST 2023
 *
 * !! TODO(pts): Add many more tests, especially for line buffering.
 */

#define NULL ((void*)0)

#define FS_CLOSED 0
#define FS_READ   1
#define FS_WRITE  2
typedef unsigned size_t;
typedef int ssize_t;
typedef struct _FILE {
  int fd;  /* File descriptor, fileno. */
  char *bufstart;
  char *bufp;  /* Sentinel: .bufp == .bufend. It means any of: the buffer is full (maybe because it has 0 size), there was an error, or line buffering (_IOLBF) is enabled. */
  char *bufpf;  /* Fallback value iff .bufp == .bufend. */
  char *bufend;
  unsigned char state;  /* FS_... */
  unsigned char indicators;  /* Bitmask of FI_... */
  unsigned char bufmode;
} FILE;

/* _FILE.state constants. */
#define FS_CLOSED 0
#define FS_READ   1
#define FS_WRITE  2

/* _FILE.indicators constants. */
#define FI_EOF 1
#define FI_ERROR 2

/* _FILE.bufmode constants, names (but not values) actually defined by the C
 * standard. Values are same as in glibc and uClibc, but different from
 * OpenWatcom libc.
 */
#define _IOFBF 0  /* Fully buffered. */
#define _IOLBF 1  /* Line buffered. Currently implemented as _IONBF, for simplicity. */
#define _IONBF 2  /* No buffering. */

#define EOF (-1)

extern ssize_t mini_write(int fd, const void *buf, size_t count);

int mini_fileno(FILE *filep) {
  return filep->fd;
}

void mini_clearerr(FILE *filep) {
  filep->indicators = 0;  /* Clears both FI_EOF and FI_ERROR. */
  filep->bufp = filep->bufpf;  /* Restore saved .bufp. */
  if (filep->bufmode == _IOFBF) filep->bufpf = filep->bufend;  /* Make (C1) work later. */
}

#if 0  /* We don't need this since we don't allow reading. */
int mini_feof(FILE *filep) {
  return filep->indicators & FI_EOF;  /* The caller just checks nonzero. The actuial value may be different from glibc. */
}
#endif

int mini_ferror(FILE *filep) {
  return filep->indicators & FI_ERROR;  /* The caller just checks nonzero. The actual value may be different from glibc. */
}

static int set_error(FILE *filep) {
  filep->indicators |= FI_ERROR;
  if (filep->bufmode == _IOFBF) filep->bufpf = filep->bufp;  /* Save .bufp, it will be restored in mini_clearerr(...). */
  filep->bufp = filep->bufend;  /* Fake indicator that the buffer is full, this speeds up the check in mini_fputc(...). */
  return EOF;
}

int mini_fflush(FILE *filep) {
  char *p;
  size_t size, got;
  if (filep->indicators & FI_ERROR) return EOF;  /* TODO(pts): Is this more important than an empty buffer? Probably it is. */
  p = filep->bufstart;
  size = (filep->bufp == filep->bufend ? filep->bufpf : filep->bufp) - p;
  while (size != 0) {  /* This is never true if filep is unbuffered. */
    got = mini_write(filep->fd, p, size);
    if (got + 1U <= 1U) return set_error(filep);  /* EOF. */
    size -= got;
    p += got;
  }
  if (filep->bufmode == _IOLBF) {
    filep->bufpf = filep->bufstart;
  } else {
    filep->bufp = filep->bufstart;
  }
  return 0;
}

/* uClibc has: (__extension__ ({ FILE *__S = ((fff)); ((__S->__user_locking) ? ( ((__S)->__bufpos < (__S)->__bufputc_u) ? (*(__S)->__bufpos++) = (((ccc))) : __fputc_unlocked((((ccc))),(__S)) ) : (fputc)(((ccc)),__S)); }) )
 * GCC doesn't optimize it.
 */
int mini_fputc(int c, FILE *filep) {
  unsigned char uc;
  ssize_t got;
 try_again_after_flush:
  if (filep->bufp != filep->bufend) {  /* Fast path: _IOFBF, no error, buffer not full yet. */
    return (unsigned char)(*filep->bufp++ = c);
  }
  if (filep->indicators & FI_ERROR) return EOF;
  if (filep->bufpf != filep->bufend) {  /* (C1). */ /* The buffer isn't really full, then we have _IOLBF. */
    *filep->bufpf++ = uc = c;
    if (uc == '\n' && mini_fflush(filep)) return EOF;
  } else {  /* The buffer is full. */
     /* Not unbuffered. !! It doesn't have to mean that the buffer size is 0. It rather means that its autoflushed. !! uClibc has stderr unbuffered -- but is fprintf byte-by-byte? glibc still has a 0x2000 byte buffer. */
    if (filep->bufp != filep->bufstart) {  /* The buffer is full, and it has nonzero size. */
      if (mini_fflush(filep)) return EOF;
      goto try_again_after_flush;
    }
    /* The buffer has zero size. */
    uc = c;
    got = mini_write(filep->fd, &uc, 1);
    if (got <= 0) return set_error(filep);  /* EOF. */
  }
  return uc;
}

int mini_setvbuf(FILE *filep, char *buf, int mode, size_t size) {
  if (mini_fflush(filep)) return 1;  /* Flush failure. */  /* TODO(pts): Propagate return value of mini_fflush(...). */
  if (mode + 0U > 2U) return 2;  /* Invalid buffering mode. */
  if (size == 0) mode = _IONBF;
  if (mode == _IONBF) buf = NULL; /* !! allow _IONBF with nonempty buffer, that means immediate flush after printf, but not during */
  filep->bufpf = filep->bufp = filep->bufend = filep->bufstart = buf;
  if (mode != _IONBF) {
    if (buf == NULL) return 3;  /* Normal libc would call malloc(...) on first use. */
    filep->bufpf = filep->bufp = filep->bufstart = buf;
    filep->bufend = buf + size;
    if (mode == _IOLBF) {
      filep->bufp = filep->bufend;  /* Sentinel. */
    } else {
      filep->bufpf = filep->bufend;  /* Sentinel. */
    }
  }
  filep->bufmode = mode;
  return 0;
}

/* Changes stream buffering from _IOFBF to _IOLBF, and if there was an
 * actual change, it does a mini_fflush(filep) as well.
 */
void mini__M_set_linebuf(FILE *filep) {
  if (filep->bufmode == _IOFBF) {
    mini_fflush(filep);
    filep->bufmode = _IOLBF;
    filep->bufpf = filep->bufp;
    filep->bufp = filep->bufend;
  }
}

/* !! If stdout is used (linked) in the program, only then add this to program startup: if (isatty(1)) mini__M_set_linebuf(stdout); */

static char buf_stdout[0x400];  /* glibc 2.19 does this much buffering on stdout if it's a TTY. It does more (0x2000) for non-TTY. */

static FILE struct_stdout = {
    /* .fd = */ 1, /* .bufstart = */ buf_stdout, /* .bufp = */ buf_stdout, /* .bufpf = */ buf_stdout + sizeof(buf_stdout), /* .bufend = */ buf_stdout + sizeof(buf_stdout),
    /* .state = */ FS_WRITE, /* .indicators = */ 0, /* .bufmode = */ _IOFBF };  /* !! TODO(pts): If stdout is a TTY, do _IOLBF. */
FILE *mini_stdout = &struct_stdout;

static FILE struct_stderr = {
    /* .fd = */ 2, /* .bufstart = */ NULL, /* .bufp = */ NULL, /* .bufpf = */ NULL, /* .bufend = */ NULL,  /* Unbuffered. */
    /* .state = */ FS_WRITE, /* .indicators = */ 0, /* .bufmode = */ _IOFBF };
FILE *mini_stderr = &struct_stderr;

void abort(void);

/* Called by mini__start(...) after main(...) has returned. */
void mini___M_flushall(void) {
  /* uClibc _stdio_term(...) iterates over all known streams and flushes
   * them, we should do the same.
   */
  /* !! TODO(pts): mini_fflush(...) everything else. */
  mini_fflush(mini_stdout);
  mini_fflush(mini_stderr);  /* In case it became buffered. */
}
