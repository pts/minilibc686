#! /usr/bin/python
#
# localtime: Python reference implementation of localtime(3) in Python with parsing of Linux tzfile(5) files
# by pts@fazekas.hu at Sun Jun  2 01:21:17 CEST 2024
#
# Based on: https://man7.org/linux/man-pages/man5/tzfile.5.html
#

import bisect
import os
import struct
import sys
import time


def parse_tzfile(filename):
  """Loads and parses a Linux tzfile (time zone information file), returns tzinfo data structure."""
  f = open(filename, 'rb')
  print filename
  try:
    data = f.read(44)
    if len(data) != 44:
      raise ValueError('tzfile too short.')
    if not data.startswith('TZif'):
      raise ValueError('Bad tzfile signature.')
    version, tzh_ttisgmtcnt, tzh_ttisstdcnt, tzh_leapcnt, tzh_timecnt, tzh_typecnt, tzh_charcnt = struct.unpack('>4xc15x6L', data)
    if version == '\0':  # Version can be: '\0', '2, '3', '4' etc.
      version = '1'
    print(version, tzh_ttisgmtcnt, tzh_ttisstdcnt, tzh_leapcnt, tzh_timecnt, tzh_typecnt, tzh_charcnt)
    data = f.read(tzh_timecnt << 2)
    if len(data) != tzh_timecnt << 2:
      raise ValueError('EOF in transition times.')
    transition_times = struct.unpack('>%dl' % tzh_timecnt, data)
    print transition_times
    data = f.read(tzh_timecnt)
    if len(data) != tzh_timecnt:
      raise ValueError('EOF in transition type indexes.')
    transition_type_indexes = struct.unpack('>%dB' % tzh_timecnt, data)
    if [1 for x in transition_type_indexes if x >= tzh_typecnt]:
      raise ValueError('Transition type index too large.')
    print transition_type_indexes
    data = f.read(tzh_typecnt * 6)
    if len(data) != tzh_typecnt * 6:
      raise ValueError('EOF in ttinfos.')
    ttinfos = tuple(struct.unpack('>lBB', data[i : i + 6]) for i in xrange(0, len(data), 6))  # (tt_gmtoff, tt_isdst, tt_abbrind)
    if [1 for x in ttinfos if x[2] >= tzh_charcnt]:
      raise ValueError('Abbreviation index too large.')
    data = f.read(tzh_charcnt)
    if len(data) != tzh_charcnt:
      raise ValueError('EOF in abbreviation strings.')
    abbr_strings = data
  finally:
    f.close()
  if not abbr_strings.endswith('\0'):
    raise ValueError('Expected NUL at end of abbreviation strings.')
  print (abbr_strings,)
  ttinfos = tuple((x[0], x[1], abbr_strings[x[2] : abbr_strings.find('\0', x[2])]) for x in ttinfos)  # Replace each abbreviation index with abbreviation string.
  return (transition_times, transition_type_indexes, ttinfos)


def localtime(ts, tzinfo):
  """Converts a timestamp to a struct tm, returns the (tm, abbrstr) pair.

  libc localtime(3) returns only the tm, not the abbrstr.
  """
  transition_times, transition_type_indexes, ttinfos = tzinfo
  ts = int(ts)
  i = bisect.bisect_right(transition_times, ts)
  if i > 0:
    i -= 1
  tt_gmtoff, tt_isdst, tt_abbrstr = ttinfos[transition_type_indexes[i]]  # (tt_gmtoff, tt_isdst, tt_abbrstr).
  print (ts, tt_gmtoff, tt_isdst, tt_abbrstr)
  tm = time.gmtime(ts + tt_gmtoff)
  tml = list(tm)
  tml[-1] = tt_isdst  # Last field is tm_isdst.
  return (type(tm)(tml), tt_abbrstr)


def main(argv):
  ts = int(time.time())  # Now.
  for filename in argv[1:] or ('/etc/localtime',):
    tzinfo = parse_tzfile(filename)
    try:
      filename2 = os.readlink(filename)  # '/usr/share/zoneinfo/Continent/City'.
    except (AttributeError, OSError):
      filename2 = None
    tm, abbrstr = localtime(ts, tzinfo)
    print (ts, filename, filename2, abbrstr, tm)


if __name__ == '__main__':
  sys.exit(main(sys.argv))
