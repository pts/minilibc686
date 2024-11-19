#include <stdio.h>
#include <string.h>

extern char *mini_strdup(const char *s);  /* Function under test. */

static char realloc_buf[0x10];

char *mini_realloc(void *ptr, size_t size) {  /* Fake implementation, called by mini_strdup(...). */
  /* fprintf(stderr, "fatal: mini_realloc(0x%lx, %u)\n", (unsigned long)ptr, size); */
  return ptr ? NULL : realloc_buf;
}

int main(int argc, char **argv) {
  const char msg[] = "Hello, World!\n";
  char *p;
  (void)argc; (void)argv;
  p = mini_strdup(msg);
  if (p != realloc_buf) return 11;
  if (strcmp(p, msg) != 0) return 12;
  return 0;
}
