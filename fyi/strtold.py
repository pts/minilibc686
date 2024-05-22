#
# strtold.py: strtold(...) for x86 f80 long double
# by pts@fazekas.hu at Wed May 22 00:23:55 CEST 2024
#
# This implementation works in Python 2.7 and 3.x. It's
# architecture-independent.
#
# This implementation is believed to be correct and accurate. See accuracy
# tests in tests/test_strtold.c. The alternative Python implementation in
# fyi/strtold.py passes the same accuracy tests. The C implementation in
# fyi/c_strtold.c passes the same tests.
#

import decimal
import struct


try:  # Polyfill for Python 2.x.
  range = xrange
except NameError:
  pass
try:  # Polyfill for Python 3.x.
  long
except NameError:
  long = int


def strtold(s, _c=decimal.Context(prec=5500), _c130=decimal.Context(prec=130), _p63=[], _prs=[]):
  # TODO(pts): Add proper implementation.
  #
  # This implementations is much slower in Python 2.7 than Python 3.
  if isinstance(s, str):
    s = s.lstrip().lower()
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
      if expls > 0x4003:
        return struct.pack('<LLH', 0, 0x80000000, 0x7fff | sign)  # Round to infinity.
      elif expls < -0x4040:
        return struct.pack('<LLH', 0, 0, sign)  # Round down to zero.
      # !! TODO(pts): Build it manually, don't create temporary Decimal.
      if exp < 0:
        exp = -exp
        j, expp = 0, exp
        while expp:
          j += 1
          expp >>= 1
        if not _prs:
          _prs[:1] = ((_c.create_decimal(2), _c.create_decimal('.5')),)  # Thread-safe append.
        while len(_prs) < j:
          i = len(_prs)
          p, r = _prs[i - 1]
          _prs[i : i + 1] = ((_c.multiply(p, p), _c.multiply(r, r)),)  # Thread-safe append.
        m = _c.create_decimal(1)
        j = 0
        while exp >= (1 << j):
          if exp & (1 << j):
            m = _c.multiply(m, _prs[j][1])
          j += 1
        s2 = str(_c.multiply(_c.create_decimal(s2), m))
      else:
        s2 = str(s2 << exp)
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
      exp = i = 0
    exp += s2[:i].find('.') + 1  # Now exp becomes the approximate base 10 exponent.
    if exp <= -5000:
      return struct.pack('<LLH', 0, 0, sign)  # Round down to zero.
    if exp >= 5000:
      return struct.pack('<LLH', 0, 0x80000000, 0x7fff | sign)  # Round to infinity.
    s = s2
    if sign:
      s = '-' + s
  v = _c.create_decimal(s)  # This may raise any exception.
  if _c.is_nan(v):
    return struct.pack('<LLH', 0, 0xc0000000, 0x7fff)
  if _c.is_signed(v):
    sign = 0x8000
    v = _c.copy_negate(v)
  else:
    sign = 0
  if _c.is_infinite(v):
    return struct.pack('<LLH', 0, 0x80000000, 0x7fff | sign)
  if _c.is_zero(v):
    return struct.pack('<LLH', 0, 0, sign)
  if not _p63:
    _p63[:1] = (_c130.create_decimal(1 << 63),)  # Thread-safe append.
  v = _c.normalize(v)
  vlb = _c.logb(v)  # The base 10 exponent of v in scientific notation.
  if vlb < -4951:
    return struct.pack('<LLH', 0, 0, sign)  # Round down to zero.
  if vlb > 4932:
    return struct.pack('<LLH', 0, 0x80000000, 0x7fff | sign)  # Round to infinity.
  is_at_least_1 = v >= 1
  if (is_at_least_1 and (not _prs or v >= _prs[-1][0])) or (not is_at_least_1 and (not _prs or v <= _prs[-1][1])):
    # Populate _prs, it will have at most 15 elements. prs[i] will be (Decimal(2) ** (i + 1), Decimal('.5') ** (i + 1)).
    if not _prs:
      _prs[:1] = ((_c.create_decimal(2), _c.create_decimal('.5')),)  # Thread-safe append.
    if is_at_least_1:
      while v >= _prs[-1][0]:
        i = len(_prs)
        p, r = _prs[i - 1]
        _prs[i : i + 1] = ((_c.multiply(p, p), _c.multiply(r, r)),)  # Thread-safe append.
    else:
      while v <= _prs[-1][1]:
        i = len(_prs)
        p, r = _prs[i - 1]
        _prs[i : i + 1] = ((_c.multiply(p, p), _c.multiply(r, r)),)  # Thread-safe append.
  w = v
  exp = 0x3fff
  if is_at_least_1:
    i = 1
    while i != len(_prs) and w >= _prs[i][0]:
      i += 1
    while i:
      i -= 1
      if w >= _prs[i][0]:
        w = _c.multiply(w, _prs[i][1])
        exp += 1 << i
        assert w < _prs[i][0]  # TODO(pts): Simplify the loop.
  else:
    i = 1
    while i != len(_prs) and w <= _prs[i][1]:
      i += 1
    while i:
      i -= 1
      if w <= _prs[i][1]:
        w = _c.multiply(w, _prs[i][0])
        exp -= 1 << i
        assert w > _prs[i][1]  # TODO(pts): Simplify the loop.
    #assert 1 < w + w <= 2  # !! Allow a small rounding error near 2.
    if w < 1:
      w = _c.add(w, w)
      exp -= 1
  assert 1 <= w < 2
  if -0x40 < exp < 0:  # Subnormal.
    w = _c130.multiply(_c130.normalize(w), 1 << (63 + exp))  # Multiply by 1 << less_than_63.
    exp = 0
  else:
    w = _c130.multiply(_c130.normalize(w), _p63[0])  # Multiply by 1 << 63.
  #print(w, exp)
  wi = int(_c130.to_integral_value(w))
  if wi >> 64:
    if wi != 0x10000000000000000:  # We can get this because of a rounding error in .to_integral_value(...) above.
      raise AssertError('Significand too large.')
    wi >>= 1
    exp += 1
  if exp >= 0x7fff:  # Round to infinity.
    exp, wi = 0x7fff, 1 << 63
  elif exp < 0:  # Round down to zero.
    exp = wi = 0
  return struct.pack('<LLH', wi & 0xffffffff, wi >> 32, exp | sign)


if __name__ == '__main__':  # Tests.
  #_c=decimal.Context(prec=8500)
  #v = _c.create_decimal('3.3621031431120935061e-4932')
  #w = _c.multiply(v, _c.power(_c.create_decimal(2), 0x403e))
  #print(str(w)[:200])
  #print(1<<64)
  #u = struct.unpack('<LLH', strtold('3.3621031431120935061e-4932L'))
  #print('u0=0x%x u1=0x%x u2=0x%x' % (u[0], u[1], u[2]))
  #import sys; sys.exit(5)

  #u = struct.unpack('<LLH', strtold('3.3621031431120935060e-4932L'))
  #print('u0=0x%x u1=0x%x u2=0x%x' % (u[0], u[1], u[2]))
  #import sys; sys.exit(5)

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
