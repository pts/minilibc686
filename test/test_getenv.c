#include <stdlib.h>
#include <unistd.h>

size_t my_strlen(const char *s) {
  const char *s0;
  for (s0 = s; *s; ++s) {}
  return s - s0;
}

int main(int argc, char **argv) {
  size_t size;
  char *value;
  (void)argc; (void)argv;
  if (!argv[0] || !argv[1] || argv[2]) return 1;
  value = getenv(argv[1]);
  if (value) {
    size = my_strlen(value);
    value[size] = '\n';  /* This is safe, we exit soon anyway. */
    (void)!write(1, value, size + 1);
  }
  return 0;
}
