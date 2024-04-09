#include <stdio.h>
#include <string.h>

extern char *mini_strncpy(char *dest, const char *src, size_t n);

static char dest[0x40];

static char test_strncpy(const char *src, size_t n) {
  size_t i;
  if (n > sizeof(dest)) return 1;
  for (i = 0; i < sizeof(dest); ++i) {
    dest[i] = '#';
  }
  if (mini_strncpy(dest, src, n) != dest) return 2;
  for (i = 0; i < n && src[i] != '\0'; ++i) {  /* Prefix of dest must match src. */
    if (dest[i] != src[i]) return 3;
  }
  for (; i < n; ++i) {
    if (dest[i] != '\0') return 4;
  }
  return 0;  /* OK. */
}

static char test_all_strncpy(const char *src, size_t n) {
  char result;
  for (;; --n) {
    if ((result = test_strncpy(src, n)) != 0) return result;
    if (n == 0) return 0;  /* All OK. */
  }
}

int main(int argc, char **argv) {
  int exit_code = 0;
  (void)argc; (void)argv;
  return test_all_strncpy("Hello, World!\n", sizeof(dest));
}
