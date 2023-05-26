#include <stdio.h>

extern double mini_log(double x);  /* Function under test. */

int main(int argc, char **argv) {
  (void)argc; (void)argv;
  /*const double log42_exp = 3.73766961828337;*/  /* Bad, Perl log(42). */
  const double log42_exp = 3.7376696182833684;
  const double log42 = mini_log(42);
  const char is_ok = log42 == log42_exp;
  printf("is_ok=%d log42_exp=%.17g log42=%.17g\n", is_ok, log42_exp, log42);
  if (!is_ok) return 1;
  return 0;
}
