#include <limits.h>  /* PATH_MAX. */
#include <unistd.h>

size_t my_strlen(const char *s) {
  const char *s0;
  for (s0 = s; *s; ++s) {}
  return s - s0;
}

int main(int argc, char **argv) {
  static char cwd[PATH_MAX];
  size_t size;
  (void)argc; (void)argv;
  if (getcwd(cwd, sizeof(cwd)) != cwd) return 1;
  size = my_strlen(cwd);
  cwd[size] = '\n';
  (void)!write(1, cwd, size + 1);
  return 0;
}
