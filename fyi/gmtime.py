# by pts@fazekas.hu at Sat Jun 30 01:19:14 CEST 2012

import time

try:
  long
except NameError:
  long = int  # For Python 3 compatibility.

try:
  xrange
except NameError:
  xrange = range  # For Python 3 compatibility.

def gmtime(ts):
  # Python (-10)/7==-2,  Ruby (-10)/7==-2,  Perl (-10)/7==-1
  # See also http://ptspts.blogspot.com/2009/11/how-to-convert-unix-timestamp-to-civil.html
  assert isinstance(ts, (int, long))
  # The int... types below work without overflow if ts is int32_t.
  t = ts
  t, hms = divmod(ts, 86400)  # int16_t t; int32_t hms;
  if hms < 0:  # Can be true in Perl or C. Always false in Python and Ruby.
    t -= 1
    hms += 86400
  hms, ss = divmod(hms, 60)  # uint8_t ss;  Use hms as uint32_t.
  hh, mm = divmod(hms, 60)  # uint8_t mm; uint8_t hh; Use hms as uint32_t.
  wday = (t + 3) % 7  # uint8_t.
  assert 0 <= wday <= 6
  if -0x80000000 <= ts <= 0x7fffffff:
    assert -24856 <= t <= 24855
    assert 2608 <= t * 4 + 102032 <= 201452
  f = (t * 4 + 102032) // 146097 - 1  # int32_t only if ts is 64 bits.
  if -0x80000000 <= ts <= 0x7fffffff:
    assert -1 <= f <= 0
    assert f - (f >> 2) == 0
  b = t  # Just for the `assert'.
  t += f - (f >> 2)  # int16_t.
  if -0x80000000 <= ts <= 0x7fffffff:
    assert b == t
    assert -24856 <= t <= 24855
    assert 13058 <= t * 20 + 510178 <= 1007278
  c = (t * 20 + 510178) // 7305  # uint8_t.
  if -0x80000000 <= ts <= 0x7fffffff:
    assert 1 <= c <= 137
  yday = t - 365 * c - (c >> 2) + 25569  # uint16_t.
  assert 1 <= yday <= 426
  a = yday * 100 + 3139  # uint16_t.
  assert 3239 <= a <= 45739
  m, g = divmod(a, 3061)  # uint8_t m; uint16_t g;
  assert 3 <= m <= 14
  assert 0 <= g <= 3060
  d = 1 + g // 100  # uint8_t.
  assert 1 <= d <= 31
  y = c + 1900  # uint16_t.
  if -0x80000000 <= ts <= 0x7fffffff:
    assert 1901 <= y <= 2038
    if not (y & 3):
      assert ((y >> 2) % 100) not in (25, 50, 75)
  if m > 12:
    m -= 12
    y += 1
    yday -= 366
  elif y & 3 or ((y >> 2) % 100) in (25, 50, 75):
    yday -= 1
  if -0x80000000 <= ts <= 0x7fffffff:
    assert 1901 <= y <= 2038
  assert 1 <= m <= 12
  assert 1 <= yday <= 366
  # In C, we have to return m-1, yday-1.
  return y, m, d, hh, mm, ss, wday, yday

#def timestamp_to_gmt_civil(ts)
#  s = ts%86400
#  ts /= 86400
#  h = s/3600
#  m = s/60%60
#  s = s%60
#  x = (ts*4+102032)/146097+15
#  b = ts+2442113+x-(x/4)
#  c = (b*20-2442)/7305
#  d = b-365*c-c/4
#  e = d*1000/30601
#  f = d-e*30-e*601/1000
#  (e < 14 ? [c-4716,e-1,f,h,m,s] : [c-4715,e-13,f,h,m,s])
#end

def good(ts):
  # This needs a 64-bit system for high values of ts.
  t = time.gmtime(ts)
  # !! t.tm_yday
  return (t.tm_year, t.tm_mon, t.tm_mday, t.tm_hour, t.tm_min, t.tm_sec, t.tm_wday, t.tm_yday)


if __name__ == '__main__':
  #gmtime(-0x80000000)
  #gmtime(0x7fffffff)
  assert gmtime(0) == good(0) == (1970, 1, 1, 0, 0, 0, 3, 1), (gmtime(0), good(0))
  assert gmtime(15398 * 86400) == good(15398 * 86400) == (2012, 2, 28, 0, 0, 0, 1, 59)
  assert gmtime(15399 * 86400) == good(15399 * 86400) == (2012, 2, 29, 0, 0, 0, 2, 60)
  assert gmtime(15400 * 86400) == good(15400 * 86400) == (2012, 3, 1, 0, 0, 0, 3, 61)
  assert gmtime(946684800 - 86400) == good(946684800 - 86400) == (1999, 12, 31, 0, 0, 0, 4, 365)
  assert gmtime(946684800) == good(946684800) == (2000, 1, 1, 0, 0, 0, 5, 1)
  assert gmtime(951696000) == good(951696000) == (2000, 2, 28, 0, 0, 0, 0, 59)
  assert gmtime(951696000 + 86400) == good(951696000 + 86400) == (2000, 2, 29, 0, 0, 0, 1, 60)

  assert gmtime(-0x80000000) == good(-0x80000000) == (1901, 12, 13, 20, 45, 52, 4, 347)
  assert gmtime(-0x70000000) == good(-0x70000000)
  assert gmtime(-0x60000000) == good(-0x60000000)
  assert gmtime(-0x50000000) == good(-0x50000000)
  assert gmtime(-0x40000000) == good(-0x40000000)
  assert gmtime(-0x30000000) == good(-0x30000000)
  assert gmtime(-0x20000000) == good(-0x20000000)
  assert gmtime(-0x10000000) == good(-0x10000000)
  assert gmtime(0) == good(0) == (1970, 1, 1, 0, 0, 0, 3, 1)
  assert gmtime(0x10000000) == good(0x10000000)
  assert gmtime(0x20000000) == good(0x20000000)
  assert gmtime(0x7fffffff) == good(0x7fffffff) == (2038, 1, 19, 3, 14, 7, 1, 19)
  assert gmtime(107370570 * 86400) == good(107370570 * 86400) == (
      295940, 8, 21, 0, 0, 0, 2, 234)
  for i in xrange(-10000 * 86400, 10000 * 86400, 86400):
    assert gmtime(i) == good(i)
  for i in xrange(-110123 * 86400 + 45678, 110000 * 86400, 8640000):
    assert gmtime(i) == good(i)
  for i in xrange(-1101234 * 86400 + 34567, 1100000 * 86400, 86400000):
    assert gmtime(i) == good(i)
  for i in xrange(-11012345 + 86400 + 12345, 11000000 * 86400, 864000000):
    assert gmtime(i) == good(i)
  for i in xrange(-11012345 + 86400 + 12345, 11000000 * 86400, 863210987):
    assert gmtime(i) == good(i)
  print('OK')
