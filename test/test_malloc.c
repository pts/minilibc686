#include <stdio.h>
#include <stdlib.h>
#include <string.h>

extern void *mini_malloc(size_t size);  /* Function under test. */
extern void *mini_realloc(void *ptr, size_t size);  /* Function under test. */
extern void mini_free(void *ptr);  /* Function under test. */

static const char start_msg[] = "Start of block.";
static const char end_msg[] = "End of block.";

static void fill_block(char *p, unsigned size) {
  memset(p, '*', size);
  memcpy(p, start_msg, sizeof(start_msg));
  memcpy(p + size - sizeof(end_msg), end_msg, sizeof(end_msg));
}

static int is_block_intact(const char *p, unsigned size) {
  return memcmp(p, start_msg, sizeof(start_msg)) == 0 &&
         p[sizeof(start_msg)] == '*' &&
         p[size - sizeof(end_msg) - 1] == '*' &&
         memcmp(p + size - sizeof(end_msg), end_msg, sizeof(end_msg)) == 0;
}

int main(int argc, char **argv) {
  const int size = 12345;
  char *p;
  (void)argc; (void)argv;
  if (!(p = mini_malloc(size))) return 2;
  if ((size_t)p & 0xf) return 3;  /* Not aligned. */
  fill_block(p, size);
  if (!is_block_intact(p, size)) return 4;
  if (!(p = mini_realloc(p, size))) return 5;
  if ((size_t)p & 0xf) return 6;  /* Not aligned. */
  mini_free(0);  /* No-op. */
  if (!is_block_intact(p, size)) return 7;
  if (!(p = mini_realloc(p, size + 4567))) return 8;
  if ((size_t)p & 0xf) return 9;  /* Not aligned. */
  if (!is_block_intact(p, size)) return 10;
  mini_free(p);
  if (!(p = mini_malloc(0))) return 11;  /* uClibc also return non-NULL here. */
  if ((size_t)p & 0xf) return 12;  /* Not aligned. */
  mini_free(p);
  if (!(p = mini_realloc(0, size))) return 13;
  if ((size_t)p & 0xf) return 14;  /* Not aligned. */
  fill_block(p, size);
  if (!is_block_intact(p, size)) return 15;
  mini_free(p);
  return 0;  /* EXIT_SUCCESS. */
}
