double mini_pow(double x, double y);

int main(int argc, char **argv) {
  int i;
  (void)argc; (void)argv;
  if (mini_pow(0.0, 1234.5678) != 0.0) return 11;
  if (mini_pow(1.0, 1234.5678) != 1.0) return 12;
  if (mini_pow(3.0, 5.0) != 243.0) return 13;
  if (mini_pow(-3.0, 5.0) != -243.0) return 14;
  if (mini_pow(3.0, 6.0) != 729.0) return 15;
  if (mini_pow(-3.0, 6.0) != 729.0) return 16;
  if (mini_pow(0.75, 0.5) != 0.8660254037844386) return 17;
  if (mini_pow(765.4321, 98.765) != 6.745938738339548e+284) return 18;
  return 0;
}
