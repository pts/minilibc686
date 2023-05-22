#ifndef _STDIO_H
#define _STDIO_H

#include <sys/types.h>

int printf(const char *format, ...) __asm__("mini_printf");
/*int fprintf(FILE *f, const char *format, ...) __asm__("mini_fprintf");*/  /* TODO(pts): Make it work. */
/*int vfprintf(FILE *f, const char *format, va_list ap) __asm__("mini_vfprintf");*/  /* TODO(pts): Make it work. */

#define EOF -1  /* Indicates end-of-file (EOF) or error. */

/* fseek(..., ..., whence) constants. */
#define SEEK_SET 0
#define SEEK_CUR 1
#define SEEK_END 2

typedef struct _SFS_FILE FILE;  /* Different from _FILE. */

#ifdef __UCLIBC__  /* Not implemented yet explicitly. */
extern FILE *stdin __asm__("mini_stdin");
#endif  /* __UCLIBC__ */
extern FILE *stdout __asm__("mini_stdout");
extern FILE *stderr __asm__("mini_stderr");

#ifndef _STDIO_SUPPORTS_LINE_BUFFERING
#define _STDIO_SUPPORTS_LINE_BUFFERING 0
#endif

FILE *fopen(const char *pathname, const char *mode) __asm__("mini_fopen");
int fflush(FILE *filep) __asm__("mini_fflush");
int fclose(FILE *filep) __asm__("mini_fclose");
size_t fread(void *ptr, size_t size, size_t nmemb, FILE *filep) __asm__("mini_fread");
size_t fwrite(const void *ptr, size_t size, size_t nmemb, FILE *filep) __asm__("mini_fwrite");
int fseek(FILE *filep, off_t offset, int whence) __asm__("mini_fseek");  /* Only 32-bit off_t. */
off_t ftell(FILE *filep) __asm__("mini_ftell");  /* Only 32-bit off_t */
int fgetc(FILE *filep) __asm__("mini_fgetc");
int fputc(int c, FILE *filep) __asm__("mini_fputc");
#if !(defined(__MINILIBC686__) && !defined(__UCLIBC__)) || defined(CONFIG_FUNC_GETC_PUTC) || !(defined(CONFIG_INLINE_GETC_PUTC) || defined(CONFIG_MACRO_GETC_PUTC))
  int getc(FILE *filep) __asm__("mini_fgetc");
  int putc(int c, FILE *filep) __asm__("mini_fputc");
#else
  int mini__fgetc_slow(FILE *filep);
#  if defined(CONFIG_MACRO_GETC_PUTC)  /* This only works with stdio_medium of minilibc686. */
    /* These macros work in GCC, Clang and TinyCC. TODO(pts): Why should we use a macro rather than an inline function? The inline code is a few bytes shorter than the macro code. */
    /* If the there are bytes to read from the buffer (filep->buf_read_ptr != filep->buf_last), get and return a byte, otherwise call mini__fgetc_slow(...). */
#    define getc(_filep) (__extension__ ({ FILE *filep = (_filep); (((char**)filep)[2]/*->buf_read_ptr*/ == ((char**)filep)[3]/*->buf_last*/) ? mini__fgetc_slow(filep) : (unsigned char)*((char**)filep)[2]/*->buf_read_ptr*/++; }))
    /* If the buffer is not full (filep->buf_write_ptr != filep->buf_end), append single byte, otherwise call fputc(...). */
#    define putc(_c, _filep) (__extension__ ({ FILE *filep = (_filep); const unsigned char uc = (_c); (((char**)filep)[0]/*->buf_write_ptr*/ == ((char**)filep)[1]/*->buf_end*/) || (_STDIO_SUPPORTS_LINE_BUFFERING && uc == '\n') ? fputc(uc, filep) : (unsigned char)(((char**)filep)[0]/*->buf_write_ptr*/++[0] = uc); }))
#  else  /* defined(CONFIG_INLINE_GETC_PUTC) */  /* This only works with stdio_medium of minilibc686. */
    /* If the there are bytes to read from the buffer (filep->buf_read_ptr != filep->buf_last), get and return a byte, otherwise call mini__fgetc_slow(...). */
    static __inline__ __attribute__((__always_inline__)) int getc(FILE *filep) { return (((char**)filep)[2]/*->buf_read_ptr*/ == ((char**)filep)[3]/*->buf_last*/) ? mini__fgetc_slow(filep) : (unsigned char)*((char**)filep)[2]/*->buf_read_ptr*/++; }
    /* If the buffer is not full (filep->buf_write_ptr != filep->buf_end), append single byte, otherwise call fputc(...). */
    static __inline__ __attribute__((__always_inline__)) int putc(int c, FILE *filep) { return (((char**)filep)[0]/*->buf_write_ptr*/ == ((char**)filep)[1]/*->buf_end*/) || (_STDIO_SUPPORTS_LINE_BUFFERING && (unsigned char)c == '\n') ? fputc(c, filep) : (unsigned char)(*((char**)filep)[0]/*->buf_write_ptr*/++ = c); }
#  endif
#endif

int remove(const char *pathname) __asm__("mini_remove");

#ifdef __UCLIBC__
int fprintf(FILE *stream, const char *format, ...) __asm__("mini_fprintf");
int sprintf(char *str, const char *format, ...) __asm__("mini_sprintf");
int ferror(FILE *stream) __asm__("mini_ferror");
int remove(const char *pathname) __asm__("mini_remove");
#endif  /* __UCLIBC__ */

#endif  /* _STDIO_H */
