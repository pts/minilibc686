#ifndef _STDIO_H
#define _STDIO_H

#include <stdarg_internal.h>  /* Defines __libc__va_list. */
#include <sys/types.h>

#define EOF -1  /* Indicates end-of-file (EOF) or error. */

/* fseek(..., ..., whence) constants. */
#define SEEK_SET 0
#define SEEK_CUR 1
#define SEEK_END 2

#define STDIN_FILENO 0
#define STDOUT_FILENO 1
#define STDERR_FILENO 2

typedef struct _SFS_FILE FILE;  /* Different from _FILE. */

extern FILE *stdin __asm__("mini_stdin");
extern FILE *stdout __asm__("mini_stdout");
extern FILE *stderr __asm__("mini_stderr");

#ifndef _STDIO_SUPPORTS_LINE_BUFFERING
#define _STDIO_SUPPORTS_LINE_BUFFERING 1
#endif

int printf(const char *format, ...) __asm__("mini_printf");
int fprintf(FILE *stream, const char *format, ...) __asm__("mini_fprintf");
int vfprintf(FILE *f, const char *format, __libc__va_list ap) __asm__("mini_vfprintf");
#ifdef __UCLIBC__
int sprintf(char *str, const char *format, ...) __asm__("mini_sprintf");
#endif

FILE *fopen(const char *pathname, const char *mode) __asm__("mini_fopen");
int fflush(FILE *filep) __asm__("mini_fflush");
int fclose(FILE *filep) __asm__("mini_fclose");
size_t fread(void *ptr, size_t size, size_t nmemb, FILE *filep) __asm__("mini_fread");
size_t fwrite(const void *ptr, size_t size, size_t nmemb, FILE *filep) __asm__("mini_fwrite");
int fseek(FILE *filep, off_t offset, int whence) __asm__("mini_fseek");  /* Only 32-bit off_t. */
off_t ftell(FILE *filep) __asm__("mini_ftell");  /* Only 32-bit off_t */
int fgetc(FILE *filep) __asm__("mini_fgetc");
#if !defined(__MINILIBC686__) || defined(__UCLIBC__)
  int fputc(int c, FILE *filep) __asm__("mini_fputc");  /* minilibc686 also defines it, but we use the other one. */
#else
  int fputc(int c, FILE *filep) __asm__("mini___M_fputc_RP2") __attribute__((__regparm__(2)));  /* Use `gcc -ffreestanding' or `gcc -fno-builtin' to avoid the compilation error here. */
#endif
#if !(defined(__MINILIBC686__) && !defined(__UCLIBC__)) || defined(CONFIG_FUNC_GETC_PUTC) || !(defined(CONFIG_INLINE_GETC_PUTC) || defined(CONFIG_MACRO_GETC_PUTC))
  int getc(FILE *filep) __asm__("mini_fgetc");
  int putc(int c, FILE *filep) __asm__("mini_fputc");
  int getchar(void) __asm__("mini_getchar");
#  if !defined(__MINILIBC686__) || defined(__UCLIBC__)
  int putchar(int c) __asm__("mini_putchar");
#  else
  int putchar(int c) __asm__("mini_putchar_RP1") __attribute__((__regparm__(1)));  /* Use `gcc -ffreestanding' or `gcc -fno-builtin' to avoid the compilation error here. */
#  endif
#else
  int mini___M_fgetc_fallback_RP1(FILE *filep) __attribute__((__regparm__(1)));
#  if defined(CONFIG_MACRO_GETC_PUTC)  /* This only works with stdio_medium of minilibc686. */
    /* These macros work in GCC, Clang and TinyCC. TODO(pts): Why should we use a macro rather than an inline function? The inline code is a few bytes shorter than the macro code. */
    /* If the there are bytes to read from the buffer (filep->buf_read_ptr != filep->buf_last), get and return a byte, otherwise call mini___M_fgetc_fallback_RP1(...). */
#    define getc(_filep) (__extension__ ({ FILE *filep = (_filep); (((char**)filep)[2]/*->buf_read_ptr*/ == ((char**)filep)[3]/*->buf_last*/) ? mini___M_fgetc_fallback_RP1(filep) : (unsigned char)*((char**)filep)[2]/*->buf_read_ptr*/++; }))
    /* If the buffer is not full (filep->buf_write_ptr != filep->buf_end), append single byte, otherwise call fputc(...). */
#    define putc(_c, _filep) (__extension__ ({ FILE *filep = (_filep); const unsigned char uc = (_c); (((char**)filep)[0]/*->buf_write_ptr*/ == ((char**)filep)[1]/*->buf_end*/) || (_STDIO_SUPPORTS_LINE_BUFFERING && uc == '\n') ? fputc(uc, filep) : (unsigned char)(((char**)filep)[0]/*->buf_write_ptr*/++[0] = uc); }))
#    define getchar() getc(stdin)
#    define putchar(_c) putc(_c, stdout)
#  else  /* defined(CONFIG_INLINE_GETC_PUTC) */  /* This only works with stdio_medium of minilibc686. */
    /* If the there are bytes to read from the buffer (filep->buf_read_ptr != filep->buf_last), get and return a byte, otherwise call mini___M_fgetc_fallback_RP1(...). */
    static __inline__ __attribute__((__always_inline__)) int getc(FILE *filep) { return (((char**)filep)[2]/*->buf_read_ptr*/ == ((char**)filep)[3]/*->buf_last*/) ? mini___M_fgetc_fallback_RP1(filep) : (unsigned char)*((char**)filep)[2]/*->buf_read_ptr*/++; }
    static __inline__ __attribute__((__always_inline__)) int getchar(void) { FILE *filep = stdin; return (((char**)filep)[2]/*->buf_read_ptr*/ == ((char**)filep)[3]/*->buf_last*/) ? mini___M_fgetc_fallback_RP1(filep) : (unsigned char)*((char**)filep)[2]/*->buf_read_ptr*/++; }
    /* If the buffer is not full (filep->buf_write_ptr != filep->buf_end), append single byte, otherwise call fputc(...). */
    static __inline__ __attribute__((__always_inline__)) int putc(int c, FILE *filep) { return (((char**)filep)[0]/*->buf_write_ptr*/ == ((char**)filep)[1]/*->buf_end*/) || (_STDIO_SUPPORTS_LINE_BUFFERING && (unsigned char)c == '\n') ? fputc(c, filep) : (unsigned char)(*((char**)filep)[0]/*->buf_write_ptr*/++ = c); }
    static __inline__ __attribute__((__always_inline__)) int putchar(int c) { FILE *filep = stdout; return (((char**)filep)[0]/*->buf_write_ptr*/ == ((char**)filep)[1]/*->buf_end*/) || (_STDIO_SUPPORTS_LINE_BUFFERING && (unsigned char)c == '\n') ? fputc(c, filep) : (unsigned char)(*((char**)filep)[0]/*->buf_write_ptr*/++ = c); }
#  endif
#endif
#if !(defined(__MINILIBC686__) && !defined(__UCLIBC__)) || defined(CONFIG_FUNC_FILENO) || !(defined(CONFIG_INLINE_FILENO) || defined(CONFIG_MACRO_FILENO))
  int fileno(FILE *filep) __asm__("mini_fileno");
#else
#  if defined(CONFIG_MACRO_FILENO)  /* This only works with stdio_medium of minilibc686. */
#    define fileno(_filep) (*(int*)(void*)(((char**)(_filep))+4))
#  else  /* defined(CONFIG_INLINE_FILENO) */  /* This only works with stdio_medium of minilibc686. */
    static __inline__ __attribute__((__always_inline__)) int fileno(FILE *filep) { return *(int*)(void*)(((char**)(filep))+4); }
#  endif
#endif

int remove(const char *pathname) __asm__("mini_remove");

#ifdef __UCLIBC__
int ferror(FILE *stream) __asm__("mini_ferror");
#endif  /* __UCLIBC__ */

#endif  /* _STDIO_H */
