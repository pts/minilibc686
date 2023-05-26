/*
 * c_strtod.c: a minimalistic, but configurable strtod(3) implementation in C
 * by pts@fazekas.hu at Tue May 16 01:49:50 CEST 2023
 *
 * Based on uClibc-0.9.30.1/libc/stdlib/_strtod.c .
 *
 * Exports: double mini_strtod(const char *str, char **endptr);
 */

#define NULL ((void*)0)
typedef unsigned short __uint16_t;
#define FPMAX_TYPE  3  /* 1: float, 2: double, 3: long double */
typedef long double __fpmax_t;
/* These values have been reverse-engineered from disassembly. */
#define MAX_ALLOWED_EXP 4973
#define DECIMAL_DIG 21
#define _STRTOD_NAN_INF_STRINGS 1
#undef  _STDTOD_ERRNO
#define _STRTOD_RESTRICT_EXP 1
#define _STRTOD_NEED_NUM_DIGITS 1
#define _STRTOD_ENDPTR 1
#define _STRTOD_ZERO_CHECK 1
#define _STRTOD_LOG_SCALING 1
#define _STRTOD_RESTRICT_DIGITS 1
#undef  _STRTOD_HEXADECIMAL_FLOATS

#ifdef _STRTOD_ERRNO
#define ERANGE 34
int global_errno;
void __set_errno(int errno) { global_errno = errno; }
#endif

static inline char is_digit(unsigned char c) { return (unsigned char)(c - '0') <= 9; }
static inline char is_hdigit(unsigned char c) { return (unsigned char)((c | 0x20) - 'a') <= 5; }
static inline char is_space(unsigned char c) { return c == ' ' || (unsigned char)(c - '\t') <= '\r' - '\t'; }

#if FPMAX_TYPE != 2 || defined(_STRTOD_ERRNO)
#if FPMAX_TYPE == 3
/* The following checks in an __fpmax_t is either 0 or +/- infinity.
 *
 * This only works if __fpmax_t is the actual maximal floating point type used
 * in intermediate calculations.  Otherwise, excess precision in the
 * intermediate values can cause the test to fail.
 */
#define __FPMAX_ZERO_OR_INF_CHECK(x)  ((x) == (x)/4)
#else
#define __FPMAX_ZERO_OR_INF_CHECK(x)  ((long double)(x) == (long double)(x)/4)  /* !! shorter */
#endif
#endif

#if !(FPMAX_TYPE != 2 && defined(_STRTOD_ERRNO))
double mini_strtod(const char *str, char **endptr)
#else
static __fpmax_t __strtofpmax(const char *str, char **endptr)
#endif
{
        int exponent_power;
	__fpmax_t number;
	__fpmax_t p_base = 10;			/* Adjusted to 16 in the hex case. */
	char *pos0;
#ifdef _STRTOD_ENDPTR
	char *pos1;
#endif
	char *pos = (char *) str;
	int exponent_temp;
	int negative; /* A flag for the number, a multiplier for the exponent. */
#ifdef _STRTOD_NEED_NUM_DIGITS
	int num_digits;
#endif

#ifdef _STRTOD_HEXADECIMAL_FLOATS
	char expchar = 'e';
	char *poshex = NULL;
#define EXPCHAR		expchar
#else  /* _STRTOD_HEXADECIMAL_FLOATS */
#define EXPCHAR		'e'
#endif /* _STRTOD_HEXADECIMAL_FLOATS */

	while (is_space(*pos)) {		/* Skip leading whitespace. */
		++pos;
	}

	negative = 0;
	switch(*pos) {				/* Handle optional sign. */
		case '-': negative = 1;	/* Fall through to increment position. */
		/* fallthrough */
		case '+': ++pos;
	}

#ifdef _STRTOD_HEXADECIMAL_FLOATS
	if ((*pos == '0') && (((pos[1])|0x20) == 'x')) {
		poshex = ++pos;			/* Save position of 'x' in case no digits */
		++pos;					/*   and advance past it.  */
		expchar = 'p';			/* Adjust exponent char. */
		p_base = 16;			/* Adjust base multiplier. */
	}
#endif

	number = 0.;
#ifdef _STRTOD_NEED_NUM_DIGITS
	num_digits = -1;
#endif
 	exponent_power = 0;
	pos0 = NULL;

 LOOP:
        (void)is_hdigit;
	while (is_digit(*pos) || (EXPCHAR != 'e' && is_hdigit(*pos))) {	/* Process string of (hex) digits. */
#ifdef _STRTOD_RESTRICT_DIGITS
		if (num_digits < 0) {	/* First time through? */
			++num_digits;		/* We've now seen a digit. */
		}
		if (num_digits || (*pos != '0')) { /* Had/have nonzero. */
			++num_digits;
			if (num_digits <= DECIMAL_DIG) { /* Is digit significant? */
#ifdef _STRTOD_HEXADECIMAL_FLOATS
				number = number * p_base
					+ (is_digit(*pos)
					   ? (*pos - '0')
					   : (((*pos)|0x20) - ('a' - 10)));
#else  /* _STRTOD_HEXADECIMAL_FLOATS */
				number = number * p_base + (*pos - '0');
#endif /* _STRTOD_HEXADECIMAL_FLOATS */
			}
		}
#else  /* _STRTOD_RESTRICT_DIGITS */
#ifdef _STRTOD_NEED_NUM_DIGITS
		++num_digits;
#endif
#ifdef _STRTOD_HEXADECIMAL_FLOATS
		number = number * p_base
			+ (is_digit(*pos)
			   ? (*pos - '0')
			   : (((*pos)|0x20) - ('a' - 10)));
#else  /* _STRTOD_HEXADECIMAL_FLOATS */
		number = number * p_base + (*pos - '0');
#endif /* _STRTOD_HEXADECIMAL_FLOATS */
#endif /* _STRTOD_RESTRICT_DIGITS */
		++pos;
	}

	if ((*pos == '.') && !pos0) { /* First decimal point? */
		pos0 = ++pos;			/* Save position of decimal point */
		goto LOOP;				/*   and process rest of digits. */
	}

#ifdef _STRTOD_NEED_NUM_DIGITS
	if (num_digits<0) {			/* Must have at least one digit. */
#ifdef _STRTOD_HEXADECIMAL_FLOATS
		if (poshex) {			/* Back up to '0' in '0x' prefix. */
			pos = poshex;
			goto DONE;
		}
#endif /* _STRTOD_HEXADECIMAL_FLOATS */

#ifdef _STRTOD_NAN_INF_STRINGS
		if (!pos0) {			/* No decimal point, so check for inf/nan. */
			/* Note: nan is the first string so 'number = i/0.;' works. */
			static const char nan_inf_str[] = "\05nan\0\012infinity\0\05inf\0";
			int i = 0;

#define _tolower(C)     ((C)|0x20)

			do {
				/* Unfortunately, we have no memcasecmp(). */
				int j = 0;
				while (_tolower(pos[j]) == nan_inf_str[i+1+j]) {
					++j;
					if (!nan_inf_str[i+1+j]) {
						number = i / 0.;
						if (negative) {	/* Correct for sign. */
							number = -number;
						}
						pos += nan_inf_str[i] - 2;
						goto DONE;
					}
				}
				i += nan_inf_str[i];
			} while (nan_inf_str[i]);
		}

#endif /* STRTOD_NAN_INF_STRINGS */
#ifdef _STRTOD_ENDPTR
		pos = (char *) str;
#endif
		goto DONE;
	}
#endif /* _STRTOD_NEED_NUM_DIGITS */

#ifdef _STRTOD_RESTRICT_DIGITS
	if (num_digits > DECIMAL_DIG) { /* Adjust exponent for skipped digits. */
		exponent_power += num_digits - DECIMAL_DIG;
	}
#endif

	if (pos0) {
		exponent_power += pos0 - pos; /* Adjust exponent for decimal point. */
	}

#ifdef _STRTOD_HEXADECIMAL_FLOATS
	if (poshex) {
		exponent_power *= 4;	/* Above is 2**4, but below is 2. */
		p_base = 2;
	}
#endif /* _STRTOD_HEXADECIMAL_FLOATS */

	if (negative) {				/* Correct for sign. */
		number = -number;
	}

	/* process an exponent string */
	if (((*pos)|0x20) == EXPCHAR) {
#ifdef _STRTOD_ENDPTR
		pos1 = pos;
#endif
		negative = 1;
		switch(*++pos) {		/* Handle optional sign. */
			case '-': negative = -1; /* Fall through to increment pos. */
			/* fallthrough */
			case '+': ++pos;
		}

		pos0 = pos;
		exponent_temp = 0;
		while (is_digit(*pos)) {	/* Process string of digits. */
#ifdef _STRTOD_RESTRICT_EXP
			if (exponent_temp < MAX_ALLOWED_EXP) { /* Avoid overflow. */
				exponent_temp = exponent_temp * 10 + (*pos - '0');
			}
#else
			exponent_temp = exponent_temp * 10 + (*pos - '0');
#endif
			++pos;
		}

#ifdef _STRTOD_ENDPTR
		if (pos == pos0) {	/* No digits? */
			pos = pos1;		/* Back up to {e|E}/{p|P}. */
		} /* else */
#endif

		exponent_power += negative * exponent_temp;
	}

#ifdef _STRTOD_ZERO_CHECK
	if (number == 0.) {
		goto DONE;
	}
#endif

	/* scale the result */
#ifdef _STRTOD_LOG_SCALING
	exponent_temp = exponent_power;

	if (exponent_temp < 0) {
		exponent_temp = -exponent_temp;
	}

	while (exponent_temp) {
		if (exponent_temp & 1) {
			if (exponent_power < 0) {
				/* Warning... caluclating a factor for the exponent and
				 * then dividing could easily be faster.  But doing so
				 * might cause problems when dealing with denormals. */
				number /= p_base;
			} else {
				number *= p_base;
			}
		}
		exponent_temp >>= 1;
		p_base *= p_base;
	}

#else  /* _STRTOD_LOG_SCALING */
	while (exponent_power) {
		if (exponent_power < 0) {
			number /= p_base;
			exponent_power++;
		} else {
			number *= p_base;
			exponent_power--;
		}
	}
#endif /* _STRTOD_LOG_SCALING */

#ifdef _STRTOD_ERRNO
	if (__FPMAX_ZERO_OR_INF_CHECK(number)) {
		__set_errno(ERANGE);
	}
#endif

 DONE:
#ifdef _STRTOD_ENDPTR
	if (endptr) {
		*endptr = pos;
	}
#endif

	return number;
}

#if FPMAX_TYPE != 2 && defined(_STRTOD_ERRNO)
static void __fp_range_check(__fpmax_t y, __fpmax_t x) {
	if (__FPMAX_ZERO_OR_INF_CHECK(y) /* y is 0 or +/- infinity */
		&& (y != 0)	/* y is not 0 (could have x>0, y==0 if underflow) */
		&& !__FPMAX_ZERO_OR_INF_CHECK(x) /* x is not 0 or +/- infinity */
		) {
		__set_errno(ERANGE);	/* Then x is not in y's range. */
	}
}

double mini_strtod(const char *__restrict str, char **__restrict endptr) {
	__fpmax_t x;
	double y;

	x = __strtofpmax(str, endptr);
	y = (double) x;

	__fp_range_check(y, x);

	return y;
}
#endif
