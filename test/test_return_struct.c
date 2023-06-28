typedef struct c1 { char a[1]; } c1;
c1 fc1(void) { c1 c; c.a[0] = 42; return c; }
c1 mini___M_test_fc1(void);  /* Function under test. */
char call_fc1(void) { c1 c = fc1(); return c.a[0]; }
char call_tfc1(void) { c1 c = mini___M_test_fc1(); return c.a[0]; }

typedef struct c9 { char a[9]; } c9;
c9 fc9(void) { c9 c; c.a[1] = 11; c.a[8] = 88; return c; }
char call_fc9(void) { c9 c = fc9(); return c.a[1] - c.a[8]; }
c9 mini___M_test_fc9(void);  /* Function under test. */
char call_tfc9(void) { c9 c = mini___M_test_fc9(); return c.a[1] - c.a[8]; }

int main(int argc, char **argv) {
  (void)argc; (void)argv;
  if (call_fc1()  != 42) return 1;
  if (call_tfc1() != 42) return 2;
  if (call_fc9()  != 11 - 88) return 3;
  if (call_tfc9() != 11 - 88) return 4;
  return 0;
}
