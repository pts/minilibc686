typedef unsigned long size_t;

#if 0
#define mini_strncmp MMM

extern int mini_strncmp(const char *s1, const char *s2, size_t n);  /* Function under test. */

int mini_strncmp(const char *s1, const char *s2, size_t n) {
  register const unsigned char* a=(const unsigned char*)s1;
  register const unsigned char* b=(const unsigned char*)s2;
  register const unsigned char* fini=a+n;
  while (a!=fini) {
    register int res=*a-*b;
    if (res) return res < 0 ? -1 : 1;
    if (!*a) return 0;
    ++a; ++b;
  }
  return 0;
}
#endif

int main(int argc, char **argv) {
  (void)argc; (void)argv;
  if (mini_strncmp("", "", 0) != 0) return 99;
  if (mini_strncmp("a", "", 0) != 0) return 99;
  if (mini_strncmp("", "a", 0) != 0) return 99;
  if (mini_strncmp("a", "A", 0) != 0) return 99;
  if (mini_strncmp("A", "a", 0) != 0) return 98;
  if (mini_strncmp("A", "a", 1) != -1) return 97;
  if (mini_strncmp("a", "A", 1) != 1) return 96;
  if (mini_strncmp("foo", "food", 2) != 0) return 94;
  if (mini_strncmp("foo", "food", 3) != 0) return 93;
  if (mini_strncmp("foo", "food", 4) != -1) return 92;
  if (mini_strncmp("food", "foo", 4) != 1) return 91;
  if (mini_strncmp("f\0o", "f\0od", 1) != 0) return 90;
  if (mini_strncmp("f\0o", "f\0od", 2) != 0) return 89;
  if (mini_strncmp("f\0o", "f\0od", 3) != 0) return 88;
  if (mini_strncmp("f\0o", "f\0od", 4) != 0) return 87;  /* This is the first difference from mini_memcmp(...). */
  if (mini_strncmp("foo\0x", "food", 3) != 0) return 86;
  if (mini_strncmp("foo\0x", "food", 4) != -1) return 85;
  if (mini_strncmp("fool", "foo\0d", 3) != 0) return 84;
  if (mini_strncmp("fool", "foo\0d", 4) != 1) return 83;
  if (mini_strncmp("foolx", "food", 3) != 0) return 82;
  if (mini_strncmp("foolx", "food", 4) != 1) return 81;
  return 0;
}
