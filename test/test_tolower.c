/* The C standard specifies that the valid range of i below is -1..255. */
#ifdef DO_TEST_RP3
#  define declare_func(name) int name(int c) __attribute__((__regparm__(1))) __asm__(#name "_RP3")
#else
#  define declare_func(name) int name(int c)
#endif
declare_func(mini_tolower);
declare_func(mini_toupper);

int main(int argc, char **argv) {
  int i;
  (void)argc; (void)argv;
  for (i = -1; i < 256; ++i) {
    if (mini_tolower(i) != (i >= 'A' && i <= 'Z' ? i + 'a' - 'A' : i)) return 11;
  }
  for (i = -1; i < 256; ++i) {
    if (mini_toupper(i) != (i >= 'a' && i <= 'z' ? i + 'A' - 'a' : i)) return 12;
  }
  return 0;
}
