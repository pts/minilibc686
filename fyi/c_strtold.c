/* Based on musl-1.2.5/src/locale/strtod_l.c */

#if defined(USE_MINILIBC) && defined(__i386__)
#  define EINVAL 22
#  define ERANGE 34
  extern int mini_errno;
#  define errno mini_errno
  typedef unsigned size_t;
  typedef unsigned uint32_t;
  typedef int int32_t;
  typedef unsigned long long uint64_t;
#else
#  include <errno.h>
#  include <float.h>  /* FLT_MIN etc. */
#  include <stddef.h>  /* size_t. */
#  include <stdint.h>  /* uint32_t, int32_t. */
#endif


#ifdef FORCE_UNDEF
#  undef LDBL_MAX
#  undef __LDBL_MAX__
#  undef LDBL_MIN
#  undef __LDBL_MIN__
#  undef LDBL_EPSILON
#  undef __LDBL_EPSILON__
#  undef DBL_MIN
#  undef __DBL_MIN__
#endif

/*#ifdef __MINILIBC686__
static __inline__*/
/* !! It produces incorrect results __PCC__. __TINYCC_ has: error: unknown constraint 't' */
#if defined(__i386__) && defined(__GNUC__) && !defined(__PCC__) && !defined(__TINYC__)
static __attribute__((noinline)) long double my_ldexpl(long double x, int exp) {
  register long double result;
  __asm__ __volatile__ ("fscale" : "=t" (result) : "0" (x), "u" ((long double) exp));
  return result;
}

static __inline__ __attribute__((always_inline)) long double my_fabsl(long double x) {
  register long double result;
  __asm__ __volatile__ ("fabs" : "=t" (result) : "0" (x));
  return result;
}

static __attribute__((noinline)) long double my_fmodl(long double x, long double y) {  /* TODO(pts): Is it smaller without __inline__. */
  register long double value;
  __asm__ __volatile__ ("M1: fprem\n\t" "fnstsw %%ax\n\t" "sahf\n\t" "jp M1" : "=t" (value) : "0" (x), "u" (y) : "ax", "cc");
  return value;
}
#define INFINITY  (__builtin_inff())
#define NAN (__builtin_nan(""))
#else
#if defined(__amd64__) && defined(__GNUC__) && !defined(__PCC__) && !defined(__TINYC__)
static __inline__ long double my_ldexpl(long double x, int exp) {
  register long double result;
  __asm__ __volatile__ ("fscale" : "=t"(result) : "0"(x), "u"((long double) exp));
  return result;
}
static __inline__ long double my_fabsl(long double x) {
  __asm__ __volatile__ ("fabs" : "+t"(x));
  return x;
}
static __inline__ long double my_fmodl(long double x, long double y) {
  unsigned short fpsr;
  do __asm__ __volatile__ ("fprem; fnstsw %%ax" : "+t"(x), "=a"(fpsr) : "u"(y));
  while (fpsr & 0x400);
  return x;
}
#define INFINITY  (__builtin_inff())
#define NAN (__builtin_nan(""))
#else
#include <math.h>  /* NAN, INFINITY, ldexpl(...), fabsl(...), fmodl(...). */
long double ldexpl(long double x, int exp);
long double fmodl(long double x, long double y);
long double fabsl(long double x);
#define my_ldexpl(x, exp) ldexpl(x, exp)
#define my_fabsl(x) fabsl(x)
#define my_fmodl(x, y) fmodl(x, y)
#endif
#endif

#if defined(__i386__) && !defined(__LDBL_MANT_DIG__)
#  define __LDBL_MANT_DIG__ 64
#endif
#if defined(__i386__) && !defined(LDBL_MANT_DIG)
#  define LDBL_MANT_DIG __LDBL_MANT_DIG__
#endif
#if defined(__i386__) && !defined(__LDBL_MIN_EXP__)
#  define __LDBL_MIN_EXP__ (-16381)
#endif
#if defined(__i386__) && !defined(LDBL_MIN_EXP)
#  define LDBL_MIN_EXP __LDBL_MIN_EXP__
#endif
#if defined(__i386__) && !defined(__LDBL_MAX_EXP__)
#  define __LDBL_MAX_EXP__ 16384
#endif
#if defined(__i386__) && !defined(LDBL_MAX_EXP)
#  define LDBL_MAX_EXP __LDBL_MAX_EXP__
#endif
#if defined(__i386__) && !defined(__LDBL_MAX__)
#  define __LDBL_MAX__ 1.1897314953572317650e+4932L  /* 1.18973149535723176502126385303097021e+4932L */
#endif
#if defined(__i386__) && !defined(LDBL_MAX)
#  define LDBL_MAX __LDBL_MAX__
#endif
#if defined(__i386__) && !defined(__LDBL_MIN__)
#  define __LDBL_MIN__ 3.3621031431120935062e-4932L  /* 3.36210314311209350626267781732175260e-4932L */
#endif
#if defined(__i386__) && !defined(LDBL_MIN)
#  define LDBL_MIN __LDBL_MIN__
#endif
#if defined(__i386__) && !defined(__LDBL_EPSILON__)
#  define __LDBL_EPSILON__ 1.0842021724855044340e-19L  /* 1.08420217248550443400745280086994171e-19L */
#endif
#if defined(__i386__) && !defined(LDBL_EPSILON)
#  define LDBL_EPSILON __LDBL_EPSILON__
#endif
#if defined(__i386__) && !defined(__DBL_MIN__)
#  define __DBL_MIN__ 2.2250738585072014e-308  /* Fewer digits is not enough. */
#endif
#if defined(__i386__) && !defined(DBL_MIN)
#  define DBL_MIN __DBL_MIN__
#endif

#if LDBL_MANT_DIG == 53 && LDBL_MAX_EXP == 1024

#define LD_B1B_DIG 2
#define LD_B1B_MAX 9007199, 254740991
#define KMAX 128

#elif LDBL_MANT_DIG == 64 && LDBL_MAX_EXP == 16384

#define LD_B1B_DIG 3
#define LD_B1B_MAX 18, 446744073, 709551615
#define KMAX 2048

#elif LDBL_MANT_DIG == 113 && LDBL_MAX_EXP == 16384

#define LD_B1B_DIG 4
#define LD_B1B_MAX 10384593, 717069655, 257060992, 658440191
#define KMAX 2048

#else
#error Unsupported long double representation
#endif

#define MASK (KMAX-1)

#define MY_LLONG_MAX (long long)(-1ULL >> 1)
#define MY_LLONG_MIN (long long)(1ULL << (sizeof(unsigned long long) - 1))
#define MY_INT_MAX (int)(-1U >> 1)

struct sfile {
  const char *p;
  const char *p0;
};
#define shunget(f) (--(f)->p)
#define shgetc(f) (*(f)->p++)

static int32_t scanexp(struct sfile *f) {
	unsigned char c;
	uint32_t x;
	int neg = 0;
	
	c = shgetc(f);
	if (c=='+' || c=='-') {
		neg = (c=='-');
		c = shgetc(f);
		if (c-'0'+0U>=10U) shunget(f);  /* Unget the sign character. */
	}
	if (c-'0'+0U>=10U) {
		shunget(f);  /* Unget the digit. */
		shunget(f);  /* Unget the 'e'. */
		return 0;
	}
	for (x=0; c-'0'+0U<10U && x<0x7fffffff/10; c = shgetc(f))
		x = 10*x + c-'0';
	for (; c-'0'+0U<10U; c = shgetc(f));
	shunget(f);
	return neg ? -x : x;
}

#define EMIN (LDBL_MIN_EXP-LDBL_MANT_DIG)
#define EMAX (-LDBL_MIN_EXP+3)

static long double decfloat(struct sfile *f, int c, int sign) {
	int bits = LDBL_MANT_DIG;
	uint32_t x[KMAX];
	static const uint32_t th[] = { LD_B1B_MAX };
	int i, j, k, a, z;
	long long lrp=0, dc=0;
	int lnz = 0;
	int gotdig = 0, gotrad = 0;
	int rp;
	uint32_t e2;
	int denormal = 0;
	long double y;
	long double frac=0;
	long double bias=0;
	static const int32_t p10s[] = { 10, 100, 1000, 10000, 100000, 1000000, 10000000, 100000000 };

	j=0;
	k=0;

	/* Don't let leading zeros consume buffer space */
	for (; c=='0'; c = shgetc(f)) gotdig=1;
	if (c=='.') {
		gotrad = 1;
		for (c = shgetc(f); c=='0'; c = shgetc(f)) gotdig=1, lrp--;
	}

	x[0] = 0;
	for (; c-'0'+0U<10U || c=='.'; c = shgetc(f)) {
		if (c == '.') {
			if (gotrad) break;
			gotrad = 1;
			lrp = dc;
		} else if (k < KMAX-3) {
			dc++;
			if (c!='0') lnz = dc;
			if (j) x[k] = x[k]*10 + c-'0';
			else x[k] = c-'0';
			if (++j==9) {
				k++;
				j=0;
			}
			gotdig=1;
		} else {
			dc++;
			if (c!='0') {
				lnz = (KMAX-4)*9;
				x[KMAX-4] |= 1;
			}
		}
	}
	if (!gotrad) lrp=dc;

	if (gotdig && (c|32)=='e') {
		lrp += scanexp(f);
	} else if (c>=0) {
		shunget(f);
	}
	if (!gotdig) {
		errno = EINVAL;
		f->p = f->p0;
		return 0;
	}

	/* Handle zero specially to avoid nasty special cases later */
	if (!x[0]) return sign * 0.0;

	/* Optimize small integers (w/no exponent) and over/under-flow */
	if (lrp==dc && dc<10 && (bits>30 || x[0]>>bits==0))
		return sign * (long double)x[0];
	if (lrp > -EMIN/2) { do_inf:
		errno = ERANGE;
		return sign * LDBL_MAX * LDBL_MAX;
	}
	if (lrp < EMIN-2*LDBL_MANT_DIG) {
		errno = ERANGE;
		return sign * LDBL_MIN * LDBL_MIN;
	}

	/* Align incomplete final B1B digit */
	if (j) {
		for (; j<9; j++) x[k]*=10;
		k++;
		j=0;
	}

	a = 0;
	z = k;
	e2 = 0;
	rp = lrp;

	/* Optimize small to mid-size integers (even in exp. notation) */
	if (lnz<9 && lnz<=rp && rp < 18) {
		if (rp == 9) return sign * (long double)x[0];
		if (rp < 9) return sign * (long double)x[0] / p10s[8-rp];
		int bitlim = bits-3*(int)(rp-9);
		if (bitlim>30 || x[0]>>bitlim==0)
			return sign * (long double)x[0] * p10s[rp-10];
	}

	/* Drop trailing zeros */
	for (; !x[z-1]; z--);

	/* Align radix point to B1B digit boundary */
	if (rp % 9) {
		int rpm9 = rp>=0 ? rp%9 : rp%9+9;
		int p10 = p10s[8-rpm9];
		uint32_t carry = 0;
		for (k=a; k!=z; k++) {
			uint32_t tmp = x[k] % p10;
			x[k] = x[k]/p10 + carry;
			carry = 1000000000/p10 * tmp;
			if (k==a && !x[k]) {
				a = (a+1 & MASK);
				rp -= 9;
			}
		}
		if (carry) x[z++] = carry;
		rp += 9-rpm9;
	}

	/* Upscale until desired number of bits are left of radix point */
	while (rp < 9*LD_B1B_DIG || (rp == 9*LD_B1B_DIG && x[a]<th[0])) {
		uint32_t carry = 0;
		e2 -= 29;
		for (k=(z-1 & MASK); ; k=(k-1 & MASK)) {
			uint64_t tmp = ((uint64_t)x[k] << 29) + carry;
			if (tmp > 1000000000) {  /* TODO(pts): Shouldn't this be `>='? Is this a bug? */
#if defined(__i386__) && (defined(__GNUC__) || defined(__TINYC__))  /* tmp <= 2305843010982666050, the result never overflows. */
				__asm__ __volatile__("divl %4" : "=a"(carry), "=d"(x[k]) : "0"((uint32_t)tmp), "1"((uint32_t)(tmp >> 32)), "rm"(1000000000) : "cc");
#else
				carry = tmp / 1000000000;  /* <= 2305843010. */
				x[k] = tmp % 1000000000;
#endif
			} else {
				carry = 0;
				x[k] = tmp;
			}
			if (k==(z-1 & MASK) && k!=a && !x[k]) z = k;
			if (k==a) break;
		}
		if (carry) {
			rp += 9;
			a = (a-1 & MASK);
			if (a == z) {
				z = (z-1 & MASK);
				x[z-1 & MASK] |= x[z];
			}
			x[a] = carry;
		}
	}

	/* Downscale until exactly number of bits are left of radix point */
	for (;;) {
		uint32_t carry = 0;
		int sh = 1;
		for (i=0; i<LD_B1B_DIG; i++) {
			k = (a+i & MASK);
			if (k == z || x[k] < th[i]) {
				i=LD_B1B_DIG;
				break;
			}
			if (x[a+i & MASK] > th[i]) break;
		}
		if (i==LD_B1B_DIG && rp==9*LD_B1B_DIG) break;
		/* FIXME: find a way to compute optimal sh */
		if (rp > 9+9*LD_B1B_DIG) sh = 9;
		e2 += sh;
		for (k=a; k!=z; k=(k+1 & MASK)) {
			uint32_t tmp = x[k] & (1<<sh)-1;
			x[k] = (x[k]>>sh) + carry;
			carry = (1000000000>>sh) * tmp;
			if (k==a && !x[k]) {
				a = (a+1 & MASK);
				i--;
				rp -= 9;
			}
		}
		if (carry) {
			if ((z+1 & MASK) != a) {
				x[z] = carry;
				z = (z+1 & MASK);
			} else x[z-1 & MASK] |= 1;
		}
	}

	/* Assemble desired bits into floating point variable */
	for (y=i=0; i<LD_B1B_DIG; i++) {
		if ((a+i & MASK)==z) x[(z=(z+1 & MASK))-1] = 0;
		y = 1000000000.0L * y + x[a+i & MASK];
	}

	y *= sign;

	/* Limit precision for denormal results */
	if (bits > (int32_t)(LDBL_MANT_DIG+e2-EMIN)) {
		bits = LDBL_MANT_DIG+e2-EMIN;
		if (bits<0) bits=0;
		denormal = 1;
	}

	/* Calculate bias term to force rounding, move out lower bits */
	if (bits < LDBL_MANT_DIG) {
		bias = my_ldexpl(1, 2*LDBL_MANT_DIG-bits-1);
		if (sign < 0) bias = -bias;
		frac = my_fmodl(y, my_ldexpl(1, LDBL_MANT_DIG-bits));
		y -= frac;
		y += bias;
	}

	/* Process tail of decimal input so it can affect rounding */
	if ((a+i & MASK) != z) {
		uint32_t t = x[a+i & MASK];
		if (t < 500000000 && (t || (a+i+1 & MASK) != z))
			frac += 0.25*sign;
		else if (t > 500000000)
			frac += 0.75*sign;
		else if (t == 500000000) {
			if ((a+i+1 & MASK) == z)
				frac += 0.5*sign;
			else
				frac += 0.75*sign;
		}
		if (LDBL_MANT_DIG-bits >= 2 && !my_fmodl(frac, 1))
			frac++;
	}

	y += frac;
	y -= bias;

	if ((int32_t)(e2+LDBL_MANT_DIG) > EMAX-5) {  /* Exponent is too large. */
		if (my_fabsl(y) >= 2/LDBL_EPSILON) {
			if (denormal && bits==(int32_t)(LDBL_MANT_DIG+e2-EMIN))
				denormal = 0;
			y *= 0.5;
			e2++;
		}
		if ((int32_t)(e2+LDBL_MANT_DIG)>EMAX || (denormal && frac)) {
			goto do_inf;
		}
	}

	return my_ldexpl(y, e2);
}

static long double hexfloat(struct sfile *f, int sign) {
	int bits = LDBL_MANT_DIG;
	uint32_t x = 0;
	long double y = 0;
	long double scale = 1;
	long double bias = 0;
	int gottail = 0, gotrad = 0, gotdig = 0;
	long long rp = 0;  /* TODO(pts): int32_t. */
	long long dc = 0;
	long long e2 = 0;  /* TODO(pts): int32_t. Check for overflow in rp and e2. */
	int d;
	int c;

	c = shgetc(f);

	/* Skip leading zeros */
	for (; c=='0'; c = shgetc(f)) gotdig = 1;

	if (c=='.') {
		gotrad = 1;
		c = shgetc(f);
		/* Count zeros after the radix point before significand */
		for (rp=0; c=='0'; c = shgetc(f), rp--) gotdig = 1;
	}

	for (; c-'0'+0U<10U || (c|32)-'a'+0U<6U || c=='.'; c = shgetc(f)) {
		if (c=='.') {
			if (gotrad) break;
			rp = dc;
			gotrad = 1;
		} else {
			gotdig = 1;
			if (c > '9') d = (c|32)+10-'a';
			else d = c-'0';
			if (dc<8) {
				x = x*16 + d;
			} else if (dc < LDBL_MANT_DIG/4+1) {
				y += d*(scale/=16);
			} else if (d && !gottail) {
				y += 0.5*scale;
				gottail = 1;
			}
			dc++;
		}
	}
	if (!gotdig) {
		shunget(f);
		shunget(f);
		if (gotrad) shunget(f);
		return sign * 0.0;
	}
	if (!gotrad) rp = dc;
	while (dc<8) x *= 16, dc++;
	if ((c|32)=='p') {
		e2 = scanexp(f);
	} else {
		shunget(f);
	}
	e2 += 4*rp - 32;

	if (!x) return sign * 0.0;
	if (e2 > -EMIN) {
		errno = ERANGE;
		return sign * LDBL_MAX * LDBL_MAX;
	}
	if (e2 < EMIN-2*LDBL_MANT_DIG) {
		errno = ERANGE;
		return sign * LDBL_MIN * LDBL_MIN;
	}

	while (x < 0x80000000) {
		if (y>=0.5) {
			x += x + 1;
			y += y - 1;
		} else {
			x += x;
			y += y;
		}
		e2--;
	}

	if (bits > 32+e2-EMIN) {
		bits = 32+e2-EMIN;
		if (bits<0) bits=0;
	}

	if (bits < LDBL_MANT_DIG) {  /* TODO(pts): How can this happen? I have bits == 64 for all long double values I could come up with. */
		bias = my_ldexpl(1, 32+LDBL_MANT_DIG-bits-1);
		if (sign < 0) bias = -bias;
	}

	if (bits<32 && y && !(x&1)) x++, y=0;

	y = bias + sign*(long double)x + sign*y;
	y -= bias;

	if (y) {
		y = my_ldexpl(y, e2);
	} else {
		errno = ERANGE;
	}
	return y;
}

long double mini_strtold(const char *s, char **p) {
	struct sfile f = { s, s };
	long double y;
	int sign = 1;
	size_t i;
	int c;

	while ((c = shgetc(&f)) == ' ' || c-'\t'+0U <= '\r'-'\t'+0U) {}  /* isspace(...); */

	if (c=='+' || c=='-') {
		if (c == '-') sign = -1;
		c = shgetc(&f);
	}

	for (i=0; i<8 && (c|32)=="infinity"[i]; i++)  /* !! Smarter parsing. */
		if (i<7) c = shgetc(&f);
	if (i==3 || i==8 || (i>3)) {
		if (i!=8) {
			shunget(&f);
			for (; i>3; i--) shunget(&f);
		}
		y = sign * INFINITY;
		goto done;
	}
	if (!i) for (i=0; i<3 && (c|32)=="nan"[i]; i++)
		if (i<2) c = shgetc(&f);
	if (i==3) {
		if (shgetc(&f) != '(') {
			shunget(&f);
			goto do_nan;
		} else {
			for (i=1; ; i++) {
				c = shgetc(&f);
				if (c-'0'+0U<10U || c-'A'+0U<26U || c-'a'+0U<26U || c=='_')
					continue;
				if (c==')') break;
				shunget(&f);
				while (i--) shunget(&f);
				break;
			}
		}
	      do_nan:
		y = NAN;
		goto done;
	}

	if (i) {
		shunget(&f);
		errno = EINVAL;
		f.p = f.p0;
		y = 0;
		goto done;
	}

	if (c=='0') {
		c = shgetc(&f);
		if ((c|32) != 'x') {
			shunget(&f);
			c = '0';
			goto do_dec;
		}
		y = hexfloat(&f, sign);
	} else { do_dec:
		y = decfloat(&f, c, sign);
	}
      done:
	if (p) *p = (char*)f.p;
	return y;
}

/* --- */

#ifdef USE_LIBC_STRTOLD
long double strtold(const char *nptr, char **endptr);
#define my_strtold strtold
#endif

#ifdef DO_MAIN_TEST
#include <stdio.h>

int signbitlp(const long double *ld) {  /* !! Must return int, not char. */
  return ((const unsigned char*)ld)[9] >> 7;
}

/*#define my_signbit(ld) signbit((long double)ld)*/  /* signbitlp(&(ld)) */
#define my_signbit(ld) signbitlp(&(ld))

float fadd2(long double a, long double b) {
  return a + b;
}

int main(int argc, char **argv) {
  /*const char is_ok = (long double)DBL_MIN == 2.22507385850720138309e-308l;*/
  union { unsigned u[3]; long double ld; } x;
  char is_ok, is_all_ok = 1;
  (void)argc; (void)argv;
  x.u[2] = 0;

  x.ld = (double)LDBL_MIN;
  is_all_ok &= (is_ok = x.ld == 0.0L);
  printf("is_ok=%d u0=0x%x u1=0x%x u2=0x%x\n", is_ok, x.u[0], x.u[1], x.u[2] & 0xffff);

  x.ld = (float)1.000000000000001L;
  is_all_ok &= (is_ok = x.ld == 1.0L);
  printf("is_ok=%d u0=0x%x u1=0x%x u2=0x%x\n", is_ok, x.u[0], x.u[1], x.u[2] & 0xffff);

  x.ld = fadd2(1, 1.000000000000001L);
  is_all_ok &= (is_ok = x.ld == 2.0L);  /* !! TCC bug. GCC and PCC work file. */
  printf("is_ok=%d u0=0x%x u1=0x%x u2=0x%x\n", is_ok, x.u[0], x.u[1], x.u[2] & 0xffff);

  x.ld = my_strtold("2.22507385850720138309e-308", 0);
  is_all_ok &= (is_ok = x.ld == (long double)DBL_MIN && x.ld == DBL_MIN && (double)x.ld == DBL_MIN);
  printf("is_ok=%d u0=0x%x u1=0x%x u2=0x%x\n", is_ok, x.u[0], x.u[1], x.u[2] & 0xffff);

  x.ld = my_strtold("2.2250738585072014e-308", 0);
  is_all_ok &= (is_ok = (double)x.ld == DBL_MIN && x.ld > (long double)DBL_MIN && x.u[0] == 0x46 && x.u[1] == 0x80000000U && (x.u[2] & 0xffff) == 0x3c01);
  printf("is_ok=%d u0=0x%x u1=0x%x u2=0x%x\n", is_ok, x.u[0], x.u[1], x.u[2] & 0xffff);

  x.ld = my_strtold("inf", 0);
  is_all_ok &= (is_ok = x.ld > 0.0L && x.ld > LDBL_MAX && x.ld == x.ld * .5);
  printf("is_ok=%d u0=0x%x u1=0x%x u2=0x%x\n", is_ok, x.u[0], x.u[1], x.u[2] & 0xffff);

  x.ld = my_strtold("infinity", 0);
  is_all_ok &= (is_ok = x.ld > 0.0L && x.ld > LDBL_MAX && x.ld == x.ld * .5);
  printf("is_ok=%d u0=0x%x u1=0x%x u2=0x%x\n", is_ok, x.u[0], x.u[1], x.u[2] & 0xffff);

  x.ld = my_strtold("-infinity", 0);
  is_all_ok &= (is_ok = x.ld < 0.0L && x.ld < -LDBL_MAX && x.ld == x.ld * .5);
  printf("is_ok=%d u0=0x%x u1=0x%x u2=0x%x\n", is_ok, x.u[0], x.u[1], x.u[2] & 0xffff);

  x.ld = my_strtold("1.18973149535723176502126385303097021e+4932", 0);
  is_all_ok &= (is_ok = x.ld == LDBL_MAX);
  printf("is_ok=%d u0=0x%x u1=0x%x u2=0x%x\n", is_ok, x.u[0], x.u[1], x.u[2] & 0xffff);

  x.ld = my_strtold("1.189731495357231765e+4932", 0);
  is_all_ok &= (is_ok = x.ld == LDBL_MAX);
  printf("is_ok=%d u0=0x%x u1=0x%x u2=0x%x\n", is_ok, x.u[0], x.u[1], x.u[2] & 0xffff);

  x.ld = my_strtold("1.1897314953572317650E4932", 0);
  is_all_ok &= (is_ok = x.ld == LDBL_MAX);
  printf("is_ok=%d u0=0x%x u1=0x%x u2=0x%x\n", is_ok, x.u[0], x.u[1], x.u[2] & 0xffff);

  x.ld = my_strtold("1.18973149535723176498902e+4932", 0);
  is_all_ok &= (is_ok = x.ld == LDBL_MAX);
  printf("is_ok=%d u0=0x%x u1=0x%x u2=0x%x\n", is_ok, x.u[0], x.u[1], x.u[2] & 0xffff);

  x.ld = my_strtold("1.18973149535723176498901e+4932", 0);
  is_all_ok &= (is_ok = x.ld > 0.0L && x.ld < LDBL_MAX);
  printf("is_ok=%d u0=0x%x u1=0x%x u2=0x%x\n", is_ok, x.u[0], x.u[1], x.u[2] & 0xffff);

  x.ld = my_strtold("1.189731495357231766e+4932", 0);
  is_all_ok &= (is_ok = x.ld > LDBL_MAX && x.ld == x.ld * .5);  /* Infinity. */
  printf("is_ok=%d u0=0x%x u1=0x%x u2=0x%x\n", is_ok, x.u[0], x.u[1], x.u[2] & 0xffff);

  x.ld = my_strtold(" \t3.36210314311209350626267781732175260e-4932", 0);
  is_all_ok &= (is_ok = x.ld > 0.0L && x.ld == LDBL_MIN && x.ld < DBL_MIN);
  printf("is_ok=%d u0=0x%x u1=0x%x u2=0x%x\n", is_ok, x.u[0], x.u[1], x.u[2] & 0xffff);

  x.ld = my_strtold("3.36210314311209350626267781732175260e-4932", 0);  /* "%.36Lg". */
  is_all_ok &= (is_ok = x.ld == LDBL_MIN);
  printf("is_ok=%d u0=0x%x u1=0x%x u2=0x%x\n", is_ok, x.u[0], x.u[1], x.u[2] & 0xffff);

  x.ld = my_strtold("3.3621031431120935060e-4932", 0);
  is_all_ok &= (is_ok = x.ld < LDBL_MIN);
  printf("is_ok=%d u0=0x%x u1=0x%x u2=0x%x\n", is_ok, x.u[0], x.u[1], x.u[2] & 0xffff);

  x.ld = my_strtold("3.3621031431120935061e-4932", 0);  /* "%.20Lg". */
  is_all_ok &= (is_ok = x.ld == LDBL_MIN);
  printf("is_ok=%d u0=0x%x u1=0x%x u2=0x%x\n", is_ok, x.u[0], x.u[1], x.u[2] & 0xffff);

  x.ld = my_strtold("3.3621031431120935062e-4932", 0);
  is_all_ok &= (is_ok = x.ld == LDBL_MIN);
  printf("is_ok=%d u0=0x%x u1=0x%x u2=0x%x\n", is_ok, x.u[0], x.u[1], x.u[2] & 0xffff);

  x.ld = my_strtold("3.3621031431120935064e-4932", 0);
  is_all_ok &= (is_ok = x.ld == LDBL_MIN);
  printf("is_ok=%d u0=0x%x u1=0x%x u2=0x%x\n", is_ok, x.u[0], x.u[1], x.u[2] & 0xffff);

  x.ld = my_strtold("3.3621031431120935065e-4932", 0);
  is_all_ok &= (is_ok = x.ld > LDBL_MIN);
  printf("is_ok=%d u0=0x%x u1=0x%x u2=0x%x\n", is_ok, x.u[0], x.u[1], x.u[2] & 0xffff);

  x.ld = LDBL_EPSILON;
  is_all_ok &= (is_ok = x.ld == LDBL_EPSILON);
  printf("is_ok=%d u0=0x%x u1=0x%x u2=0x%x\n", is_ok, x.u[0], x.u[1], x.u[2] & 0xffff);

  x.ld = my_strtold("1.08420217248550443400745280086994171e-19", 0);
  is_all_ok &= (is_ok = x.ld == LDBL_EPSILON);
  printf("is_ok=%d u0=0x%x u1=0x%x u2=0x%x\n", is_ok, x.u[0], x.u[1], x.u[2] & 0xffff);

  x.ld = my_strtold("1.0842021724855044340E-19", 0);
  is_all_ok &= (is_ok = x.ld == LDBL_EPSILON);
  printf("is_ok=%d u0=0x%x u1=0x%x u2=0x%x\n", is_ok, x.u[0], x.u[1], x.u[2] & 0xffff);

  x.ld = my_strtold("3.64519953188247460252840593361941982e-4951", 0);
  is_all_ok &= (is_ok = x.u[0] == 1 && x.u[1] == 0 && (x.u[2] & 0xffff) == 0);
  printf("is_ok=%d u0=0x%x u1=0x%x u2=0x%x\n", is_ok, x.u[0], x.u[1], x.u[2] & 0xffff);

  x.ld = my_strtold("2e-4951", 0);
  is_all_ok &= (is_ok = x.u[0] == 1 && x.u[1] == 0 && (x.u[2] & 0xffff) == 0);
  printf("is_ok=%d u0=0x%x u1=0x%x u2=0x%x\n", is_ok, x.u[0], x.u[1], x.u[2] & 0xffff);

  x.ld = my_strtold("3e-4951", 0);
  is_all_ok &= (is_ok = x.u[0] == 1 && x.u[1] == 0 && (x.u[2] & 0xffff) == 0);
  printf("is_ok=%d u0=0x%x u1=0x%x u2=0x%x\n", is_ok, x.u[0], x.u[1], x.u[2] & 0xffff);

  x.ld = my_strtold("4e-4951", 0);
  is_all_ok &= (is_ok = x.u[0] == 1 && x.u[1] == 0 && (x.u[2] & 0xffff) == 0);
  printf("is_ok=%d u0=0x%x u1=0x%x u2=0x%x\n", is_ok, x.u[0], x.u[1], x.u[2] & 0xffff);

  x.ld = my_strtold("1.8226e-4951", 0);
  is_all_ok &= (is_ok = x.u[0] == 1 && x.u[1] == 0 && (x.u[2] & 0xffff) == 0);
  printf("is_ok=%d u0=0x%x u1=0x%x u2=0x%x\n", is_ok, x.u[0], x.u[1], x.u[2] & 0xffff);

  x.ld = my_strtold("-1.8226e-4951", 0);
  is_all_ok &= (is_ok = x.u[0] == 1 && x.u[1] == 0 && (x.u[2] & 0xffff) == 0x8000);
  printf("is_ok=%d u0=0x%x u1=0x%x u2=0x%x\n", is_ok, x.u[0], x.u[1], x.u[2] & 0xffff);

  x.ld = my_strtold("+1.8225e-4951", 0);
  is_all_ok &= (is_ok = x.ld == 0.0L && !my_signbit(x.ld));
  printf("is_ok=%d u0=0x%x u1=0x%x u2=0x%x\n", is_ok, x.u[0], x.u[1], x.u[2] & 0xffff);

  x.ld = my_strtold("-1.8225E-4951", 0);
  is_all_ok &= (is_ok = x.ld == 0.0L && my_signbit(x.ld));  /* !! */
  printf("is_ok=%d u0=0x%x u1=0x%x u2=0x%x\n", is_ok, x.u[0], x.u[1], x.u[2] & 0xffff);

  x.ld = my_strtold("  \t4567", 0);
  is_all_ok &= (is_ok = x.u[0] == 0x0&& x.u[1] == 0x8eb80000&& (x.u[2] & 0xffff) == 0x400b);
  printf("is_ok=%d u0=0x%x u1=0x%x u2=0x%x\n", is_ok, x.u[0], x.u[1], x.u[2] & 0xffff);

  x.ld = my_strtold("12.25", 0);
  is_all_ok &= (is_ok = x.u[0] == 0x0&& x.u[1] == 0xc4000000 && (x.u[2] & 0xffff) == 0x4002);
  printf("is_ok=%d u0=0x%x u1=0x%x u2=0x%x\n", is_ok, x.u[0], x.u[1], x.u[2] & 0xffff);

  x.ld = my_strtold("inf", 0);
  is_all_ok &= (is_ok = x.u[0] == 0x0 && x.u[1] == 0x80000000 && (x.u[2] & 0xffff) == 0x7fff);
  printf("is_ok=%d u0=0x%x u1=0x%x u2=0x%x\n", is_ok, x.u[0], x.u[1], x.u[2] & 0xffff);

  x.ld = my_strtold("  -0.0000", 0);
  is_all_ok &= (is_ok = x.u[0] == 0x0 && x.u[1] == 0x0 && (x.u[2] & 0xffff) == 0x8000);
  printf("is_ok=%d u0=0x%x u1=0x%x u2=0x%x\n", is_ok, x.u[0], x.u[1], x.u[2] & 0xffff);

  x.ld = my_strtold(" 000", 0);
  is_all_ok &= (is_ok = x.u[0] == 0x0 && x.u[1] == 0x0 && (x.u[2] & 0xffff) == 0x0);
  printf("is_ok=%d u0=0x%x u1=0x%x u2=0x%x\n", is_ok, x.u[0], x.u[1], x.u[2] & 0xffff);

  x.ld = my_strtold("\t-InfINity", 0);
  is_all_ok &= (is_ok = x.u[0] == 0x0 && x.u[1] == 0x80000000 && (x.u[2] & 0xffff) == 0xffff);
  printf("is_ok=%d u0=0x%x u1=0x%x u2=0x%x\n", is_ok, x.u[0], x.u[1], x.u[2] & 0xffff);

  x.ld = my_strtold("+NaN", 0);
  is_all_ok &= (is_ok = x.u[0] == 0x0 && x.u[1] == 0xc0000000 && (x.u[2] & 0xffff) == 0x7fff);
  printf("is_ok=%d u0=0x%x u1=0x%x u2=0x%x\n", is_ok, x.u[0], x.u[1], x.u[2] & 0xffff);

  x.ld = my_strtold("-NaN", 0);  /* Negative NaN is the same as NaN. */
  is_all_ok &= (is_ok = x.u[0] == 0x0 && x.u[1] == 0xc0000000 && (x.u[2] & 0xffff) == 0x7fff);
  printf("is_ok=%d u0=0x%x u1=0x%x u2=0x%x\n", is_ok, x.u[0], x.u[1], x.u[2] & 0xffff);

  x.ld = my_strtold("  -12.345e-67", 0);
  is_all_ok &= (is_ok = x.u[0] == 0x4dde0c28 && x.u[1] == 0x8520d2ce && (x.u[2] & 0xffff) == 0xbf24);
  printf("is_ok=%d u0=0x%x u1=0x%x u2=0x%x\n", is_ok, x.u[0], x.u[1], x.u[2] & 0xffff);

  x.ld = my_strtold("  +12.345678901234567E67", 0);
  is_all_ok &= (is_ok = x.u[0] == 0x5fda11f1 && x.u[1] == 0x92895a8d && (x.u[2] & 0xffff) == 0x40e1);
  printf("is_ok=%d u0=0x%x u1=0x%x u2=0x%x\n", is_ok, x.u[0], x.u[1], x.u[2] & 0xffff);

  x.ld = my_strtold("  -1.0345e-4932", 0);
  is_all_ok &= (is_ok = x.u[0] == 0xfbf7ea34 && x.u[1] == 0x276286ee && (x.u[2] & 0xffff) == 0x8000);
  printf("is_ok=%d u0=0x%x u1=0x%x u2=0x%x\n", is_ok, x.u[0], x.u[1], x.u[2] & 0xffff);

  x.ld = my_strtold("  +1.0345678901234567E4932", 0);
  is_all_ok &= (is_ok = x.u[0] == 0xff618ea && x.u[1] == 0xde9cdc14 && (x.u[2] & 0xffff) == 0x7ffe);
  printf("is_ok=%d u0=0x%x u1=0x%x u2=0x%x\n", is_ok, x.u[0], x.u[1], x.u[2] & 0xffff);

  x.ld = my_strtold("+infhello", 0);
  is_all_ok &= (is_ok = x.u[0] == 0x0 && x.u[1] == 0x80000000 && (x.u[2] & 0xffff) == 0x7fff);
  printf("is_ok=%d u0=0x%x u1=0x%x u2=0x%x\n", is_ok, x.u[0], x.u[1], x.u[2] & 0xffff);

  x.ld = my_strtold("+inhello", 0);
  is_all_ok &= (is_ok = x.u[0] == 0x0 && x.u[1] == 0x0 && (x.u[2] & 0xffff) == 0x0);
  printf("is_ok=%d u0=0x%x u1=0x%x u2=0x%x\n", is_ok, x.u[0], x.u[1], x.u[2] & 0xffff);

  x.ld = my_strtold("+infiniTyLong", 0);
  is_all_ok &= (is_ok = x.u[0] == 0x0 && x.u[1] == 0x80000000 && (x.u[2] & 0xffff) == 0x7fff);
  printf("is_ok=%d u0=0x%x u1=0x%x u2=0x%x\n", is_ok, x.u[0], x.u[1], x.u[2] & 0xffff);

  x.ld = my_strtold("+0xf00.ba4p16000", 0);
  is_all_ok &= (is_ok = x.u[0] == 0x0 && x.u[1] == 0xf00ba400 && (x.u[2] & 0xffff) == 0x7e8a);
  printf("is_ok=%d u0=0x%x u1=0x%x u2=0x%x\n", is_ok, x.u[0], x.u[1], x.u[2] & 0xffff);

  x.ld = my_strtold("\r -0xf00.ba4p-16000", 0);
  is_all_ok &= (is_ok = x.u[0] == 0x0 && x.u[1] == 0xf00ba400 && (x.u[2] & 0xffff) == 0x818a);
  printf("is_ok=%d u0=0x%x u1=0x%x u2=0x%x\n", is_ok, x.u[0], x.u[1], x.u[2] & 0xffff);

  /* !! Test endptr and errno. */

  return !is_all_ok;
}
#endif  /* DO_MAIN_TEST */
