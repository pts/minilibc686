typedef unsigned long size_t;

extern int mini_memcmp(const void *s1, const void *s2, size_t n);

int main(int argc, char **argv) {
  (void)argc; (void)argv;
  if (mini_memcmp("", "", 0) != 0) return 99;
  if (mini_memcmp("a", "", 0) != 0) return 99;
  if (mini_memcmp("", "a", 0) != 0) return 99;
  if (mini_memcmp("a", "A", 0) != 0) return 99;
  if (mini_memcmp("A", "a", 0) != 0) return 98;
  if (mini_memcmp("A", "a", 1) != -1) return 97;
  if (mini_memcmp("a", "A", 1) != 1) return 96;
  if (mini_memcmp("foo", "food", 2) != 0) return 94;
  if (mini_memcmp("foo", "food", 3) != 0) return 93;
  if (mini_memcmp("foo", "food", 4) != -1) return 92;
  if (mini_memcmp("food", "foo", 4) != 1) return 91;
  if (mini_memcmp("f\0o", "f\0od", 1) != 0) return 90;
  if (mini_memcmp("f\0o", "f\0od", 2) != 0) return 89;
  if (mini_memcmp("f\0o", "f\0od", 3) != 0) return 88;
  if (mini_memcmp("f\0o", "f\0od", 4) != -1) return 87;  /* This is the first difference from mini_strncmp(...). */
  if (mini_memcmp("foo\0x", "food", 3) != 0) return 86;
  if (mini_memcmp("foo\0x", "food", 4) != -1) return 85;
  if (mini_memcmp("fool", "foo\0d", 3) != 0) return 84;
  if (mini_memcmp("fool", "foo\0d", 4) != 1) return 83;
  if (mini_memcmp("foolx", "food", 3) != 0) return 82;
  if (mini_memcmp("foolx", "food", 4) != 1) return 81;
  return 0;
}
