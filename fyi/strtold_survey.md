# A survey of x86 strtold implementations

x86 (8087 FPU, 80387 FPU, i586, i686 etc.) supports a [80-bit
extended-precision floating-point numbers](https://en.wikipedia.org/wiki/Extended_precision#x86_extended_precision_format)
(x86 f80). In fact, internally all (non-MMX, non-SIMD) floating-point
calculations are done at that precison and the result can be converted a to
[32-bit, 64-bit](https://en.wikipedia.org/wiki/IEEE_754) or 80-bit number in
memory. The corresponding C type is typically *long double* with a size of
10, 12 or 16. Only the first 80 bits (10 bytes) contain data, the rest is
for alignment only, and its contents is ignored.

The [strtold(3)](https://linux.die.net/man/3/strtold) libc function converts
a string (decimal, scientific notation or hexadecimal floating point) to a
long double. This conversion may be inaccurate, i.e. the last few bits of
the 64-bit significand may be incorrect, because of intermediate rounding
errors. This document is a survey of *strtold* implementations for accuracy.
The test program
[test_strtold.c](https://github.com/pts/minilibc686/blob/master/test/test_strtold.c)
is compiled and run.

Relevant standards:

* [IEE 754](https://en.wikipedia.org/wiki/IEEE_754-1985)
* [x86 80-bit extended-precision floation-point numbers](https://en.wikipedia.org/wiki/Extended_precision#x86_extended_precision_format)

Relevant docs:

* [How to convert strings to floats with perfect accuracy?](https://stackoverflow.com/questions/2174012/how-to-convert-strings-to-floats-with-perfect-accuracy) on StackOverflow.com

## Survey results

Accurate implementations:

* glibc 2.19 (2014-02-07) and 2.27 (2018-02-01): It has its own implementation.
* EGLIBC 2.19 (2014-09-29): It has its own implementation matching glibc.
* musl 1.1.16 (2017-01-01), musl 1.2.4 (2023-05-02) and musl 1.2.5
  (2024-03-01): It has its own implementation in
  [src/internal/floatscan.c](https://git.musl-libc.org/cgit/musl/log/src/internal/floatscan.c)
  which uses a bit more than 8 KiB of stack space. The behavior matches
  glibc. This implementation was introduced [on
  2012-04-10](https://git.musl-libc.org/cgit/musl/commit/src/internal/floatscan.c?id=415c4cd7fdb3e8b7476fbb2be2390f4592cf5165)
  by Rich Felker, stable part of musl since 0.9.8 (2012-11-26), last update on
  [2019-10-18](https://git.musl-libc.org/cgit/musl/commit/src/internal/floatscan.c?id=bff78954995b115e469aadb7636357798978fffd).
* FreeBSD 9.3 (2014-07-16) libc: It implements *strtold* using *strtold\_l*,
  using *strtorx\_l*, which is part of the bundled
  [gdtoa](https://github.com/jwiegley/gdtoa) library by David M. Gay, based on dtoa.c by
  David M. Gay. The behavior matches glibc and musl except for a minor
  difference that `-nan` returns a negative NaN value.
* David M. Gay's [strtod(...) in dtoa.c in netlib](https://www.netlib.org/fp/dtoa.c) (last change 2024-02-24): It directly supports only *double*, but can be patched (see e.g. FreeBSD). It's also quite large, containing multiple large tables.
* minilibc686 [strtold.nasm](https://github.com/pts/minilibc686/blob/40d3704c294ff532c8cc2a88ab18a8241e5fb484/src/strtold.nasm) (2024-05-20): It is based on musl 1.2.5.

Inaccurate implementations:

* diet libc 0.34 (2018-09-24, latest): 32 inaccuracies. It contains a simplistic implementation with many intermediate rounding errors.
* uClibc 0.9.30.1 (2009-03-02), 0.9.33.2 (2012-05-15, latest): 18 inaccuracies. It contains a simplistic implementation with many intermediate rounding errors.
* picolibc 1.8.6 (2024-01-21): Inaccurate. It contains a simplistic implementation with intermediate rounding errors.
* Digital Mars C/C++ 8.57c libc (2020-09-01, latest): 19 inaccuracies
* Borland C++ 5.5.1 (2000-06-27): 33 inaccuracies
* newlib 4.1.0 (2020-12-18): 27 inaccuracies. It contains code
  ([strtorx.c](https://github.com/jwiegley/gdtoa/blob/master/strtorx.c) and
  [strtodg.c](https://github.com/jwiegley/gdtoa/blob/master/strtordg.c))
  matching [gdtoa](https://github.com/jwiegley/gdtoa) by David M. Gay, but
  somehow it's still inaccurate.

Missing implementations:

* OpenWatcom C compiler and libc don't support x86 f80, *long double* has 64 bits.
* MSVCRT.DLL doesn't contain *strtold*.
* Microsoft UCRT doesn't support x86 f80, *long double* has 64 bits.
* Microsoft Visual C++ 2010 (and later) compiler libc doesn't support x86 f80, *long double* has 64 bits.
* The [ACK libc](https://github.com/davidgiven/ack) doesn't support x86 f80.
* The libc of Microsoft Visual C++ Toolit 2003 doesn't contain *strtold*.
* [neatlibc](https://github.com/aligrudi/neatlibc) doesn't contain *strtold*.
* [klibc](https://en.wikipedia.org/wiki/Klibc) 1.5.25 doesn't contain *strtold* or *strtod*.

Untested libcs:

* newlib 4.4.0 (2023-12-31)
* earlier glibc, musl and FreeBSD versions

Untested C compilers (maybe they don't have a libc):

* [chibicc](https://github.com/rui314/chibicc)
* [8cc](https://github.com/rui314/8cc), the predecessor of chibicc
* [cproc](https://github.com/michaelforney/cproc)
* [andrewchambers/c](https://github.com/andrewchambers/c)
* [lacc](https://github.com/larmel/lacc)
* [SCC](http://www.simple-cc.org/)
