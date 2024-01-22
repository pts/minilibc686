#! /usr/bin/python
# by pts@fazekas.hu at Mon Jan 22 15:55:07 CET 2024

import sys


def add(logd, key, delta=1):
  logd[key] = logd.get(key, 0) + delta


def qsort_depth(n2, logd, depth=1):
  if n2:
    add(logd, depth, 1)
    if n2 > 1:
      n2h = (n2 + 1) >> 1
      add(logd, depth + 1, 2)
      qsort_depth(n2h, logd, depth + 2)
      qsort_depth(n2h, logd, depth + 2)
      qsort_depth(n2h, logd, depth + 2)
      qsort_depth(n2h, logd, depth + 2)


def qsort_copy(n2, logd):
  if n2:
    add(logd, n2, n2)
    if n2 > 1:
      n2h = (n2 + 1) >> 1
      qsort_copy(n2h, logd)
      qsort_copy(n2h, logd)
      qsort_copy(n2h, logd)
      qsort_copy(n2h, logd)


def qsort_both(n, logd):
  if n:
    add(logd, n)
    if n > 1:
      a = (n * 3) >> 2  # !! +3?
      b = n - a
      qsort_both(a, logd)
      qsort_both(b, logd)


def main(argv):
  logd = {}
  qsort_depth(256, logd)
  print sorted(logd.iteritems())

  logd = {}
  qsort_copy(256, logd)
  print sorted(logd.iteritems())

  logd = {}
  qsort_both(256, logd)
  print sorted(logd.iteritems())


if __name__ == '__main__':
  sys.exit(main(sys.argv))
