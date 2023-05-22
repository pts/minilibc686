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

FILE *fopen(const char *pathname, const char *mode) __asm__("mini_fopen");
int fflush(FILE *filep) __asm__("mini_fflush");
int fclose(FILE *filep) __asm__("mini_fclose");
size_t fread(void *ptr, size_t size, size_t nmemb, FILE *filep) __asm__("mini_fread");
size_t fwrite(const void *ptr, size_t size, size_t nmemb, FILE *filep) __asm__("mini_fwrite");
int fseek(FILE *filep, off_t offset, int whence) __asm__("mini_fseek");  /* Only 32-bit off_t. */
off_t ftell(FILE *filep) __asm__("mini_ftell");  /* Only 32-bit off_t */
int fgetc(FILE *filep) __asm__("mini_fgetc");
int fputc(int c, FILE *filep) __asm__("mini_fputc");

int remove(const char *pathname) __asm__("mini_remove");

#ifdef __UCLIBC__
int fprintf(FILE *stream, const char *format, ...) __asm__("mini_fprintf");
int sprintf(char *str, const char *format, ...) __asm__("mini_sprintf");
int ferror(FILE *stream) __asm__("mini_ferror");
int remove(const char *pathname) __asm__("mini_remove");
#endif  /* __UCLIBC__ */

#endif  /* _STDIO_H */
