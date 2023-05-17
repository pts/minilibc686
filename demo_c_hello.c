extern int mini_printf(const char *format, ...);

int main(int argc, char **argv) {
  mini_printf("Hello, %s!\n", argc < 2 ? "World" : argv[1]);
  return 0;
}
