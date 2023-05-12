/* Based on https://raw.githubusercontent.com/open-watcom/open-watcom-v2/da4230a21a20597c297d057e2fea575b55377c4e/bld/clib/convert/c/strtol.c */

#define ULONG_MAX 0xffffffffUL
#define LONG_MAX 0x7fffffffL
typedef char mybool;
#define true 1
#define false 0

static inline char my_isspace(char c) {
  return (unsigned char)c == 32 || (unsigned char)c - 9U <= 4U;
}

long mini_strtol(const char *nptr, char **endptr, int base) {
  const char *p;
  const char *startp;
  unsigned digit;
  unsigned long value;
  mybool minus;
  mybool overflow;
  unsigned long overflow_limit;
#define is_signed 1  /* Change this to 0 to get mini_strtoul. TODO(pts): Should we allow the - sign there? */
  if (endptr) *endptr = (char*)nptr;
  for (p = nptr; my_isspace((unsigned char)*p); ++p) {}
  minus = false;
  switch(*p) {
   case '-':
    minus = true;
    /* fallthrough */
   case '+':
    ++p;
    break;
  }
  if (base != 0 && base != 16) {
  } else if (p[0] == '0' && (p[1] | 32) == 'x') {
    base = 16;
    p += 2;  /* skip over '0x' */
  } else if (base != 0) {
  } else if (*p == '0') {
    base = 8;
  } else {
    base = 10;
  }
  if (base - 2U > 36U - 2U) return 0;  /* errno = EDOM or errno = EINVAL. */
  overflow_limit = ULONG_MAX / base;
  startp = p;
  overflow = false;
  value = 0;
  for (;;) {
    digit = *p - '0';
    if (digit > 9) {
      digit += '0';
      if ((digit | 32) - 'a' > 26) break;
      digit = ((digit | 32) - 'a') + 10;
    }
    if (digit >= base + 0U) break;
    if (value > overflow_limit) overflow = true;  /* Check that the multiplication would overflow. */
    value *= base;
    if (value + digit < value) overflow = true;
    value += digit;
    ++p;
  }
  if (p != startp && endptr) *endptr = (char*)p;
  if (overflow || (is_signed && value >= (ULONG_MAX / 2 + 1) && !(value == (ULONG_MAX / 2 + 1) && minus))) {
    /* errno = ERANGE; */
    value = LONG_MAX;
    if (is_signed && minus) value = ~value;
  } else if (minus) {
    value = -value;
  }
  return value;
}
