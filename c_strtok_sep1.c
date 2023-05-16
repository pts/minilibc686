/* This is a mini strtok implementation which assumes strlen(sep) == 1. This
 * assumption makes the code much shorter.
 *
 * Based on musl-1.2.4/src/string/strtok.c
 */

#ifndef __GNUC__
#  define __restrict__
#endif

char *mini_strtok(char *__restrict__ s, const char *__restrict__ sep) {
  char *save_s;
  char sepc0 = *sep;
  static char *mini_strtok_global_ptr;
  if (!s && !(s = mini_strtok_global_ptr)) return (void*)0;
  for (; *s == sepc0; s++);
  if (!*s) return mini_strtok_global_ptr = 0;
  save_s = s;
  for (; *s && s[0] != sepc0; s++) {}
  mini_strtok_global_ptr = s;
  if (*mini_strtok_global_ptr) {
    *mini_strtok_global_ptr++ = 0;
  } else {
    mini_strtok_global_ptr = 0;
  }
  return save_s;
}
