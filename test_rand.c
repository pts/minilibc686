#include <stdio.h>

#define RAND_MAX 0x7ffffffff

extern void mini_srand(unsigned s);  /* Function under test. */
extern int mini_rand(void);  /* Function under test. */

/* This is the reference implementation in C. */
static unsigned long long ref_seed;
void ref_srand(unsigned s) { ref_seed = s - 1; }
int ref_rand(void) {
  ref_seed = 6364136223846793005ULL * ref_seed + 1;
  return ref_seed >> 33;
}

extern double mini_log(double x);  /* Function under test. */

int main(int argc, char **argv) {
  int exit_code = 0;
  unsigned u, vr, vm;
  char is_ok;
  (void)argc; (void)argv;
  vr = argc + 42;
  ref_srand(vr);
  mini_srand(vr);
  for (u = 0; u < 10; ++u) {
    vr = ref_rand();
    vm = mini_rand();
    is_ok = vr == vm;
    if (!is_ok) exit_code |= 1;
    printf("is_ok=%d ref_rand()=0x%08x mini_rand()=0x%08x\n", is_ok, vr, vm);
  }
  return exit_code;
}
