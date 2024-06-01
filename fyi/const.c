/*
 * const.c: test wcc386 puts which constant to which segment.
 * by pts@fazekas.hu at Sat Jun  1 02:50:47 CEST 2024
 *
 * Compile with: wcc386 -s -j -of+ -bt=linux -fr -zl -zld -e=10000 -zp=4 -6r -os -wx -wce=308 -I../libc/minilibc/include -fo=const.obj const.c && wdis const.obj
 *
 * -ec would adds extra segments YIB,YI,YIE
 */

const char str1[] = "Str1";  /* CONST2. */  /* This should go to CONST. */
const char *str2 = "Str2";  /* Pointer goes to _DATA, data bytes go to CONST. */
const int int3 = 43;  /* CONST2. */
const double double4 = 44.5;  /* CONST2. */

/* All functions go to _TEXT. */
const char *func1() { return "Str5"; }  /* CONST. */
double muld35(double d) { return d * 3.5; }  /* CONST, aligned. */  /* This should go to CONST2. */
double divd35(double d) { return d / 3.5; }  /* CONST, aligned. */  /* This should go to CONST2. */
float mulf35(float f) { return f * 3.5f; }  /* CONST, aligned. */  /* This should go to CONST2. */
float divf35(float f) { return f / 3.5f; }  /* CONST, aligned. */  /* This should go to CONST2. */
int muli37(int i) { return i * 37; }  /* Literal within assembly instruction. */
int divi37(int i) { return i / 37; }  /* Literal within assembly instruction. */
int modi37(int i) { return i % 37; }  /* Literal within assembly instruction. */
