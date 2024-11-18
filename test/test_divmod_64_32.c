#include <unistd.h>

#define assert(x)

#ifndef __WATCOMC__
#  define __watcall __attribute__((regparm(3)))
#endif

typedef unsigned UInt32;
typedef unsigned long long UInt64;

#if defined(__WATCOMC__) && defined(__386__)
  /* Returns *a % b, and sets *a = *a_old / b; */
  static UInt32 __watcall UInt64DivAndGetMod(UInt64 *a, UInt32 b);
#  pragma aux UInt64DivAndGetMod = "xor eax, eax"  "mov edx, [ecx+4]"  "cmp edx, ebx"  "jb L3"  "xchg eax, edx"  "div ebx"  "L3: mov [ecx+4], eax"  "mov eax, [ecx]"  "div ebx"  "mov [ecx], eax" __value [__edx] __parm [__ecx] [__ebx] __modify [__eax]
  /* Returns *a % b, and sets *a = *a_old / b; */
  static UInt32 UInt32DivAndGetMod(UInt32 *a, UInt32 b);
#  pragma aux UInt32DivAndGetMod = "mov eax, [ecx]"  "xor edx, edx"  "div ebx"  "mov [ecx], eax" __value [__edx] __parm [__ecx] [__ebx] __modify [__eax]
#else
#  ifdef __i386__
    /* Returns *a % b, and sets *a = *a_old / b; */
    UInt32 __watcall UInt64DivAndGetMod(UInt64 *a, UInt32 b) {
      /* http://stackoverflow.com/a/41982320/97248 */
      UInt32 upper = ((UInt32*)a)[1], r;
      ((UInt32*)a)[1] = 0;
      if (upper >= b) {
        ((UInt32*)a)[1] = upper / b;
        upper %= b;
      }
      __asm__("divl %2" : "=a" (((UInt32*)a)[0]), "=d" (r) : "rm" (b), "0" (((UInt32*)a)[0]), "1" (upper));
      return r;
    }
    /* Returns *a % b, and sets *a = *a_old / b; */
    UInt32 __watcall UInt32DivAndGetMod(UInt32 *a, UInt32 b) {
      /* gcc-4.4 is smart enough to optimize the / and % to a single divl. */
      const UInt32 r = *a % b;
      *a /= b;
      return r;
    }
#  endif
#endif

/** Returns p + size of formatted output. */
static char *format_u(char *p, unsigned i) {
  char *q = p, *result, c;
  assert(i >= 0);
  do {
    *q++ = '0' + UInt32DivAndGetMod((UInt32*)&i, 10);
  } while (i != 0);
  result = q--;
  while (p < q) {  /* Reverse the string between p and q. */
    c = *p; *p++ = *q; *q-- = c;
  }
  return result;
}

/** Returns p + size of formatted output. */
static char *format_llu(char *p, unsigned long long i) {
  char *q = p, *result, c;
  assert(i >= 0);
  do {
    *q++ = '0' + UInt64DivAndGetMod((UInt64*)&i, 10);
  } while (i != 0);
  result = q--;
  while (p < q) {  /* Reverse the string between p and q. */
    c = *p; *p++ = *q; *q-- = c;
  }
  return result;
}

int main(int argc, char **argv) {
  char buf[sizeof(unsigned long long) * 3 + 1];
  char *p;
  (void)argc; (void)argv;
  p = format_u(buf, 4213567890U);
  *p++ = '\n'; *p++ = '\0';
  (void)!write(1, buf, p - buf);
  p = format_llu(buf, 18432101234567890987ULL);
  *p++ = '\n'; *p = '\0';
  (void)!write(1, buf, p - buf);
  return 0;
}
