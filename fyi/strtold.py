#
# strtold.py: strtold(...) for x86 f80 long double
# by pts@fazekas.hu at Wed May 22 00:23:55 CEST 2024
#
# This implementation works in Python 2.4--2.7 and 3.x. It's
# architecture-independent.
#
# This implementation is believed to be correct and accurate. See accuracy
# tests in tests/test_strtold.c. The alternative Python implementation in
# fyi/strtold.py passes the same accuracy tests. The C implementation in
# fyi/c_strtold.c passes the same tests. musl 1.1.16, musl 1.2.4, musl
# 1.2.5, EGLIBC 2.19, glibc 2.19, glibc 2.27 pass the same tests.
#

import struct


try:  # Polyfill for Python 2.x.
  range = xrange
except NameError:
  pass
try:  # Polyfill for Python 3.x.
  long
except NameError:
  long = int
try:  # Polyfill for Python 2.6.
  (0).bit_length
  def bit_length(n):
    return n.bit_length()
except AttributeError:
  def bit_length(n):
    n = hex(abs(n))
    return ((len(n) - 3) << 2) + (0, 1, 2, 2, 3, 3, 3, 3, 4, 4, 4, 4, 4, 4, 4, 4)[int(n[2], 16)]


def strtold(s):
  """Converts string to x86 80-bit extended precision floating-point number.

  This implementation is believed to be correct and accurate. See accuracy
  tests in tests/test_strtold.c. The alternative Python implementation in
  fyi/strtold.py passes the same accuracy tests. The C implementation in
  fyi/c_strtold.c passes the same tests. musl 1.1.16, musl 1.2.4, musl
  1.2.5, EGLIBC 2.19, glibc 2.19, glibc 2.27 pass the same tests.

  This is an independent implementation written from scratch, it's not based
  on any existing code.

  This implementation allows and ignores some junk characters after the
  literal, but not anything. The C strtold(3) function allows and returns
  any junk string. Apart from this difference, this implementation does the
  same as a C strold(3).

  Args:
    s: ASCII string containing a floating point literal as base 10 decimal
        (with an optional fraction starting with '.'), base 10 scientific
        notation or base 16 (hex) floating point notation.
  Returns:
    A byte string of size 10 containing the equivalent x86 80-bit
    floating-point number
    (https://en.wikipedia.org/wiki/Extended_precision#x86_extended_precision_format).
    It may be rounded.
  Raises:
    ValueError: .
    TypeError: .
  """
  if isinstance(s, (list, tuple, dict)) or s is None:
    raise TypeError
  s = str(s).lstrip().lower()
  sign, s2 = 0, s
  if s.startswith('+'):
    s2 = s[1:]
  elif s.startswith('-'):
    sign = 0x8000
    s2 = s[1:]
  if s2 in ('inf', 'infinity'):
    return struct.pack('<LLH', 0, 0x80000000, 0x7fff | sign)
  if s2 == 'nan':
    return struct.pack('<LLH', 0, 0xc0000000, 0x7fff)
  if s2.startswith('0x') and 'p' in s2:  # Hex float literal.
    s2 = s2[2:].lstrip('0').rstrip('lf')
    i = s2.find('p')
    if i >= 0:
      try:
        exp = int(s2[i + 1:], 10)
      except ValueError:
        raise ValueError('Bad binary exponent syntax.')
      s2 = s2[:i]
    else:
      exp = 0
    s2 = s2.strip()
    if '+' in s2 or '-' in s2 or len(s2.split()) > 1:
      raise ValueError('Bad characters in hex significand.')
    i = s2.find('.')
    if i >= 0:
      exp -= (len(s2) - i - 1) << 2
      s2 = s2[:i] + s2[i + 1:]
    expls = exp + (len(s2) << 2)
    try:
      s2 = int(s2, 16)
    except ValueError:
      raise ValueError('Bad hex significand syntax: %r' % s2)
    if not s2:  # Zero.
      return struct.pack('<LLH', 0, 0, sign)
    i = bit_length(s2)
    if exp + i - 64 + 0x403e < -63:
      return struct.pack('<LLH', 0, 0, sign)  # Round down to zero.
    if i <= 64:  # Significand of s2 is short.
      s2 <<= 64 - i
      exp -= 64 - i
      if exp + 0x403e <= 0:  # Subnormal.
        i = -(exp + 0x403d)
        assert i >= 1  # `1 << (a - 1)' below needs it in C.
        is_up = (s2 >> (i - (s2 & ((1 << (i)) - 1) != 1 << (i - 1)))) & 1  # For rounding middle towards even.
        s2 >>= i
        s2 += is_up
        assert not (s2 >> 63)  # This implies from `i >= 1' above.
        return struct.pack('<LLH', s2 & 0xffffffff, s2 >> 32, sign)
    else:  # Significand of s2 is long. Round s2 down to 64 bits.
      is_subnormal = (-63 <= exp + i - 64 + 0x403e <= 0)
      if is_subnormal:
        a = -(exp + 0x403d)
      else:
        a = i - 64
      assert a >= 1  # `1 << (a - 1)' below needs it in C.
      exp += a
      is_up = (s2 >> (a - (s2 & ((1 << (a)) - 1) != 1 << (a - 1)))) & 1  # For rounding middle towards even.
      # is_up = (s2 >> (a - 1)) & 1  # For rounding.
      s2 >>= a
      s2 += is_up
      if is_subnormal:
        assert s2 >> 63 <= 1  # We can't get >= (1 >> 64) even with is_up.
        return struct.pack('<LLH', s2 & 0xffffffff, s2 >> 32, (s2 >> 63) | sign)
      if s2 == (1 << 64):
        s2 >>= 1
        exp += 1
    assert (s2 >> 63) == 1, (bit_length(s2), '0x%x' % s2)
    if exp + 0x403e > 0x7ffe:
      return struct.pack('<LLH', 0, 0x80000000, 0x7fff | sign)  # Round to infinity.
    assert exp + 0x403e > 0
    return struct.pack('<LLH', s2 & 0xffffffff, s2 >> 32, (exp + 0x403e) | sign)  # Normal.
  elif s2 == 'inx':  # Special case.
    s2 = ''
  s2 = s2.lstrip('0').rstrip('lf')
  if not s2:  # Empty string is zero.
    return struct.pack('<LLH', 0, 0, sign)
  i = s2.find('e')
  if i >= 0:
    try:
      exp = int(s2[i + 1:], 10)
    except ValueError:
      raise ValueError('Bad exponent syntax.')
  else:
    exp = 0
    i = len(s2)
  if s2.startswith('.'):  # Remove leading zeros after the '.', for better estimation of `exp' below.
    j = 1
    while len(s2) > j and s2[j] == '0':
      j += 1
    if j > 1:
      s2 = '.' + s2[j:]
      i -= j - 1
      exp -= j - 1
  j = s2[:i].find('.')
  if j >= 0:  # Remove '.'.
    exp -= i - (j + 1)
    s2 = s2[:j] + s2[j + 1 : i]   # We don't need the exp at the end.
    i -= 1
  assert '.' not in s2, (s2, i, j)
  assert not s2.startswith('0'), (s2, i, j)
  assert len(s2) == i or s2[i] == 'e', (s2, i, j)
  if i == 0:  # Zero.
    return struct.pack('<LLH', 0, 0, sign)
  r = 24  # !! TODO(pts): What's wrong with 23, 22, 21 and 20? A few tests fail. What is a safe value?
  if i > r:  # Round long significand.
    #print('A', s2)
    j = int(s2[:r])
    if s2[r] >= '5':  # Round. !! TODO(pts): Test rounding towards even?
      j += 1
    exp += i - r
    s2, i = j, r
  else:
    s2 = int(s2[:i])
  assert s2  # We've already handled zero above.
  if exp + i <= -5000:
    return struct.pack('<LLH', 0, 0, sign)  # Round down to zero.
  if exp + i >= 5000:
    return struct.pack('<LLH', 0, 0x80000000, 0x7fff | sign)  # Round to infinity.
  # Now: -5000 < exp + i < 5000.
  # Now: -5000 - i < exp < 5000 < 5000 + i.
  # Now: 5000 > -exp -i > -5000.
  # Now: -5000 + r >= 5000 + i > -exp > -5000 - i.
  #assert -5000 + r < exp < 5000  # Since i >= 0 and exp + i < 5000.
  i = j = None  # Save memory and clear temporaries.
  must_rshift = False
  if exp >= 0:
    j = 0x403e + exp
    wi = s2 * (5 ** exp)  # This uses large integers and is slow. TODO(pts): Do it with smaller integers.
  else:
    assert -exp < 0x403e
    j = 0
    i = 0x403e + exp  # Left shift amout before division.
    b_min = bit_length(s2) + i - ((23219281 * -exp + 9999999) // 10000000)  # 2.3219281 is an upper bound for log(5)/log(2).
    if b_min >= 65:  # Speed and integer size optimization for the division below.
      i -= b_min - 65
      j += b_min - 65
      must_rshift = True  # Trigger the asertion below.
    # Max i value in the tests: 11510.
    wi = (s2 << i) // (5 ** -exp)  # This use large integers and is slow. Round down (this seems to match glibc and musl). TODO(pts): Which rounding is correct?
    if not wi:
      return struct.pack('<LLH', 0, 0, sign)  # Round down to zero.
  b = bit_length(wi)
  assert not must_rshift or b >= 65
  exp = b + j - 64
  if exp > 0x7ffe:
    return struct.pack('<LLH', 0, 0x80000000, 0x7fff | sign)  # Round to infinity.
  assert (j < exp) == (b >= 65)
  if j < exp:  # Same as: if b >= 65:
    assert exp - j - 1 == b - 65
    wi >>= exp - j - 1
    assert wi >> 64 == 1
    wi = (wi + 1) >> 1  # Round. !! TODO(pts): Test rounding towards even?
    if wi >> 64:
      wi >>= 1
      exp += 1
    assert wi >> 63 == 1
  elif exp <= 0:  # Fix subnormal.
    #print('exp=%d wi=%d' % (exp, wi))
    assert not j  # It's only possible to get subnormal with j == 0 (negative power of 10 exp).
    #wi <<= j  # Not needed since j == 0.
    wi = (wi + 1) >> 1 # Round. !! TODO(pts): Test rounding towards even?
    if not (wi >> 64):
      exp = 0
      if wi >> 63:
        exp = 1
    else:  # !! TODO(pts): Test this. Is it even possible?
      exp = 2
      wi = (wi + 1) >> 1  # Round. !! TODO(pts): Test rounding towards even?
  else:
    assert j >= exp
    wi <<= j - exp
    assert wi >> 63 == 1
  return struct.pack('<LLH', wi & 0xffffffff, wi >> 32, exp | sign)


if __name__ == '__main__':  # Tests.
  #print(str(w)[:200])
  #print(1<<64)
  #for s in ('3.3621031431120935052e-4932L', '3.3621031431120935053e-4932L', '3.3621031431120935054e-4932L', '3.3621031431120935055e-4932L', '3.3621031431120935056e-4932L', '3.3621031431120935057e-4932L',
  #          '3.3621031431120935058e-4932L', '3.3621031431120935059e-4932L', '3.3621031431120935060e-4932L', '3.3621031431120935061e-4932L', '3.3621031431120935062e-4932L', '3.3621031431120935063e-4932L', '3.3621031431120935064e-4932L', '3.3621031431120935065e-4932L', '3.3621031431120935066e-4932L',
  #          '3.3621031431120935067e-4932L', '3.3621031431120935068e-4932L', '3.3621031431120935069e-4932L', '3.3621031431120935070e-4932L', '3.3621031431120935071e-4932L', '3.3621031431120935072e-4932L', '3.3621031431120935073e-4932L', '3.3621031431120935074e-4932L', '3.3621031431120935075e-4932L',
  #          '3.3621031431120935076e-4932L', '3.3621031431120935077e-4932L',):
  #for s in ("1.8225e-4951", "1.8226e-4951", "-1.8226e-4951", "2e-4951", "3e-4951", "3.64519953188247460252840593361941982e-4951", "4e-4951"):
  #  u = struct.unpack('<LLH', strtold(s))
  #  print('%s e/h/l=0x%04x/0x%08x/0x%08x' % (s, u[2], u[1], u[0]))
  #import sys; sys.exit(5)
  #u = struct.unpack('<LLH', strtold('3.3621031431120935060e-4932L'))
  #print('u0=0x%x u1=0x%x u2=0x%x' % (u[0], u[1], u[2]))
  #import sys; sys.exit(5)
  #u = struct.unpack('<LLH', strtold('9.0245045105257814454e+4926'))
  #print('u0=0x%x u1=0x%x u2=0x%x' % (u[0], u[1], u[2]))
  #assert u == (0xaa1d633b, 0xfe857a4f, 0x7fed)
  #import sys; sys.exit(5)

  # Test very long significands.
  u = struct.unpack('<LLH', strtold('7' * 7777 + 'e-2877'))
  print('u0=0x%x u1=0x%x u2=0x%x' % (u[0], u[1], u[2]))
  assert u == (0x45642acf, 0x87c6e6c9, 0x7f94)
  u = struct.unpack('<LLH', strtold('7' * 7777 + '.5678e-2877'))
  print('u0=0x%x u1=0x%x u2=0x%x' % (u[0], u[1], u[2]))
  assert u == (0x45642acf, 0x87c6e6c9, 0x7f94)
  u = struct.unpack('<LLH', strtold('7' * 5040 + '.' + '8' * 2737 + 'e-140'))
  print('u0=0x%x u1=0x%x u2=0x%x' % (u[0], u[1], u[2]))
  assert u == (0x45642acf, 0x87c6e6c9, 0x7f94)
  u = struct.unpack('<LLH', strtold('.' + '7' * 7777 + 'e4900'))
  print('u0=0x%x u1=0x%x u2=0x%x' % (u[0], u[1], u[2]))
  assert u == (0x45642acf, 0x87c6e6c9, 0x7f94)
  u = struct.unpack('<LLH', strtold('0' * 3456 + '.' + '0' * 10000 + '7' * 7777 + 'e14900'))
  print('u0=0x%x u1=0x%x u2=0x%x' % (u[0], u[1], u[2]))
  assert u == (0x45642acf, 0x87c6e6c9, 0x7f94)

  u = struct.unpack('<LLH', strtold('2'))
  print('u0=0x%x u1=0x%x u2=0x%x' % (u[0], u[1], u[2]))
  assert u == (0, 0x80000000, 0x4000)
  u = struct.unpack('<LLH', strtold('1'))
  print('u0=0x%x u1=0x%x u2=0x%x' % (u[0], u[1], u[2]))
  assert u == (0, 0x80000000, 0x3fff)
  u = struct.unpack('<LLH', strtold('0.5'))
  print('u0=0x%x u1=0x%x u2=0x%x' % (u[0], u[1], u[2]))
  assert u == (0, 0x80000000, 0x3ffe)
  u = struct.unpack('<LLH', strtold('0'))
  print('u0=0x%x u1=0x%x u2=0x%x' % (u[0], u[1], u[2]))
  assert u == (0, 0, 0)
  u = struct.unpack('<LLH', strtold('-0'))
  print('u0=0x%x u1=0x%x u2=0x%x' % (u[0], u[1], u[2]))
  assert u == (0, 0, 0x8000)
  u = struct.unpack('<LLH', strtold('1.8000320949558996187e-4837'))
  print('u0=0x%x u1=0x%x u2=0x%x' % (u[0], u[1], u[2]))
  assert u == (0xcab669c7, 0xcd557719, 0x013b)
  u = struct.unpack('<LLH', strtold('-1.8000320949558996187e-4837'))
  print('u0=0x%x u1=0x%x u2=0x%x' % (u[0], u[1], u[2]))
  assert u == (0xcab669c7, 0xcd557719, 0x813b)
  u = struct.unpack('<LLH', strtold('9.0245045105257814454e+4926'))
  print('u0=0x%x u1=0x%x u2=0x%x' % (u[0], u[1], u[2]))
  assert u == (0xaa1d633b, 0xfe857a4f, 0x7fed)
  u = struct.unpack('<LLH', strtold('-9.0245045105257814454e+4926'))
  print('u0=0x%x u1=0x%x u2=0x%x' % (u[0], u[1], u[2]))
  assert u == (0xaa1d633b, 0xfe857a4f, 0xffed)
  print([struct.pack('<LLH', *u)])  # 10-byte x86 representation.
  print([struct.pack('<LLL', *u)])  # 12-byte x86 representation.
  print([struct.pack('<LLL4x', *u)])  # 16-byte x86 representation.
  import ast, os, os.path, sys
  failc = 0
  f = open(os.path.join(os.path.dirname(__file__), '..', 'test', 'test_strtold.c'))
  try:
    for line in iter(f.readline, ''):
      line = line.strip()
      if line.startswith('expect(') and ';' in line:
        line = line[line.find('('):]
        line = line[:line.find(';')]
        line = line.replace('U', '')
        line = ast.literal_eval(line)
        name, s, exp, high, low = line
        if not isinstance(name, str):
          raise TypeError
        if not isinstance(s, str):
          raise TypeError
        if not isinstance(exp, (int, long)):
          raise TypeError
        if not isinstance(high, (int, long)):
          raise TypeError
        if not isinstance(low, (int, long)):
          raise TypeError
        s2 = s.lstrip()
        if not name:
          name = s2
        try:
          glow, ghigh, gexp = struct.unpack('<LLH', strtold(s))
          e = None
        except ValueError:
          e = repr(sys.exc_info()[1])
        except:
          print((name, s))
          raise
        if e is None:
          if glow != low or ghigh != high or gexp != exp:
            print((name, s, exp, high, low, gexp, ghigh, glow))
            failc += 1
        else:
          print((name, s, e))
          failc += 1
  finally:
    f.close()
  if failc:
    sys.stderr.write('info: %d failure%s\n' % (failc, 's' * (failc != 1)))
    sys.exit(2)
  else:
    sys.stderr.write('info: all OK\n')
