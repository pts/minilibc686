/* GCC and OpenWatcom generates code which modifies local variables on the stack. */
unsigned mixit(unsigned a, unsigned b, unsigned c, unsigned d, unsigned e, unsigned f, unsigned g, unsigned h) {
  unsigned i;
  for (i = a + b + c + d + e + f + g + h; i > 0; --i) {
    a += b;
    b *= c;
    c -= d;
    d /= e;
    e |= f;
    f ^= g;
    g &= h;
    h = (h << 1) | (a & 1);
  }
  return a ^ b ^ c ^ d ^ e ^ f ^ g ^ h;
}
