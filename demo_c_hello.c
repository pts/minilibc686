#include <stdio.h>

int main(int argc, char **argv) {
  printf("Hello, %s!\n", argc < 2 ? "World" : argv[1]);
  return 0;
}
