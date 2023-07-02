#include <stdio.h>
#include <string.h>

extern int mini_strcasecmp(const char *_l, const char *_r, size_t n_missing);  /* Function under test. Purposefully incorrect declaration (to detect stack use), last argument doesn't exist. */
#if !DO_IGNORE_STRNCASECMP
extern int mini_strncasecmp(const char *_l, const char *_r, size_t n);  /* Function under test. */
#endif

static char expect(const char *l, const char *r, size_t n) {
#if DO_IGNORE_STRNCASECMP
  int expected_value = 0;
#else
  int expected_value = strncasecmp(l, r, n);
#endif
  int expected_value2 = strcasecmp(l, r);
#if DO_IGNORE_STRNCASECMP
  int value = 0;
#else
  int value = mini_strncasecmp(l, r, n);
#endif
  int value2 = mini_strcasecmp(l, r, 0);
  char is_ok = (value == expected_value && value2 == expected_value2);
  printf("is_ok=%d lstr=(%s) rstr=(%s) n=%u exp=%d value=%d exp2=%d value2=%d\n", is_ok, l, r, (unsigned)n, expected_value, value, expected_value2, value2);
  return is_ok;
}

int main(int argc, char **argv) {
  int exit_code = 0;
  (void)argc; (void)argv;
  if (!expect("", "", 0)) exit_code |= 1;
  if (!expect("", "", 5)) exit_code |= 1;
  if (!expect("", "fo+", 0)) exit_code |= 1;
  if (!expect("", "fo+", 5)) exit_code |= 1;
  if (!expect("fo+", "", 0)) exit_code |= 1;
  if (!expect("fo+", "", 5)) exit_code |= 1;
  if (!expect("fo+", "bar", 0)) exit_code |= 1;
  if (!expect("fo+", "fo+d", 3)) exit_code |= 1;
  if (!expect("fo+d", "fO+", 3)) exit_code |= 1;
  if (!expect("fo+d", "fOo", 3)) exit_code |= 1;
  if (!expect("fo+d", "foO", 3)) exit_code |= 1;
  if (!expect("fo+d", "foO", 2)) exit_code |= 1;
  if (!expect("fo+l", "fO+d", 3)) exit_code |= 1;
  if (!expect("fo+l", "fO+d", 4)) exit_code |= 1;
  if (!expect("fo+l", "fO+d", 5)) exit_code |= 1;
  if (!expect("fo+D", "fO+d", 5)) exit_code |= 1;
  return exit_code;
}
