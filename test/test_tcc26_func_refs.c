/*
 * test_tcc26_func_refs.c: external function call in code generated by TinyCC (__TINYC__) 0.9.26
 * by pts@fazekas.hu at Thu Jun  6 03:54:15 CEST 2024
 */

#ifdef __WATCOMC__
  extern void *alloca(unsigned long /*size_t*/ __size);
#  pragma aux alloca = "sub esp, eax" "and esp, -4" __parm __nomemory [__eax] __value [__esp] __modify __exact __nomemory [__esp]
  void do_alloca(unsigned u) { int *a = alloca(sizeof(int) * u); (void)a; } 
#else
  void do_alloca(unsigned u) { int a[u]; (void)a; } 
#endif
void do_memset(void) { int a[2] = { 0, }; (void)a; }
struct s { int i, j, k; } do_memcpy(void) { struct s r = { 5, 6, 7 }; return r; };
unsigned long long do___fixunssfdi(float       r) { return r; }
unsigned long long do___fixunsdfdi(double      r) { return r; }
unsigned long long do___fixunsxfdi(long double r) { return r; }
float       do___floatundisf(unsigned long long u) { return u; }
double      do___floatundidf(unsigned long long u) { return u; }
long double do___floatundixf(unsigned long long u) { return u; }
long long do___divdi3(long long a, long long b) { return a / b; }
long long do___moddi3(long long a, long long b) { return a % b; }
unsigned long long do___udivdi3(unsigned long long a, unsigned long long b) { return a / b; }
unsigned long long do___umoddi3(unsigned long long a, unsigned long long b) { return a % b; }
unsigned long long do___lshrdi3(unsigned long long a, unsigned b) { return a >> b; }
long long do___ashrdi3(long long a, unsigned b) { return a >> b; }
unsigned long long do___ashldi3(unsigned long long a, unsigned b) { return a << b; }

int main(int argc, char **argv) {
  (void)argc; (void)argv;
  return 0;
}