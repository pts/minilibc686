#include <stdio.h>

int main(int argc, char **argv) {
  (void)argc; (void)argv;
  fputc('X', fopen("/dev/null", "w"));
  fputc('X', fopen("/dev/null", "w"));
  fputc('X', fopen("/dev/null", "w"));
  fputc('X', fopen("/dev/null", "w"));
  fputc('\n', stderr);
  return 0;
}
