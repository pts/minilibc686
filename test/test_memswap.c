#include <stdlib.h>  /* NULL. */
#include <string.h>

#ifdef TEST_RP3
#  undef __asm__
  extern __attribute__((__regparm__(3))) void mini_memswap(void *a, void *b, size_t size) __asm__("mini_memswap_RP3");  /* Function under test. */
#else
  extern void mini_memswap(void *a, void *b, size_t size);  /* Function under test. */
#endif

int main(int argc, char **argv) {
  char buf1[] = "foo!here";
  char buf2[] = "bar!there";
  mini_memswap(NULL, NULL, 0);  /* Shouldn't crash. */
  mini_memswap(buf1, buf2, 0);  /* Shouldn't crash. */
  if (strcmp(buf1, "foo!here") != 0) return 2;
  if (strcmp(buf2, "bar!there") != 0) return 3;
  mini_memswap(buf1, buf2, 3);
  if (strcmp(buf1, "bar!here") != 0) return 4;
  if (strcmp(buf2, "foo!there") != 0) return 5;
  return 0;
}