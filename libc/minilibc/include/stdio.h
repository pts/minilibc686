#ifndef _STDIO_H
#define _STDIO_H
#include <_preincl.h>

#include <stdarg_internal.h>  /* Defines __libc__va_list. */
#include <sys/types.h>

#define NULL ((void*)0)  /* Defined in multiple .h files: https://en.cppreference.com/w/c/types/NULL */

#define EOF -1  /* Indicates end-of-file (EOF) or error. */

/* fseek(..., ..., whence) constants. */
#define SEEK_SET 0
#define SEEK_CUR 1
#define SEEK_END 2

#define STDIN_FILENO 0
#define STDOUT_FILENO 1
#define STDERR_FILENO 2

#if defined(__OSI__) || defined(__DOS__) || defined(__NT__)
#  define FILENAME_MAX 255
#else
#  define FILENAME_MAX 4095
#endif

#define BUFSIZ 4096

#define P_tmpdir "/tmp"

typedef struct _SFS_FILE FILE;  /* Different from _FILE. */

__LIBC_VAR(extern FILE *, stdin);
__LIBC_VAR(extern FILE *, stdout);
__LIBC_VAR(extern FILE *, stderr);
#ifdef __WATCOMC__  /* There is no other way with `wcc386 -za'. */
#  pragma aux stdin  "mini_*"
#  pragma aux stdout "mini_*"
#  pragma aux stderr "mini_*"
#endif

#ifndef _STDIO_SUPPORTS_LINE_BUFFERING
#define _STDIO_SUPPORTS_LINE_BUFFERING 1
#endif

__LIBC_FUNC(int, printf, (const char *format, ...), __attribute__((__format__(__printf__, 1, 2))));
__LIBC_FUNC(int, vprintf, (const char *format, __libc__va_list ap), __attribute__((__format__(__printf__, 1, 0))));
__LIBC_FUNC(int, fprintf, (FILE *filep, const char *format, ...), __attribute__((__format__(__printf__, 2, 3))));
__LIBC_FUNC(int, vfprintf, (FILE *filep, const char *format, __libc__va_list ap), __attribute__((__format__(__printf__, 2, 0))));
#ifdef __MINILIBC686__
  __LIBC_FUNC(void, vfprintf_simple, (FILE *filep, const char *format, __libc__va_list ap), __attribute__((__format__(__printf__, 2, 0))));
#endif
__LIBC_FUNC(int, sprintf, (char *str, const char *format, ...), __attribute__((__format__(__printf__, 2, 3))));
__LIBC_FUNC(int, vsprintf, (char *str, const char *format, __libc__va_list ap), __attribute__((__format__(__printf__, 2, 0))));
__LIBC_FUNC(int, snprintf, (char *str, size_t size, const char *format, ...), __attribute__((__format__(__printf__, 3, 4))));
__LIBC_FUNC(int, vsnprintf, (char *str, size_t size, const char *format, __libc__va_list ap), __attribute__((__format__(__printf__, 3, 0))));

__LIBC_FUNC(FILE *, fopen, (const char *pathname, const char *mode), __LIBC_NOATTR);
__LIBC_FUNC(FILE *, fdopen, (int fd, const char *mode), __LIBC_NOATTR);
__LIBC_FUNC(FILE *, freopen, (const char *pathname, const char *mode, FILE *filep), __LIBC_NOATTR);
__LIBC_FUNC(int, fflush, (FILE *filep), __LIBC_NOATTR);
__LIBC_FUNC(int, fclose, (FILE *filep), __LIBC_NOATTR);
__LIBC_FUNC(size_t, fread, (void *ptr, size_t size, size_t nmemb, FILE *filep), __LIBC_NOATTR);
__LIBC_FUNC(size_t, fwrite, (const void *ptr, size_t size, size_t nmemb, FILE *filep), __LIBC_NOATTR);
__LIBC_FUNC(int, fseek, (FILE *filep, __off_t offset, int whence), __LIBC_NOATTR);  /* Only 32-bit __off_t. */
__LIBC_FUNC(void, rewind, (FILE *filep), __LIBC_NOATTR);
__LIBC_FUNC(__off_t, ftell, (FILE *filep), __LIBC_NOATTR);  /* Only 32-bit __off_t. */
__LIBC_FUNC(int, fputs, (const char *s, FILE *filep), __LIBC_NOATTR);
__LIBC_FUNC(char *, fgets, (char *s, int size, FILE *filep), __LIBC_NOATTR);
__LIBC_FUNC(int, puts, (const char *s), __LIBC_NOATTR);
__LIBC_FUNC_MAYBE_MINIRP3(int, fgetc, (FILE *filep), __LIBC_NOATTR);  /* Use `gcc -ffreestanding' or `gcc -fno-builtin' to avoid the compilation error here. */
__LIBC_FUNC_MAYBE_MINIRP3(int, fputc, (int c, FILE *filep), __LIBC_NOATTR);  /* Use `gcc -ffreestanding' or `gcc -fno-builtin' to avoid the compilation error here. */
__LIBC_FUNC_MAYBE_MINIRP3(int, ungetc, (int c, FILE *filep), __LIBC_NOATTR);  /* Use `gcc -ffreestanding' or `gcc -fno-builtin' to avoid the compilation error here. */
#if !defined(__MINILIBC686__) || defined(CONFIG_FUNC_GETC_PUTC) || !(defined(CONFIG_INLINE_GETC_PUTC) || defined(CONFIG_MACRO_GETC_PUTC))
#  ifdef __WATCOMC__
#    ifdef __MINILIBC686__
#      ifdef CONFIG_NO_RP3
        int getc(FILE *filep);
        int putc(int c, FILE *filep);
#        pragma aux getc "mini_fgetc"
#        pragma aux putc "mini_fputc"
#      else  /* CONFIG_NO_RP3 */
        int __fortran getc(FILE *filep);
        int __fortran putc(int c, FILE *filep);
#        pragma aux getc "mini_fgetc_RP3"
#        pragma aux putc "mini_fputc_RP3"
#      endif
#    else  /* __MINILIBC686__ */
      int getc(FILE *filep);
      int putc(int c, FILE *filep);
#      pragma aux getc "_fgetc"
#      pragma aux putc "_fputc"
#    endif  /* else __MINILIBC686__ */
#  else  /* __WATCOMC__ */
#    if defined(CONFIG_NO_RP3) || !defined(__MINILIBC686__)
      int getc(FILE *filep) __asm__(__LIBC_MINI "fgetc");
      int putc(int c, FILE *filep) __asm__(__LIBC_MINI "fputc");
#    else  /* CONFIG_NO_RP3 */
      int getc(FILE *filep) __asm__(__LIBC_MINI "fgetc_RP3") __attribute__((__regparm__(3)));
      int putc(int c, FILE *filep) __asm__(__LIBC_MINI "fputc_RP3") __attribute__((__regparm__(3)));
#    endif  /* else CONFIG_NO_RP3 */
#  endif  /* else __WATCOMC__ */
  __LIBC_FUNC(int, getchar, (void), __LIBC_NOATTR);
  __LIBC_FUNC_MAYBE_MINIRP3(int, putchar, (int c), __LIBC_NOATTR);  /* Use `gcc -ffreestanding' or `gcc -fno-builtin' to avoid the compilation error here. */
#else
  __LIBC_FUNC_MINIRP3(int, __M_fgetc_fallback, (FILE *filep), __LIBC_NOATTR);
#  if defined(CONFIG_MACRO_GETC_PUTC) && !defined(__WATCOMC__)  /* This only works with stdio_medium of minilibc686. It is disabled for __WATCOMC__, because it doesn't support ({...}). For __WATCOMC__, we fall back to CONFIG_INLINE_GETC_PUTC below. */
    /* These macros work in GCC, Clang and TinyCC. TODO(pts): Why should we use a macro rather than an inline function? The inline code is a few bytes shorter than the macro code. */
    /* If the there are bytes to read from the buffer (filep->buf_read_ptr != filep->buf_last), get and return a byte, otherwise call __M_fgetc_fallback(...). */
#    define getc(_filep) (__extension__ ({ FILE *filep = (_filep); (((char**)filep)[2]/*->buf_read_ptr*/ == ((char**)filep)[3]/*->buf_last*/) ? __M_fgetc_fallback(filep) : (unsigned char)*((char**)filep)[2]/*->buf_read_ptr*/++; }))
    /* If the buffer is not full (filep->buf_write_ptr != filep->buf_end), append single byte, otherwise call fputc(...). */
#    define putc(_c, _filep) (__extension__ ({ FILE *filep = (_filep); const unsigned char uc = (_c); (((char**)filep)[0]/*->buf_write_ptr*/ == ((char**)filep)[1]/*->buf_end*/) || (_STDIO_SUPPORTS_LINE_BUFFERING && uc == '\n') ? fputc(uc, filep) : (unsigned char)(((char**)filep)[0]/*->buf_write_ptr*/++[0] = uc); }))
#    define getchar() getc(stdin)
#    define putchar(_c) putc(_c, stdout)
#  else  /* defined(CONFIG_INLINE_GETC_PUTC) */  /* This only works with stdio_medium of minilibc686. It works with __GNUC__, __TINYC__ and __WATCOM__. */
    /* If the there are bytes to read from the buffer (filep->buf_read_ptr != filep->buf_last), get and return a byte, otherwise call __M_fgetc_fallback(...). */
    static __inline__ __attribute__((__always_inline__)) int getc(FILE *filep) { return (((char**)filep)[2]/*->buf_read_ptr*/ == ((char**)filep)[3]/*->buf_last*/) ? __M_fgetc_fallback(filep) : (unsigned char)*((char**)filep)[2]/*->buf_read_ptr*/++; }
    static __inline__ __attribute__((__always_inline__)) int getchar(void) { FILE *filep = stdin; return (((char**)filep)[2]/*->buf_read_ptr*/ == ((char**)filep)[3]/*->buf_last*/) ? __M_fgetc_fallback(filep) : (unsigned char)*((char**)filep)[2]/*->buf_read_ptr*/++; }
    /* If the buffer is not full (filep->buf_write_ptr != filep->buf_end), append single byte, otherwise call fputc(...). */
    static __inline__ __attribute__((__always_inline__)) int putc(int c, FILE *filep) { return (((char**)filep)[0]/*->buf_write_ptr*/ == ((char**)filep)[1]/*->buf_end*/) || (_STDIO_SUPPORTS_LINE_BUFFERING && (unsigned char)c == '\n') ? fputc(c, filep) : (unsigned char)(*((char**)filep)[0]/*->buf_write_ptr*/++ = c); }
    static __inline__ __attribute__((__always_inline__)) int putchar(int c) { FILE *filep = stdout; return (((char**)filep)[0]/*->buf_write_ptr*/ == ((char**)filep)[1]/*->buf_end*/) || (_STDIO_SUPPORTS_LINE_BUFFERING && (unsigned char)c == '\n') ? fputc(c, filep) : (unsigned char)(*((char**)filep)[0]/*->buf_write_ptr*/++ = c); }
#  endif
#endif
#if !defined(__MINILIBC686__) || defined(CONFIG_FUNC_FILENO) || !(defined(CONFIG_INLINE_FILENO) || defined(CONFIG_MACRO_FILENO))
  __LIBC_FUNC(int, fileno, (FILE *filep), __LIBC_NOATTR);
#else
#  if defined(CONFIG_MACRO_FILENO)  /* This only works with stdio_medium of minilibc686. */
#    define fileno(_filep) (*(int*)(void*)(((char**)(_filep))+4))
#  else  /* defined(CONFIG_INLINE_FILENO) */  /* This only works with stdio_medium of minilibc686. */
    static __inline__ __attribute__((__always_inline__)) int fileno(FILE *filep) { return *(int*)(void*)(((char**)(filep))+4); }
#  endif
#endif

__LIBC_FUNC(int, remove, (const char *pathname), __LIBC_NOATTR);
__LIBC_FUNC(int, rename, (const char *oldpath, const char *newpath), __LIBC_NOATTR);  /* Typically rename(2) is defined in <stdio.h>, bu we are lenient are and define in <unistd.h> as well. */

__LIBC_FUNC(void, perror,  (const char *s), __LIBC_NOATTR);

__LIBC_FUNC(char *, tempnam, (const char *dir, const char *pfx), __LIBC_NOATTR);
#ifdef __MINILIBC686__
  __LIBC_FUNC(char *, tempnam_noremove, (const char *dir, const char *pfx), __LIBC_NOATTR);
#endif

#if defined(__UCLIBC__) || defined(__GLIBC__) || defined(__dietlibc__)
  __LIBC_FUNC(int, ferror, (FILE *filep), __LIBC_NOATTR);
#endif

#endif  /* _STDIO_H */
