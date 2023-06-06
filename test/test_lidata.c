static int myvar;

/* This makes wcc386 emit a LIDATA386 record. */
struct {
  char pad1[0x54321];
  char msg[0x200];
  int *varp;
  char pad2[0x65432];
} mybig = {{0}, "Hello, World!\n", &myvar, {0}};
