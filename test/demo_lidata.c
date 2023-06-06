static int myvar;

/* This makes OpenWatcom (wcc386) emit LIDATA386 records. */
#ifdef __WATCOMC__
_Packed
#endif
struct {
  char pad1[0x54321];
  char msg[0x200];
  int *varp;
  char pad2[0x65432];
} mybig = {{0}, "Hello, World!\n", &myvar, {0}};
