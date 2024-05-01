typedef struct _FILE *FILE;
extern FILE *mini_stdout, *mini_stderr;
extern int mini_fputc(int c, FILE *filep);  /* Function under test. */

#ifndef TEST_NO_MINI_WRITE
typedef unsigned size_t;
typedef int ssize_t;
extern ssize_t write(int fd, const void *buf, size_t count);
ssize_t mini_write(int fd, const void *buf, size_t count) {
  return write(fd, buf, count);
}
#endif

int main(int argc, char **argv) {
  (void)argc; (void)argv;
  mini_fputc('A', mini_stderr);
  mini_fputc('\n', mini_stdout);
  mini_fputc('o', mini_stdout);
  mini_fputc('B', mini_stderr);
  mini_fputc('\n', mini_stderr);
  mini_fputc('C', mini_stderr);
  return 0;  /* Failure. */
}
