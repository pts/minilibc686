/* Returning a struct generates a reference to memcpy(3) in TinyCC 0.9.26. */

struct s { int a, b, c, d; };

static struct s rs(void) { struct s s = { 5, 6, 7, 8 }; return s; }

int main(int argc, char **argv) {
  struct s s = rs();
  (void)argc; (void)argv;
  return !(s.a == 5 && s.b == 6 && s.c == 7 && s.d == 8);
}
