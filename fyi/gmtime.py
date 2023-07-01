# by pts@fazekas.hu at Sat Jun 30 01:19:14 CEST 2012, revised on 2022-06-23

import calendar
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
  # Python (-10)//7==-2,  Ruby (-10)//7==-2,  Perl (-10)//7==-1,  C (-10)//7==-1.
  # We accept either behavior here. All divisions (/, % and divmod) are done properly even for negative dividend.
  # See also http://ptspts.blogspot.com/2009/11/how-to-convert-unix-timestamp-to-civil.html
  assert isinstance(ts, (int, long))
  is_i32 = ts >> 31 in (0, -1)
  is_i64 = ts >> 63 in (0, -1)
  # The int... types below work without overflow if ts is int32_t.
  t = ts
  t, hms = divmod(ts, 86400)  # int16_t t; int32_t hms;
  if hms < 0:  # Can be true in Perl or C. Always false in Python and Ruby.
    t -= 1
    hms += 86400
  hms, ss = divmod(hms, 60)  # uint8_t ss;  Use hms as uint32_t.
  hh, mm = divmod(hms, 60)  # uint8_t mm; uint8_t hh; Use hms as uint32_t.
  wday = (t + 3) % 7  # uint8_t.
  if wday < 0:  # Can be true in Perl or C. Always false in Python and Ruby.
    wday += 7
  assert 0 <= wday <= 6
  if is_i32:
    assert -24856 <= t <= 24855
    assert 2608 <= (t << 2) + 102032 <= 201452
  elif is_i64:
    assert -106751991167301 <= t <= 106751991167300
  f, fm = divmod(((t << 2) + 102032), 146097)
  if fm < 0:  # Can be true in Perl or C. Always false in Python and Ruby. Always false if is_i32.
    f -= 1
    #fm += 102032  # We don't care about fm.
  f -= 1  # int32_t only if ts is 64 bits.
  if is_i32:
    assert -1 <= f <= 0
    assert f - (f >> 2) == 0
    b = t
  else:
    if is_i64:
      assert -2922770247 <= f <= 2922770245
      assert -2192077685 <= f - (f >> 2) <= 2192077684
    f -= f >> 2
    b = t
    if f:  # Always false if is_i32.
      b += f
  if is_i32:
    assert b == t
    assert -24856 <= t <= 24855
    assert 13058 <= t * 20 + 510178 <= 1007278
    c = ((b << 2) + 102035) // 1461  # uint8_t.
  else:
    if is_i64:
      assert -106754183244986 <= b <= 106754183244984
      assert -2135083664389542 <= b * 20 + 510178 <= 2135083665409858
    c, cm = divmod((b << 2) + 102035, 1461)  # c is still uint64_t.
    if cm < 0:
      c -= 1
      #cm += 1461  # We don't care about cm.
  if is_i32:
    assert 1 <= c <= 137
  elif is_i64:
    assert -292277024558 <= c <= 292277024696
  yday = b - 365 * c - (c >> 2) + 25569  # uint16_t.
  assert 1 <= yday <= 426
  if 0:
    a = yday * 100 + 3139  # uint16_t.
    assert 3239 <= a <= 45739
    m, g = divmod(a, 3061)  # uint8_t m; uint16_t g; This is a nonnegative division (a >= 0).
    assert 0 <= g <= 3060
    d = 1 + g // 100  # uint8_t. This is a nonnegative division (g >= 100).
  elif 0:  # This is better suited for C code, where `struct tm' has `yday - 1' and `m - 1'.
    a = (yday - 1) * 100 + 178  # uint32_t.
    assert 0 <= a <= 42678
    m, g = divmod(a, 3061)  # uint8_t m; uint16_t g; This is a nonnegative division (a >= 0).
    assert 0 <= g <= 3060
    m += 1
    d = 1 + g // 100  # uint8_t. This is a nonnegative division (g >= 100).
  elif 1:
    a = yday * 5 + 156
    assert 161 <= a <= 2286
    m, g = divmod(a, 153)
    assert 0 <= g <= 153
    d = 1 + g // 5
  else:  # This is better suited for C code, where `struct tm' has `yday - 1' and `m - 1'.
    a = (yday - 1) * 5 + 8
    assert 8 <= a <= 2133
    m, g = divmod(a, 153)
    assert 0 <= g <= 153
    m += 1
    d = 1 + g // 5
  assert 3 <= m <= 14
  assert m == (yday + 123) * 5 // 153 - 3
  assert 1 <= d <= 31
  assert d == yday + 62 - (m + 1) * 30 - (m + 1) * 601 // 1000
  assert d == yday + 32 - m * 30 - (m + 1) * 601 // 1000
  assert d == yday + 32 - m * 30 - (m + 1) * 61 // 100
  assert d == yday + 32 - m * 30 - (m + 1) * 3 // 5
  assert d == yday + 32 - ((m * 979 + 25) >> 5)
  assert d == yday - ((m * 979 - 999) >> 5)
  assert d == 1 + ((yday + 123) * 5 % 153) // 5
  assert m == ((yday + 123) * 5 // 153) - 3
  assert yday == 3 * (m + 1) // 5 + 30 * m + d - 32
  assert yday == (153 * m - 157) // 5 + d
  y = c + 1900  # uint16_t.
  if is_i32:
    assert 1901 <= y <= 2038
    if not (y & 3):
      assert ((y >> 2) % 100) not in (25, 50, 75)
  if m > 12:
    m -= 12
    y += 1
    yday -= 366
  elif y & 3:
    yday -= 1
  elif ((y >> 2) % 100) in (25, 50, 75, -25, -50, -75):  # not isleap(y).
    assert not is_i32
    yday -= 1
  if is_i32:
    assert 1901 <= y <= 2038
  assert 1 <= m <= 12
  assert 1 <= yday <= 366
  assert yday == t - 365 * y - ((y - 1) >> 2) + ((y - 1) // 100) - ((y - 1) // 400) + 719528
  # In C, we have to return m-1, yday-1.
  return y, m, d, hh, mm, ss, wday, yday


def gmtime_impl1(ts):
  # Based on: http://ptspts.blogspot.com/2009/11/how-to-convert-unix-timestamp-to-civil.html
  # Python (-10)//7==-2,  Ruby (-10)//7==-2,  Perl (-10)//7==-1,  C (-10)//7==-1.
  # We require the Python/Ruby behavior here.
  t, hms = divmod(ts, 86400)
  hms, ss = divmod(hms, 60)  # uint8_t ss;  Use hms as uint32_t.
  hh, mm = divmod(hms, 60)  # uint8_t mm; uint8_t hh; Use hms as uint32_t.
  wday = (t + 3) % 7
  assert 0 <= wday <= 6
  f = ((t << 2) + 102032) // 146097 - 1
  f -= f >> 2
  b = t
  if f:  # Always false if ts is int32_t.
    b += f
  c = ((b << 2) + 102035) // 1461
  yday = b - 365 * c - (c >> 2) + 25569
  assert 1 <= yday <= 426
  a = (yday + 123) * 5
  m, g = divmod(a, 153)
  d = 1 + g // 5
  assert 1 <= d <= 31
  m -= 3
  assert 3 <= m <= 14
  assert yday == 3 * (m + 1) // 5 + 30 * m + d - 32
  assert yday == (153 * m - 157) // 5 + d
  y = c + 1900
  if m > 12:
    m -= 12
    y += 1
    yday -= 366
  elif y & 3 or ((y >> 2) % 100) in (25, 50, 75):  # not isleap(y).
    yday -= 1
  assert yday == t - 365 * y - ((y - 1) >> 2) + ((y - 1) // 100) - ((y - 1) // 400) + 719528
  return y, m, d, hh, mm, ss, wday, yday


def gmtime_impl0(ts):
  # Directly based on: http://ptspts.blogspot.com/2009/11/how-to-convert-unix-timestamp-to-civil.html
  # Python (-10)//7==-2,  Ruby (-10)//7==-2,  Perl (-10)//7==-1,  C (-10)//7==-1.
  # We require the Python/Ruby behavior here.
  t, s = divmod(ts, 86400)
  hh = s // 3600
  mm = s // 60 % 60
  ss = s % 60
  wday = (t + 3) % 7
  x = (t * 4 + 102032) // 146097 + 15
  b = t + 2442113 + x - (x >> 2)
  c = (b * 20 - 2442) // 7305
  yday = b - 365 * c - (c >> 2)
  e = yday * 1000 // 30601
  d = yday - e * 30 - e * 601 // 1000
  if e < 14:
    y, m = c - 4716, e - 1
    yday -= 63
    if (y & 3) == 0 and (y % 100 != 0 or y % 400 == 0):  # isleap(y).
      yday += 1
  else:
    y, m = c - 4715, e - 13
    yday -= 428
  return y, m, d, hh, mm, ss, wday, yday


def gmtime_newlib(ts):
  # Based on newlib/libc/time/gmtime_r.c in Newlib 4.3.0
  # https://sourceware.org/git/?p=newlib-cygwin.git;a=blob;f=newlib/libc/time/gmtime_r.c;h=8bf9ee52dd1e54e39d2b1516b0208375104e4415;hb=9e09d6ed83cce4777a5950412647ccc603040409
  # Python (-10)//7==-2,  Ruby (-10)//7==-2,  Perl (-10)//7==-1,  C (-10)//7==-1.
  # We accept either behavior here. All divisions (/, % and divmod) are done properly even for negative dividend.
  t = ts
  t, hms = divmod(ts, 86400)  # int16_t t; int32_t hms;
  if hms < 0:  # Can be true in Perl or C. Always false in Python and Ruby.
    t -= 1
    hms += 86400
  hms, ss = divmod(hms, 60)  # uint8_t ss;  Use hms as uint32_t.
  hh, mm = divmod(hms, 60)  # uint8_t mm; uint8_t hh; Use hms as uint32_t.
  wday = (t + 4) % 7
  if wday < 0:  # Not needed in Python.
    wday += 7
  days = t + 719468
  era = days
  #if days < 0:
  #  era -= 146097 - 1  # !! Why this behavior with negative days? For rounding? This breaks compatibility.
  era, eraday = divmod(days, 146097)
  if eraday < 0:  # Can be true in Perl or C. Always false in Python and Ruby.
    era -= 1
    eraday += 146097
  assert 0 <= eraday <= 146097
  erayear = (eraday - eraday // ((3 * 365 + 366) - 1) + eraday // 36524 - eraday // (146097 - 1)) // 365
  assert 0 <= erayear <= 399
  yearday = eraday - (365 * erayear + erayear // 4 - erayear // 100)
  assert 0 <= yearday <= 365
  month = (5 * yearday + 2) // 153
  assert 0 <= month <= 11
  day = yearday - (153 * month + 2) // 5 + 1
  assert 1 <= day <= 31
  year = erayear + era * 400
  if month < 10:
    month += 2
  else:
    month -= 10
    year += 1
  if yearday >= 365 - 31 - 28:
    yday = yearday - (365 - 31 - 28)
  else:
    yday = yearday + 31 + 28
    if (erayear & 3) == 0 and (erayear % 100 != 0 or erayear % 400 == 0):  # isleap(erayear).
      yday += 1
  return year, month + 1, day, hh, mm, ss, (wday + 6) % 7, yday + 1


def timegm(y, m, d, h, mi, s):
  # Based on: http://ptspts.blogspot.com/2009/11/how-to-convert-unix-timestamp-to-civil.html
  # Python (-10)//7==-2,  Ruby (-10)//7==-2,  Perl (-10)//7==-1,  C (-10)//7==-1.
  # We require the Python/Ruby behavior here.
  if m <= 2:
    y -= 1
    m += 12
  y4 = y >> 2
  y100 = y4 // 25
  t = 365 * y + y4 - y100 + (y100 >> 2) + (153 * m + 3) // 5 + d - (398 + 719163)
  return t * 86400 + 3600 * h + 60 * mi + s


def timegm_smart(y, m, d, h, mi, s, wday=None, yday=None):
  # It doesn't use wday.
  # Based on POSIX : https://stackoverflow.com/questions/9745255/minimal-implementation-of-gmtime-algorithm
  # https://stackoverflow.com/a/9745438
  # Python (-10)//7==-2,  Ruby (-10)//7==-2,  Perl (-10)//7==-1,  C (-10)//7==-1.
  # We require the Python/Ruby behavior here.
  yday0 = yday  # Just for the assert.
  if yday is None:
    if m <= 2:
      y -= 1
      m += 12
    yday = (153 * m + 3) // 5 + d - 398
  else:
    y -= 1
  y4 = y >> 2
  y100 = y4 // 25
  t = 365 * y + y4 - y100 + (y100 >> 2) + yday - 719163
  if yday0 is not None and m is not None and d is not None:  # Just the assert checking that (y, yday) matches (y, m, d).
    y += 1
    if m <= 2:
      y -= 1
      m += 12
    yday = (153 * m + 3) // 5 + d - 398
    y4 = y >> 2
    y100 = y4 // 25
    assert t == 365 * y + y4 - y100 + (y100 >> 2) + yday - 719163
  return t * 86400 + 3600 * h + 60 * mi + s


def timegm_posix(y, m, unused_d, h, mi, s, unused_wday, yday):
  # POSIX: http://pubs.opengroup.org/onlinepubs/9699919799/basedefs/V1_chap04.html#tag_04_15
  # https://stackoverflow.com/questions/9745255/minimal-implementation-of-gmtime-algorithm
  # https://stackoverflow.com/a/9745438
  # Python (-10)//7==-2,  Ruby (-10)//7==-2,  Perl (-10)//7==-1,  C (-10)//7==-1.
  # We require the Python/Ruby behavior here.
  y -= 1900
  return ((y - 70) * 365 + ((y - 69) >> 2) - ((y - 1) // 100) + ((y + 299) // 400) + (yday - 1)) * 86400 + 3600 * h + 60 * mi + s


def expect(ts, expected_tm=None, is_time_gmtime_buggy=False):
  tm1 = gmtime(ts)
  tm3 = gmtime_newlib(ts)
  tm4 = gmtime_impl0(ts)
  tm5 = gmtime_impl1(ts)
  if is_time_gmtime_buggy:
    tm2 = tm3
  else:
    try:
      t = time.gmtime(ts)
      # This needs a 64-bit system for high values of ts.
      tm2 = (t.tm_year, t.tm_mon, t.tm_mday, t.tm_hour, t.tm_min, t.tm_sec, t.tm_wday, t.tm_yday)
    except (ValueError, OSError, OverflowError):
      if ts >> 55 in (0, -1):  # Not an overflow in time.gmtime(...).
        raise
      tm2 = tm3
  t = None
  if expected_tm is None:
    expected_tm = tm3
  if not (tm1 == tm2 == tm3 == tm4 == tm5 == expected_tm):
    if tm1 == tm3 == tm4 == tm5 == expected_tm:
      assert 0, ('bad_tm2', ts, tm1, tm2, tm3, tm4, tm5, expected_tm)
    else:
      assert 0, ('bad_tms', ts, tm1, tm2, tm3, tm4, tm5, expected_tm)
  tm = tm1[:6]
  ts1 = timegm(*tm)
  try:
    ts2 = calendar.timegm(tm)
  except (ValueError, OverflowError):  # It fails for very small and very large years.
    tm_fixed = list(tm)
    year = tm_fixed[0]
    tm_fixed[0] = 2000 + year % 400
    ts2 = calendar.timegm(tm_fixed)
    ts2 += (year - tm_fixed[0]) * (146097 * 86400 // 400)
  ts3 = timegm_posix(*tm1)
  ts4 = timegm_smart(*tm1)
  ts4 = timegm_smart(*tm1[:6])
  assert ts1 == ts2 == ts3 == ts4 == ts, (ts, tm, ts1, ts2, ts3, ts4, ts)


def do_test():
  expect(0, (1970, 1, 1, 0, 0, 0, 3, 1))
  expect(15398 * 86400, (2012, 2, 28, 0, 0, 0, 1, 59))
  expect(15399 * 86400, (2012, 2, 29, 0, 0, 0, 2, 60))
  expect(15400 * 86400, (2012, 3, 1, 0, 0, 0, 3, 61))
  expect(946684800 - 86400, (1999, 12, 31, 0, 0, 0, 4, 365))
  expect(946684800, (2000, 1, 1, 0, 0, 0, 5, 1))
  expect(951696000, (2000, 2, 28, 0, 0, 0, 0, 59))
  expect(951696000 + 86400, (2000, 2, 29, 0, 0, 0, 1, 60))
  expect(-0x80000000, (1901, 12, 13, 20, 45, 52, 4, 347))
  expect(0x7fffffff, (2038, 1, 19, 3, 14, 7, 1, 19))
  expect(107370570 * 86400, (295940, 8, 21, 0, 0, 0, 2, 234))
  expect(-67768100567971200, (-0x80000000, 1, 1, 0, 0, 0, 1, 1))  # Smallest where tm_year fits to an int32_t.
  expect(67767976233532799, (0x7fffffff, 12, 31, 23, 59, 59, 1, 365), True)  # Largest where tm_year fits to an int32_t.
  expect(-67768040609740800, (-0x80000000 + 1900, 1, 1, 0, 0, 0, 3, 1))  # Smallest where tm_year-1900 fits to an int32_t.
  expect(67768036191676799, (0x7fffffff + 1900, 12, 31, 23, 59, 59, 2, 365))  # Largest where tm_year-1900 fits to an int32_t.
  expect(9007199227497599, (285428750, 12, 31, 23, 59, 59, 6, 365))
  expect(9007199259033599, (285428751, 12, 31, 23, 59, 59, 0, 365), True)  # Python time.gmtime (glibc 2.27) returns off-by-one day from this year.
  for ts in xrange(-0x80000000, 0x80000000, 0x1000000):  # 256 iterations.
    expect(ts)
  for ts in xrange(-10000 * 86400, 10000 * 86400, 86400):
    expect(ts)
  for ts in xrange(-110123 * 86400 + 45678, 110000 * 86400, 8640000):
    expect(ts)
  for ts in xrange(-1101234 * 86400 + 34567, 1100000 * 86400, 86400000):
    expect(ts)
  for ts in xrange(-11012345 + 86400 + 12345, 11000000 * 86400, 864000000):
    expect(ts)
  for ts in xrange(-11012345 + 86400 + 12345, 11000000 * 86400, 863210987):
    expect(ts)
  for i in xrange(-62):
    expect(1 << i)
    expect((1 << i) - 1)
    expect(-1 << i)
    expect((-1 << i) - 1)
  expect(1 << 63)
  expect((1 << 63) - 1)
  #expect(4523176237161599)
  #for dy in xrange(-1000, 10000):
  #  ts = timegm(285428751 + dy, 12, 31, 23, 59, 59)
  #  print dy, ts, (285428751 + dy, 12, 31, 23, 59, 59)
  #  expect(ts)
  #print gmtime(67767976233532799 - 2000000000 * 366 * 24 * 3600)


if __name__ == '__main__':
  do_test()
  print('OK')
