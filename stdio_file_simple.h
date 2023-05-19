/*
 * stdio_file_simple.h: public API for file I/O
 * by pts@fazekas.h at Fri May 19 16:23:16 CEST 2023
 *
 * This API has multiple implementations, e.g
 * c_stdio_file_simple_unbuffered. and c_stdio_file_simple_buffered.c
 * See the source comments for limitations of each implementation.
 */

#ifndef _STDIO_FILE_SIMPLE_H
#define _STDIO_FILE_SIMPLE_H

#define EOF -1  /* Indicates end-of-file (EOF) or error. */

/* fseek(..., ..., whence) constants. */
#define SEEK_SET 0
#define SEEK_CUR 1
#define SEEK_END 2

typedef unsigned size_t;
typedef int ssize_t;
typedef long off_t;  /* Still 32 bits only. */

typedef struct _SFS_FILE FILE;  /* Different from _FILE. */

extern FILE *mini_fopen(const char *pathname, const char *mode);
extern int mini_fflush(FILE *filep);
extern int mini_fclose(FILE *filep);
extern size_t mini_fread(void *ptr, size_t size, size_t nmemb, FILE *filep);
extern size_t mini_fwrite(const void *ptr, size_t size, size_t nmemb, FILE *filep);
extern int mini_fseek(FILE *filep, off_t offset, int whence);  /* Only 32-bit off_t. */
extern off_t mini_ftell(FILE *filep);  /* Only 32-bit off_t */
extern int mini_fgetc(FILE *filep);

#endif /* _STDIO_FILE_SIMPLE_H */
