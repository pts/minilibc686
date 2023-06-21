#define NULL ((void*)0)

int sprintf(char *str, const char *format, ...);

double mul3(double x) { return 3 * x; }
unsigned divbig(unsigned x) { return x / 0x01234567; }  /* This doesn't put anything to CONST. */
unsigned myswitch(unsigned x) {  /* This puts the switch table to CODE (not CONST). */
  switch (x) {
   case 1: case 11: return 11;
   case 2: case 12: return 22;
   case 3: case 13: return 33;
   case 4: case 14: return 44;
   case 5: case 15: return 55;
   case 6: case 16: return 66;
   case 7: case 17: return 77;
   case 8: case 18: return 88;
   case 9: case 19: return 99;
   default: return 0;
  }
}

int main(int argc, char **argv) {
  (void)argc; (void)argv;
  return sprintf(NULL, "%s=%s", "World", "World");
}
