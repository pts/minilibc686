typedef struct c1 { char a[1]; } c1;
typedef struct c2 { char a[2]; } c2;
typedef struct c3 { char a[3]; } c3;
typedef struct c4 { char a[4]; } c4;
typedef struct c5 { char a[5]; } c5;
typedef struct c6 { char a[6]; } c6;
typedef struct c7 { char a[7]; } c7;
typedef struct c8 { char a[8]; } c8;
typedef struct c9 { char a[9]; } c9;

c1 fc1(void) { c1 c; c.a[0] = 42;              return c; }
c2 fc2(void) { c2 c; c.a[0] = 42; c.a[1] = 11; return c; }
c3 fc3(void) { c3 c; c.a[1] = 11; c.a[2] = 22; return c; }
c4 fc4(void) { c4 c; c.a[1] = 11; c.a[3] = 33; return c; }
c5 fc5(void) { c5 c; c.a[1] = 11; c.a[4] = 44; return c; }
c6 fc6(void) { c6 c; c.a[1] = 11; c.a[5] = 55; return c; }
c7 fc7(void) { c7 c; c.a[1] = 11; c.a[6] = 66; return c; }
c8 fc8(void) { c8 c; c.a[1] = 11; c.a[7] = 77; return c; }
c9 fc9(void) { c9 c; c.a[1] = 11; c.a[8] = 88; return c; }

char call_fc9(void) { c9 c = fc9(); return c.a[1] - c.a[8]; }

typedef struct i1 { int a[1]; } i1;
typedef struct i2 { int a[2]; } i2;
typedef struct i3 { int a[3]; } i3;

i1 fi1(void) { i1 i; i.a[0] = 0;             return i; }
i2 fi2(void) { i2 i; i.a[0] = 0; i.a[1] = 1; return i; }
i3 fi3(void) { i3 i; i.a[1] = 1; i.a[2] = 2; return i; }

typedef struct iv1 { int a0; } iv1;
typedef struct iv2 { int a0, a1; } iv2;
typedef struct iv3 { int a0, a1, a2; } iv3;

iv1 fiv1(void) { iv1 i; i.a0 = 0;           return i; }
iv2 fiv2(void) { iv2 i; i.a0 = 0; i.a1 = 1; return i; }
iv3 fiv3(void) { iv3 i; i.a1 = 1; i.a2 = 2; return i; }


typedef struct fv1 { float a0; } fv1;
typedef struct fv2 { float a0, a1; } fv2;
typedef struct fv3 { float a0, a1, a2; } fv3;

fv1 ffv1(void) { fv1 i; i.a0 = 0;           return i; }
fv2 ffv2(void) { fv2 i; i.a0 = 0; i.a1 = 1; return i; }
fv3 ffv3(void) { fv3 i; i.a1 = 1; i.a2 = 2; return i; }

#if !defined(__TINYC__) && !defined(__WATCOMC__)
float _Complex ffc(void) { return 5 + 6i; }  /* PCC and TCC: returns: EAX := 5f; EDX := 6f; */
#endif
