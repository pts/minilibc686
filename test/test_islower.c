/* The C standard specifies that the valid range of i below is -1..255. */
#ifdef DO_TEST_RP3
#  define declare_func(name) int name(int c) __attribute__((__regparm__(1))) __asm__(#name "_RP3")
#else
#  define declare_func(name) int name(int c)
#endif
declare_func(mini_islower);
declare_func(mini_isupper);
declare_func(mini_isalpha);
declare_func(mini_isdigit);
declare_func(mini_isalnum);
declare_func(mini_isxdigit);
declare_func(mini_isascii);
declare_func(mini_isprint);

int main(int argc, char **argv) {
  int i;
  (void)argc; (void)argv;
  for (i = -1; i < 256; ++i) {
    if (mini_islower(i) != (i >= 'a' && i <= 'z')) return 11;
  }
  for (i = -1; i < 256; ++i) {
    if (mini_isupper(i) != (i >= 'A' && i <= 'Z')) return 12;
  }
  for (i = -1; i < 256; ++i) {
    if (mini_isalpha(i) != ((i >= 'A' && i <= 'Z') || (i >= 'a' && i <= 'z'))) return 13;
  }
  for (i = -1; i < 256; ++i) {
    if (mini_isdigit(i) != (i >= '0' && i <= '9')) return 14;
  }
  for (i = -1; i < 256; ++i) {
    if (mini_isalnum(i) != ((i >= 'A' && i <= 'Z') || (i >= 'a' && i <= 'z') || (i >= '0' && i <= '9'))) return 15;
  }
  for (i = -1; i < 256; ++i) {
    if (mini_isxdigit(i) != ((i >= 'A' && i <= 'F') || (i >= 'a' && i <= 'f') || (i >= '0' && i <= '9'))) return 16;
  }
  for (i = -1; i < 256; ++i) {
    if (mini_isascii(i) != ((i) >= 0 && (i) <= 127)) return 17;
  }
  for (i = -1; i < 256; ++i) {
    if (mini_isprint(i) != ((i) >= 32 && (i) <= 126)) return 18;
  }
  return 0;
}
