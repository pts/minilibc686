/* Based on musl-1.2.4/src/string/strtok.c */

#ifndef __GNUC__
#  define __restrict__
#endif

typedef unsigned size_t;

#define BITOP(a,b,op) \
   ((a)[(size_t)(b)/(8*sizeof *(a))] op (size_t)1<<((size_t)(b)%(8*sizeof *(a))))

char *mini_strtok(char *__restrict__ s, const char *__restrict__ sep) {
  char *save_s;
  const char *c;
  char c0;
  size_t byteset[32/sizeof(size_t)] = { 0 };
  static char *mini_strtok_global_ptr;
  if (!s && !(s = mini_strtok_global_ptr)) return (void*)0;
  c = sep;
  if (!c[0]) {
  } else if (!c[1]) {
    c0 = c[0];
    for (; *s == c0; s++);
  } else {
    for (; *c && BITOP(byteset, *(unsigned char *)c, |=); c++);
    for (; *s && BITOP(byteset, *(unsigned char *)s, &); s++);
  }
  if (!*s) return mini_strtok_global_ptr = 0;
  save_s = s;
  c = sep;
  if (!c[0] || !c[1]) {
    c0 = c[0];
    for (; *s && s[0] != c0; s++) {}
  } else {
    for (; *s && !BITOP(byteset, *(unsigned char *)s, &); s++);
  }
  mini_strtok_global_ptr = s;
  if (*mini_strtok_global_ptr) {
    *mini_strtok_global_ptr++ = 0;
  } else {
    mini_strtok_global_ptr = 0;
  }
  return save_s;
}
