#ifndef __MINILIBC686__
#  define mini_floor floor
#  define mini_ceil ceil
#endif
double mini_floor(double x);  /* Function under test. */
double mini_ceil(double x);  /* Function under test. */

int signbit(double x) {
  /* return ((const unsigned*)&x)[0] & 0x80000000; */
  /* return ((const char*)&x)[7] & 0x80; */
  return ((const signed char*)&x)[7] < 0;
}

int main(int argc, char **argv) {
  (void)argc; (void)argv;

  if (mini_floor(0.0) != 0.0 || signbit(mini_floor(0.0))) return 11;
  if (mini_floor(-0.0) != -0.0 || signbit(mini_floor(0.0))) return 12;
  if (mini_floor(0.25) != 0.0 || signbit(mini_floor(0.0))) return 13;
  if (mini_floor(-0.25) != -1.0) return 14;
  if (mini_floor(0.75) != 0.0 || signbit(mini_floor(0.0))) return 15;
  if (mini_floor(-0.75) != -1.0) return 16;
  if (mini_floor(42.0) != 42.0) return 17;
  if (mini_floor(42.25) != 42.0) return 18;
  if (mini_floor(-42.25) != -43.0) return 19;

  if (mini_ceil(0.0) != 0.0 || signbit(mini_ceil(0.0))) return 31;
  if (mini_ceil(-0.0) != -0.0 || signbit(mini_ceil(0.0))) return 32;
  if (mini_ceil(0.25) != 1.0 || signbit(mini_ceil(0.0))) return 33;
  if (mini_ceil(-0.25) != -0.0 || !signbit(mini_ceil(-0.25))) return 34;
  if (mini_ceil(0.75) != 1.0) return 35;
  if (mini_ceil(-0.75) != -0.0 || !signbit(mini_ceil(-0.25))) return 36;
  if (mini_ceil(42.0) != 42.0) return 37;
  if (mini_ceil(42.25) != 43.0) return 38;
  if (mini_ceil(-42.25) != -42.0) return 39;

  if (mini_floor(-42.25) != -43.0) return 9;  /* Verify that the rounding mode hsa been switched back. */

  return 0;
}
