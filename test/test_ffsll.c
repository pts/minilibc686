#include <stdio.h>

extern int ffs(int i);
extern int mini_ffsll(long long i);  /* Function under test. */
extern int __ffsdi2(long long i);  /* Function under test. */

int ffsll(long long i) {
  const int r = ffs((int)i);
  return r ? r : i == 0 ? 0 : 32 + ffs((unsigned long long)i >> 32);
}

static char expect(long long i) {
  const int expected_value = ffsll(i);
  const int value = mini_ffsll(i);
  const int value2 = __i64_ffsdi2(i);
  char is_ok = (value == expected_value);
  printf("is_ok=%d i=%lld expected_value=%d value=%d\n", is_ok, i, expected_value, value);
  return is_ok;
}

int main(int argc, char **argv) {
  int exit_code = 0;
  int i;
  (void)argc; (void)argv;
  for (i = -10; i <= 10; ++i) {
    if (!expect(i)) exit_code |= 1;
  }
  if (!expect((5ULL << 30))) exit_code |= 1;
  if (!expect((5ULL << 31))) exit_code |= 1;
  if (!expect((5ULL << 32))) exit_code |= 1;
  if (!expect((5ULL << 33))) exit_code |= 1;
  if (!expect((5ULL << 62))) exit_code |= 1;
  if (!expect((5ULL << 63))) exit_code |= 1;
  return exit_code;
}
