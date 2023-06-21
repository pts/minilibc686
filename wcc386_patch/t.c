#define NULL ((void*)0)

int sprintf(char *str, const char *format, ...);

double mul3(double x) { return 3 * x; }

int main(int argc, char **argv) {
  (void)argc; (void)argv;
  return sprintf(NULL, "%s=%s", "World", "World");
}
