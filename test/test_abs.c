#ifndef __MINILIBC686__
#  define mini_abs abs
#  define mini_labs labs
#  define mini_llabs llabs
#endif

int mini_abs(int x);
long mini_labs(long x);
long long int mini_llabs(long long x);

int main(int argc, char **argv) {
  (void)argc; (void)argv;

  if (mini_abs(0) != 0) return 11;
  if (mini_abs(42) != 42) return 12;
  if (mini_abs(-42) != 42) return 12;
  if (sizeof(int) == 4) {
    if (mini_abs(0x7fffffff) != 0x7fffffff) return 13;
    if (mini_abs(-0x7fffffff) != 0x7fffffff) return 14;
    if (mini_abs(-0x80000000) != (int)-0x80000000) return 15;
  } else if (sizeof(int) == 2) {
    if (mini_abs(0x7fff) != 0x7fff) return 13;
    if (mini_abs(-0x7fff) != 0x7fff) return 14;
    if (mini_abs(-0x8000) != (int)-0x8000) return 15;
  }
  if (mini_abs(-(1U << (sizeof(int) * 8 - 1))) != (int)-(1U << (sizeof(int) * 8 - 1))) return 16;
  if (mini_abs(-1U - (1U << (sizeof(int) * 8 - 1))) != (int)(-1U - (1U << (sizeof(int) * 8 - 1)))) return 16;
  if (mini_abs(1U - (1U << (sizeof(int) * 8 - 1))) != (int)(-1U - (1U << (sizeof(int) * 8 - 1)))) return 17;

  if (mini_labs(0L) != 0L) return 21;
  if (mini_labs(42L) != 42L) return 22;
  if (mini_labs(-42L) != 42L) return 22;
  if (mini_labs(0x7fffffffL) != 0x7fffffffL) return 23;
  if (mini_labs(-0x7fffffffL) != 0x7fffffffL) return 24;
  if (mini_labs(-0x80000000L) != (long)-0x80000000L) return 25;
  if (mini_labs(-(1UL << (sizeof(long) * 8 - 1))) != (long)-(1UL << (sizeof(long) * 8 - 1))) return 26;
  if (mini_labs(-1UL - (1UL << (sizeof(long) * 8 - 1))) != (long)(-1UL - (1UL << (sizeof(long) * 8 - 1)))) return 26;
  if (mini_labs(1UL - (1UL << (sizeof(long) * 8 - 1))) != (long)(-1UL - (1UL << (sizeof(long) * 8 - 1)))) return 27;
  if (mini_labs( 1L << (sizeof(long long) * 8 - 5)) != 1L << (sizeof(long long) * 8 - 5)) return 28;
  if (mini_labs(-1L << (sizeof(long long) * 8 - 5)) != 1L << (sizeof(long long) * 8 - 5)) return 29;

  if (mini_llabs(0LL) != 0LL) return 21;
  if (mini_llabs(42LL) != 42LL) return 22;
  if (mini_llabs(-42LL) != 42LL) return 22;
  if (mini_llabs(0x7fffffffLL) != 0x7fffffffLL) return 23;
  if (mini_llabs(-0x7fffffffLL) != 0x7fffffffLL) return 24;
  if (mini_llabs(-0x80000000LL) != (sizeof(long long) > 4 ? (long long)0x80000000LL : (long long)-0x80000000LL)) return 25;
  if (mini_llabs(-(1ULL << (sizeof(long long) * 8 - 1))) != (long long)-(1ULL << (sizeof(long long) * 8 - 1))) return 26;
  if (mini_llabs(-1ULL - (1ULL << (sizeof(long long) * 8 - 1))) != (long long)(-1ULL - (1ULL << (sizeof(long long) * 8 - 1)))) return 26;
  if (mini_llabs( 1ULL - (1ULL << (sizeof(long long) * 8 - 1))) != (long long)(-1ULL - (1ULL << (sizeof(long long) * 8 - 1)))) return 27;
  if (mini_llabs( 1LL << (sizeof(long long) * 8 - 5)) != 1LL << (sizeof(long long) * 8 - 5)) return 28;
  if (mini_llabs(-1LL << (sizeof(long long) * 8 - 5)) != 1LL << (sizeof(long long) * 8 - 5)) return 29;

  return 0;
}
