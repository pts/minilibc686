typedef unsigned size_t;

char *strncpy(char *dst, const char *src, size_t n) {
  if (n != 0) {
    register char *d = dst;
    register const char *s = src;
    do {
      if ((*d++ = *s++) == 0) {  /* NUL pad the remaining n-1 bytes */
        while (--n != 0)
          *d++ = 0;
        break;
      }
    } while (--n != 0);
  }
  return (dst);
}
