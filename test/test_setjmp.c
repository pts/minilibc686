#include <setjmp.h>

static void deep2(jmp_buf env, int i);

static void deep1(jmp_buf env, int i) {
  if (i != 0) deep2(env, i & 0xff);  /* `&' is to prevent tail call optimization. */
}

static void deep2(jmp_buf env, int i) {
  if (i == 0) longjmp(env, 42);
  deep2(env, i - 1);
}

int main(int argc, char **argv) {
  int i;
  jmp_buf env;
  (void)argv;
  if ((i = setjmp(env)) != 0) return i != 42;  /* EXIT_SUCCESS (== 0) iff i == 42. */
  deep1(env, argc + 5);
  return 9;  /* Not reached. */
}
