#include <stdio.h>

extern int ffs(int i);
extern int mini_ffs(int i);  /* Function under test. */
extern int mini_ffsl(long i);  /* Function under test. */

static char expect(int i) {
  const int expected_value = ffs(i);
  const int value = mini_ffs(i);
  const int value2 = mini_ffsl(i);
  char is_ok = (value == expected_value && value2 == expected_value);
  printf("is_ok=%d i=%d expected_value=%d value=%d value2=%d\n", is_ok, i, expected_value, value, value2);
  return is_ok;
}

int main(int argc, char **argv) {
  int exit_code = 0;
  int i;
  (void)argc; (void)argv;
  for (i = -10; i <= 10; ++i) {
    if (!expect(i)) exit_code |= 1;
  }
  if (!expect((int)0x80000000U)) exit_code |= 1;
  return exit_code;
}
