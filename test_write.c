typedef unsigned size_t;
typedef int ssize_t;
#define STDOUT_FILENO 1

extern ssize_t mini_write(int fd, const void *buf, size_t count);  /* Function under test. */

int main(int argc, char **argv) {
  static const char msg[] = "Hello, Test!\n";
  (void)argc; (void)argv;
  return mini_write(STDOUT_FILENO, msg, sizeof(msg) - 1) <= 0;  /* Condition is true on error exit. */
}
