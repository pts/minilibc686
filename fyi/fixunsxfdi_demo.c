#if 0
#include <stdio.h>
#else
extern int printf(const char *format, ...);
#endif

extern long double getld1(void);
extern long double getld2(void);
extern unsigned long long __fixunsxfdi(long double a);

int main(int argc, char **argv) {
  (void)argc; (void)argv;
  printf("%llu\n", (unsigned long long)getld1());  /* : 123456. */
  printf("%llu\n", (unsigned long long)getld2());  /* : 0. */
  printf("%llu\n", __fixunsxfdi(18446744073709551615.0L));  /* 18446744073709551615 */
  printf("%llu\n", __fixunsxfdi(18446744073709551616.0L));  /* 0 */
  return 0;  
}
