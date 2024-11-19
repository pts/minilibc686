#include <stdio.h>
#include <string.h>

extern char *mini_strncat(char *dest, const char *src, size_t n);

char *reference_strncat(char *dest, const char *src, size_t n) {
  size_t i;
  char *dest_orig = dest;
  const char *src_limit = src + n;
  for (; *dest != '\0'; ++dest) {}
  for (; src != src_limit && *src != '\0'; *dest++ = *src++) {}
  *dest = '\0';
  return dest_orig;
}

static char dest[0x40];

static char test_strncat(const char *src, size_t n, char *(*func_strncat)(char *dest, const char *src, size_t n)) {
  size_t i;
  dest[0] = 'B'; dest[1] = 'a'; dest[2] = 'r'; dest[3] = '\0';
  for (i = 4; i < sizeof(dest); ++i) {
    dest[i] = '#';
  }
  if (func_strncat(dest, src, n) != dest) return 2;
  if (dest[0] != 'B' || dest[1] != 'a' || dest[2] != 'r') return 1;
  for (i = 0; i < n && src[i] != '\0'; ++i) {  /* Prefix of dest must match src. */
    if (dest[i + 3] != src[i]) return 3;
  }
  if (dest[i += 3] != '\0') return 4;
  for (++i; i < sizeof(dest); ++i) {
    if (dest[i] != '#') return 5;  /* Rest of dest must not be overwritten. */
  }
  return 0;  /* OK. */
}

static char test_all_strncat(char *(*func_strncat)(char *dest, const char *src, size_t n)) {
  const char src[] = "Hello, World!\n";
  char result;
  size_t n = sizeof(src) + 4;
  for (;; --n) {
    if ((result = test_strncat(src, n, func_strncat)) != 0) return result;
    if (n == 0) return 0;  /* All OK. */
  }
}

int main(int argc, char **argv) {
  int exit_code = 0;
  (void)argc; (void)argv;
  if ((exit_code = test_all_strncat(reference_strncat)) != 0) return exit_code + 10;
  return test_all_strncat(mini_strncat);
}
