/*
 * stdio_medium.h: a medium-partial, buffered stdio implementation for files and standard streams (stdin, stdout or stderr)
 * by pts@fazekas.h at Mon May 22 15:20:04 CEST 2023
 *
 * Features:
 *
 * * Open files are flushed at mini_exit(...) time, including when returning
 *   from main(...).
 * * File I/O is buffered.
 * * stdin and stdout line buffering is autodetected at program startup.
 *
 * Limitations:
 *
 * * Only these functions are implemented: fopen, fclose, fread, fwrite,
 *   fseek, ftell, fileno, fgetc, getc (defined in <stdio.h>), fputc, putc
 *   (defined in <stdio.h>), printf, vprintf, fprintf, vfprintf,
 *   sprintf, vsprintf, snprintf, vsnprintf.
 * * !! mini_fseek(...) doesn't work (can do anything) if the file size is
 *   larger than 4 GiB - 4 KiB. That's because the return value of lseek(2)
 *   (without errno) doesn't fit to 32 bits.
 * * !! mini_ftell(...) returns garbage if the file size is larger than 4 GiB -
 *   4 KiB.
 * * Only full buffering (_IOFBF) is implemented for files opened with
 *   fopen(...). For stdin and stdout, it's linue buffering (_IOLBF) if it
 *   is a TTY (terminal), otherwise it's full buffering.
 * * !! Implement gets.
 * * !! Implement fgets.
 * * Only fopen modes "rb" (same as "r", for reading), "wb" (same as "w",
 *   for writing), "ab" (same as "a", for appending) are implemented. Thus
 *   the file can be opened only in one direction at a time.
 * * !! There is no error indicator bit, subsequent read(2) and write(2) will
 *   be attempted even after an I/O error.
 * * Only up to a compile-time fixed number of files (default:
 *   FILE_CAPACITY == 2) can be open at the same time.
 * * Buffer size is fixed at compile time (default: BUF_SIZE == 0x1000).
 *   stdin, stdout and stderr have a default, smaller buffer size.
 * * !! Currently functions are not split to multiple .c files, thus unneeded
 *   functions will also be linked.
 * * The behavior is undefined if `size * nmemb' is overflows (i.e. at
 *   least 2 ** 32 == 4 GiB).
 * * When the file is opened for appending, the result of ftell(...) is not
 *   reliable. As a workaround, fseek(filep, 0, SEEK_CUR) first, and then
 *   call ftell(filep).
 */

/* See the public API in <stdio.h>. */

#define EOF -1  /* Indicates end-of-file (EOF) or error. */

/* fseek(..., ..., whence) constants. */
#define SEEK_SET 0
#define SEEK_CUR 1
#define SEEK_END 2

typedef unsigned size_t;
typedef int ssize_t;
typedef long off_t;  /* Still 32 bits only. */

typedef struct _SMS_FILE FILE;  /* Different from _FILE. */

#define FILE_CAPACITY 2  /* TODO(pts): Make this configurable: CONFIG_FILE_CAPACTIY etc. */
#define BUF_SIZE 0x1000  /* glibc has 0x2000, uClibc has BUFSIZ == 0x1000. */

#define NULL ((void*)0)

/* _FILE.dire (direction) constant. */
#define FD_CLOSED 0
#define FD_READ 1
#define FD_WRITE 4  /* Must be even, so that `^= 1' can toggle between FD_WRITE and FD_WRITE_RELAXED. */
#define FD_WRITE_RELAXED (FD_WRITE+1)  /* Like FD_WRITE, but the buffer size will be set to 0 by mini___M_writebuf_unrelax(...). */
#define FD_READ_LINEBUF (FD_READ+2)  /* Line buffered, for reading. */
#define FD_WRITE_LINEBUF (FD_WRITE+2)  /* Line buffered, for writing. */
#define FD_WRITE_SATURATE (FD_WRITE+3)  /* Like FD_WRITE, but silently ignore further writes when the buffer is full. Used and implemented by mini_snprintf(...) and mini_vsnprintf(...). */

#define IS_FD_ANY_READ(dire) ((unsigned char)((dire) - FD_READ) < (unsigned char)(FD_WRITE - FD_READ + 0U))
#define IS_FD_ANY_WRITE(dire) ((unsigned char)(dire) >= (unsigned char)FD_WRITE)

#define _STDIO_SUPPORTS_EMPTY_BUFFERS 1
#define _STDIO_SUPPORTS_LINE_BUFFERING 1  /* If changed, also update include/stdio.h. */
#define _STDIO_EARLY_FREAD_ON_NL 0  /* None of uClibc 0.9.30.1, glibc 2.19 and glibc 2.27 return early of '\n' for fread(3), so we don't do it either. */

struct _SMS_FILE {  /* Layout must match stdio_medium_*.nasm. */
  /* The first two pointers must be buf_write_ptr and buf_end, for the putc(c, filep) macro to work. */
  char *buf_write_ptr;  /* For writing: points to the first available byte in buf. */
  char *buf_end;  /* Points to the end of the buffer (i.e. byte after the buffer). */
  /* The next two pointers must be buf_write_ptr and buf_end, for the getc(filep) macro to work. */
  char *buf_read_ptr;  /* For reading: points to the first unreturned byte in buf. */
  char *buf_last;  /* For reading: points after the last byte read from file. */
  /* fd must come right after the 4 pointers above, for the fileno(filep) macro to work. */
  int fd;
  /* dire must come right after fd above, for mini___M_init_isatty(...) to work. */
  unsigned char dire;  /* Direction. One of FD_... . FD_CLOSED by default. */
  char padding[sizeof(int) - 1];
  /* Invariant: buf_start <= buf_write_ptr <= buf_end <= buf_capacity_end (unless FD_WRITE_RELAXED). */
  /* Invariant: buf_start <= buf_read_ptr <= buf_last <= buf_end. <= buf_capacity. */
  char *buf_start;  /* Points to the start of the buffer. */
  char *buf_capacity_end;  /* Indicates the end of the buffer data available (unless FD_WRITE_RELAXED). The region buf_end...buf_capacity_end is currently disabled. */
  off_t buf_off;  /* Points to the file offset of buf. */
};

/* Underlying syscall API. */
#define O_RDONLY 0
#define O_WRONLY 1
#define O_RDWR 2
#define O_CREAT 0100  /* Linux-specific. */
#define O_EXCL  0200  /* Linux-specific. */
#define O_TRUNC 01000  /* Linux-specific. */
#define O_APPEND 02000  /* Linux-specific. */
typedef unsigned mode_t;
extern int mini_open(const char *pathname, int flags, mode_t mode);
extern int mini_close(int fd);
extern ssize_t mini_read(int fd, void *buf, size_t count);
extern ssize_t mini_write(int fd, const void *buf, size_t count);
extern off_t mini_lseek(int fd, off_t offset, int whence);

#ifdef __WATCOMC__
#  define __extension__
#  define REGPARM1 __watcall
#  define REGPARM2 __watcall  /* REGPARM3 wouldn't work, __watcall expects 3rd argument in ECX, __regparm__(3) expects in EBX. */
#else
#  define REGPARM1 __attribute__((__regparm__(1)))
#  define REGPARM2 __attribute__((__regparm__(2)))
#endif

void mini___M_discard_buf(FILE *filep);
int REGPARM2 mini___M_fputc_RP2(int c, FILE *filep);
int mini_fflush(FILE *filep);

size_t mini_fread(void *ptr, size_t size, size_t nmemb, FILE *filep);
int REGPARM1 mini___M_fgetc_fallback_RP1(FILE *filep);
