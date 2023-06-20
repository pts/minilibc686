#include <stdio.h>
#include <unistd.h>

int main(int argc, char **argv) {
  char buf[32];
  int n;
  for (;;) {
    n = snprintf(buf, sizeof(buf) - 1, "Hello, %s!\n", argc < 2 ? "World" : argv[1]);
    if (n + 0U < sizeof(buf)) break;
    argc = 0;  /* Fall back to default "World" on buffer overflow. */
  }
  (void)!write(1, buf, n);
  return 0;
}
