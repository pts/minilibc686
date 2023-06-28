#include <stdio.h>

#ifdef __WATCOMC__
#  error This test does not work with Watcom C, because Watcom C expects the function returning a struct cleanup up the struct pointer from the stack.
#endif

#define CONCAT(a, b) a ## b
#define CONCATX(a, b) CONCAT(a, b)
#ifdef __GNUC__  /* Works with GCC >= 4.1 and PCC 1.1.0. */
#  define RFT8(FUNCSX, FT) FT _Complex
#  define RFT12 RFT8
#  define RFT4 RFT8
#  define EXPECT_DEFINE_VALUES8(FUNCSX, FT, OP) \
      const FT _Complex z2 = FUNCSX(ar, ai, br, bi); \
      const struct FUNCSX value2 = { __real__ z2, __imag__ z2 }; \
      const FT _Complex z = (ar + ai * 1i) OP (br + bi * 1i); \
      const struct FUNCSX value = { __real__ z, __imag__ z };
#  define EXPECT_DEFINE_VALUES12 EXPECT_DEFINE_VALUES8
#  define EXPECT_DEFINE_VALUES4 EXPECT_DEFINE_VALUES8
#else  /* Works with TinyCC >=0.9.26-2, doesn't work with earlier versions TinyCC and any OpenWatcom (because of different ABI for returning structs). */
#  define RFT8(FUNCSX, FT) struct FUNCSX
#  define RFT12 RFT8
  /* GCC (and PCC) `float _Complex' return ABI is: EAX := real part; EDX :=
   * imaginary part. We abuse the 64-bit unsigned long long type, that's
   * returned in EAX (low dword, first in little endian, first element
   * (real) of struct) and EDX (high dword, second in little endian, second
   * element (imaginary) of struct).
   */
#  define RFT4(FUNCSX, FT) unsigned long long
#  define EXPECT_DEFINE_VALUES8(FUNCSX, FT, OP) \
      const struct FUNCSX value2 = FUNCSX(ar, ai, br, bi); \
      const struct FUNCSX value = value2;
#  define EXPECT_DEFINE_VALUES12 EXPECT_DEFINE_VALUES8
#  define EXPECT_DEFINE_VALUES4(FUNCSX, FT, OP) \
      const unsigned long long ull = FUNCSX(ar, ai, br, bi); \
      const struct FUNCSX value2 = *(struct FUNCSX*)&ull; \
      const struct FUNCSX value = value2;
#endif
#define EQ(a, b, IS_APPROX) ((IS_APPROX) ? (((a) >= (b) ? (a) - (b) : (b) - (a)) < 1e-6) : ((a) == (b)))
#define DEFINE_EXPECT(FUNCSX, FT, FS, FMT, OP, IS_APPROX) \
    struct FUNCSX { FT r, i; }; \
    typedef char CONCATX(assert_size_ft_,  FUNCSX)[sizeof(FT) == FS ? 1 : -1]; \
    typedef char CONCATX(assert_size_cft_, FUNCSX)[sizeof(struct FUNCSX) == 2 * FS ? 1 : -1]; \
    extern RFT ## FS(FUNCSX, FT) FUNCSX(FT ar, FT ai, FT br, FT bi);  /* Function under test. */ \
    static char CONCATX(expect, FUNCSX)(FT ar, FT ai, FT br, FT bi, FT expected_r, FT expected_i) { \
      EXPECT_DEFINE_VALUES ## FS(FUNCSX, FT, OP) \
      const char is_ok = (EQ(value.r, expected_r, IS_APPROX) && EQ(value.i, expected_i, IS_APPROX) && EQ(value2.r, expected_r, IS_APPROX) && EQ(value2.i, expected_i, IS_APPROX)); \
      printf("is_ok=%d func=%s a=%"FMT"g+%"FMT"gi b=%"FMT"g+%"FMT"gi expected=%"FMT"g+%"FMT"gi value=%"FMT"g+%"FMT"gi value=%"FMT"g+%"FMT"gi\n", is_ok, #FUNCSX, ar, ai, br, bi, expected_r, expected_i, value.r, value.i, value2.r, value2.i); \
      return is_ok; \
    }

DEFINE_EXPECT(__muldc3, double, 8, "", *, 0)
DEFINE_EXPECT(__mulsc3, float, 4, "", *, 0)
DEFINE_EXPECT(__mulxc3, long double, 12, "L", *, 0)
DEFINE_EXPECT(__divdc3, double, 8, "", /, 1)
DEFINE_EXPECT(__divsc3, float, 4, "", /, 1)
DEFINE_EXPECT(__divxc3, long double, 12, "L", /, 1)

int main(int argc, char **argv) {
  int exit_code = 0;
  (void)argc; (void)argv;
  if (argc < 16) argc = 0;  /* Use the argc trick to prevent GCC to optimize away the FUNCSX call via constant folding. */
  if (!expect__muldc3(argc + 3, 4, 5, 6, -9, 38)) exit_code |= 1;
  if (!expect__mulsc3(argc + 3, 4, 5, 6, -9, 38)) exit_code |= 1;
  if (!expect__mulxc3(argc + 3, 4, 5, 6, -9, 38)) exit_code |= 1;
  if (!expect__divdc3(argc + -9, 38, 5, 6, 3, 4)) exit_code |= 1;
  if (!expect__divsc3(argc + -9, 38, 5, 6, 3, 4)) exit_code |= 1;
  if (!expect__divxc3(argc + -9, 38, 5, 6, 3, 4)) exit_code |= 1;
  return exit_code;
}
