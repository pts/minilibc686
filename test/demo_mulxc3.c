int main(int argc, char **argv) {
  (void)argv;
  /* This returns `argc * argc', and uses `long double _Complex' multiplication. */
  return (__imag__ ((argc + 0.iL) * (argc * 1.iL))) + 0.5;
}
