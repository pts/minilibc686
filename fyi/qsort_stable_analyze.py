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


# 2: rotate(1, 1) == swap
# 3 == 1 + 2 == 1 + 2: rotate(1, 1) == swap
# 4 == 1 + 3 == 1 + 3: rotate(2, 1)
# 4 == 2 + 2 == 1 + 3
# 5 == 1 + 4 == 2 + 3
# 5 == 2 + 3 == 1 + 4
# 6 == 1 + 5 == 2 + 4
# 6 == 2 + 4 == 2 + 4
# 6 == 3 + 3 == 1 + 5
# 7 == 1 + 6 == 3 + 4
# 7 == 2 + 5 == 4 + 3
# 7 == 3 + 4 == 2 + 5
# 8 == 1 + 7 == 3 + 5
# 8 == 2 + 6 == 3 + 5
# 8 == 3 + 5 == 2 + 6
# 8 == 3 + 5 == 2 + 6
# 9 == 1 + 8 == 4 + 5
# 9 == 2 + 7 == 3 + 6
# 9 == 3 + 6 == 3 + 6
# 9 == 4 + 5 == 2 + 7
# 10 == 1 + 9 == 4 + 6
# 10 == 2 + 8 == 4 + 6
# 10 == 3 + 7 == 3 + 7
# 10 == 4 + 6 == 3 + 7
# 10 == 5 + 5 == 2 + 8
# 11 == 1 + 10 == 5 + 6
# 11 == 2 + 9 == 4 + 7
# 11 == 3 + 8 == 4 + 7
# 11 == 4 + 7 == 3 + 8
# 11 == 5 + 6 == 3 + 8
#
# f(11) == 3, f(7) == 2, f(3) == 1; f(n) == (n + 1) >> 2
def qsort_both(n, logd):
  if n:
    add(logd, n, n)
    if n > 1:
      #a = (n * 3) >> 2  # !! +3 doesn't work for n == 2 and n == 3.
      a = max(1, (n + 1) >> 2)
      #a = n >> 1
      #a = n - 1
      b = n - a
      qsort_both(a, logd)
      qsort_both(b, logd)

# Maximum number of swaps:
# 256 * 1 --> 128 * 2:  128*2*log2(2)     == c*128*2*1 == c*256*1  # !! In reality, this is just 128.
# 128 * 2 --> 64 * 4 :  64*c*4*log2(4)    == c*64*4*2  == c*256*2
# 64 * 4  --> 32 * 8 :  32*c*8*log2(8)    == c*32*8*3  == c*256*3
# 32 * 8  --> 16 * 16:  16*c*16*log2(16)  == c*16*16*4 == c*256*4
# 16 * 16 --> 8 * 32 :  8*c*32*log2(32)   == c*8*32*5  == c*256*5
# 8 * 32  --> 4 * 64 :  4*c*64*log2(64)   == c*4*64*6  == c*256*6
# 4 * 64  --> 2 * 128:  2*c*128*log2(128) == c*2*128*7 == c*256*7
# 2 * 128 --> 1 * 256:  1*c*256*log2(256) == c*1*256*8 == c*256*8
# Total: c*256*(1+8)*8/2.

# !! TODO(pts): Implement with memswap, faster than 3 reverses.

# Upper bound for the approximated swap count:
#
# S(n) <= c * n * log2(n).
#
# S(n) <= 3/4*n + S(n/4) + S(3/4*n)
#      <= 3/4*n + c*n/4*log2(n/4) + c*3/4*n*log2(3/4*n)
#      == 3/4*n + c*n/4*log2(n) + c*3/4*n*log2(n) + c*n/4*log2(1/4) + c*3/4*n*log2(3/4)
#      == c*n*log2(n) + n*(3/4+c*(1/4*log2(1/4)+3/4*log2(3/4)))
#      <= c*n*log2(n) + n*(3/4-c*0.811278)  (*)
#      <= c*n*log2(n).
#
# (*): We want 3/4-c*0.811278 < 0 <=> 3/4 < c*0.811278 <= c >= 0.9244674.
#
# Thus we have S(n) <= 0.9244674 * n * log2(n).
#
#



def main(argv):
  logd = {}
  qsort_depth(256, logd)
  print sorted(logd.iteritems())

  logd = {}
  qsort_copy(256, logd)
  print sorted(logd.iteritems())

  for i in xrange(1, 21):
    n = 1 << i
    logd = {}
    qsort_both(n, logd)
    #print sorted(logd.iteritems()),
    s = sum(logd.itervalues())
    print i, n, s, (s + 0.) / n / i # / i

  print '---'
  for n in xrange(1, 51):
    #t = sum((1 << (n - i)) * i for i in xrange(1, n + 1))
    t = sum((1 << (n - i)) * i * (1 << i) for i in xrange(1, n + 1))
    print n, t, (t + 0.) / (1 << n) / n / n

  print '---'
  import math
  for n1 in xrange(1, 30):
    n2 = 30 - n1
    print (n1, n2, n1 * math.log(n1) + n2 * math.log(n2))




if __name__ == '__main__':
  sys.exit(main(sys.argv))
