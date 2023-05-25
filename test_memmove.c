typedef unsigned long size_t;

extern void *mini_memmove(void *dest, const void *src, size_t n);  /* Function under test. */
extern void *mini_memcmp(void *dest, const void *src, size_t n);

int main(int argc, char **argv) {
  char buf[0x80];
  (void)argc; (void)argv;
  mini_memmove(buf, "hello-world", 12);
  if (mini_memcmp(buf, "hello-world", 12) != 0) return 2;
  mini_memmove(buf, "help", 5);
  if (mini_memcmp(buf, "help\0-world", 12) != 0) return 3;
  mini_memmove(buf + 2, buf, 8);  /* Overlaps forward. */
  if (mini_memcmp(buf, "hehelp\0-wod", 12) != 0) return 4;
  mini_memmove(buf, buf + 3, 4);  /* Overlaps backward. */
  if (mini_memcmp(buf, "elp\0lp\0-wod", 12) != 0) return 5;
  return 0;
}
