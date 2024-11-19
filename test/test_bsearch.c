#include <stdio.h>
#include <stdlib.h>

void *mini_bsearch(const void *key, const void *base, size_t nmemb, size_t size, int (*compar)(const void*, const void*));

static int cmp_short(const void *a, const void *b) {
  return *(const short*)a - *(const short*)b;  /* Increasing. */
}

static const short ary[] = { 3, 5, 5, 5, 5, 5, 6, 8 };

static void expect(short key, int expected_pos) {
  const short *ppos = (const short*)mini_bsearch(&key, ary, sizeof(ary) / sizeof(ary[0]), sizeof(ary[0]), cmp_short);
  const int pos = ppos ? ppos - ary : -1; 
  const char is_ok = (pos == expected_pos);
  printf("is_ok=%d key=%d pos=%d expected_pos=%d\n", is_ok, key, pos, expected_pos);
  return is_ok;
}

int main(int argc, char **argv) {
  int exit_code = 0;
  (void)argc; (void)argv;
  if (!expect(2, -1) && !exit_code) exit_code = 2;
  if (!expect(3, 0) && !exit_code) exit_code = 3;
  if (!expect(4, -1) && !exit_code) exit_code = 4;
  if (!expect(5, 4) && !exit_code) exit_code = 5;  /* According to the spec, the result could be any of 1, 2, 3, 4 or 5.  */
  if (!expect(6, 6) && !exit_code) exit_code = 6;
  if (!expect(7, -1) && !exit_code) exit_code = 7;
  if (!expect(8, 7) && !exit_code) exit_code = 8;
  if (!expect(9, -1) && !exit_code) exit_code = 9;
  return exit_code;
}
