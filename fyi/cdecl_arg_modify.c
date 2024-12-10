/* In the SYSV i386 default calling convention (__cdecl), can a function
 * modify its argument on the stack? Yes, both GCC and the OpenWatcom C
 * compiler generate such code if there are many arguments.
 *
 * Try it with: ./soptcc.pl -mno-owcc fyi/cdecl_arg_modify.c
 */

char *reorder(char *q, const char *p, const char *a, const char *b, const char *c, const char *d, const char *e, const char *f) {
  char v;
  while ((v = *p++) != '\0') {
    *q++ = (v == 1) ? *a++ : (v == 2) ? *b++ : (v == 3) ? *c++ : (v == 4) ? *d++ : (v == 5) ? *e++ : *f++;
  }
  return q;
}
