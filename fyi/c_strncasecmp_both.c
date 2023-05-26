typedef unsigned size_t;

static inline unsigned char to_lower(unsigned char c) {
  return (unsigned char)(c - 'A') <= 'Z' - 'A' + 0U ? c | 0x20 : c;
}

int mini_strncasecmp(const char *arg_l, const char *arg_r, size_t n) {
  const unsigned char *l=(void *)arg_l, *r=(void *)arg_r;
  unsigned diff;
  if (!n--) return 0;
 again:
  diff = to_lower(*l) - to_lower(*r);
  if (*l && *r && n && !diff) {
    ++l; ++r; --n;
    goto again;
  }
  return diff;
}

int mini_strcasecmp(const char *arg_l, const char *arg_r) {
#if 0  /* This would also work. */
  return mini_strncasecmp(arg_l, arg_r, (size_t)-1);
#else
  const unsigned char *l=(void *)arg_l, *r=(void *)arg_r;
  unsigned diff;
 again:
  diff = to_lower(*l) - to_lower(*r);
  if (*l && *r && !diff) {
    ++l; ++r;
    goto again;
  }
  return diff;
#endif
}
