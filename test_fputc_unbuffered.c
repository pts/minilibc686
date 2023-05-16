typedef struct _FILE *FILE;
extern FILE *mini_stdout, *mini_stderr;
extern int mini_fputc(int c, FILE *filep);  /* Function under test. */

typedef unsigned size_t;
typedef int ssize_t;
extern ssize_t write(int fd, const void *buf, size_t count);
ssize_t mini_write(int fd, const void *buf, size_t count) {
  return write(fd, buf, count);
}

int main(int argc, char **argv) {
  (void)argc; (void)argv;
  mini_fputc('A', mini_stderr);
  mini_fputc('\n', mini_stdout);
  return 0;  /* Failure. */
}
