/* Filling a local array generates a reference to memset(3) in TinyCC 0.9.26. */

static int f1(int base) {
  int a[] = { 5, 6, 7, 8, 9, 10, 11, 12 };
  return base + a[0] + a[1] + a[2] + a[3] + a[4] + a[5] + a[6] + a[7];
}

static int f2(int base) {
  int a[8] = { 0, };
  return base + (a[0] | a[1] | a[2] | a[3] | a[4] | a[5] | a[6] | a[7]);
}

int main(int argc, char **argv) {
  int v1, v2;
  (void)argc; (void)argv;
  v1 = f1(100);
  v2 = f2(v1);
  return !(v1 == 168 && v2 == 168);
}
