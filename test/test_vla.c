/* Creating a variable-length array reference to alloca(3) in TinyCC 0.9.26. */

static unsigned adda(const int *a0, unsigned n) {
  unsigned i, r;
  int a[n];
  for (i = 0; i < n; ++i) {
    a[i] = a0[i];
  }
  for (i = 0, r = 0; i < n; ++i) {
    r += i & 1 ? -a[i] : a[i];
  }
  return r;
}

static int a0[] = { 5, 6, 7, 9, 8, 11, 12, 16 };

int main(int argc, char **argv) {
  (void)argc; (void)argv;
  return !(adda(a0, sizeof(a0) / sizeof(a0[0])) == -10U);
}
