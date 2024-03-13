#! /usr/bin/python
# by pts@fazekas.hu at Mon Jan 22 15:55:07 CET 2024

import math
import sys


# n1 := len(left) == b - a.
# n2 := len(right) == c - b.
# n := n1 + n2 == (b - a) + (c - b) == c - a.
# is_lower := (n1 > n2) == b - a > c -b.
# v := ceil((c-a)*3/4) == ceil(n*3/4).
#
# We focus on n1 >= 1 and n2 >= 1 case (thus n >= 2). Smaller inputs are
# trivial.
#
# We analyze the n1 <= n2 case, same is !is_lower, same as n1 <= n // 2,
# same as n2 >= ceil(n/2). The other one is symmetrical.
#
# [b,c) is split to two almost equal halves: [b,q) and [q,b), where q
# := b + ((c - b) // 2). (q is same as *key*)
#
# The binary search finds data[q] within [a,b), the result is named p (same
# as *low*). Thus a <= p <= b.
#
# The block swap swaps the blocks [p,b) and [b,q). If one of the blocks are
# empty, then it's 0 swaps. We analyze only the nonempty case (b > q and q >
# b).
#
# t := (b - p) + (q - b), the total number number of items in the block swap.
#
# t <= (b-a) + (c-b)//2 == (2*b-2*a+c-b)//2 ==
# ((b-a)+(c-a))//2 <= ((c-a)//2+(c-a))//2 == (c-a)*3//4 <= ceil((c-a)*3/4)
# == v. The last `ceil' is needed only in the n2 > n1 case.
#
# The block swap consists of 3 reverses of size b - p, q - b, q - p
# each. A reverse of size r is at most r // 2 swaps, thus the total number
# of swaps is at most (b-p)//2 + (q-b)//2 + (q-p)//2 <= (b-p+q-b+q-p)//2 ==
# q-p == (b-p) + (q-b) == t <= v.
#
# First recursive call: (a, p, p+(q-b)), total number of items: nr1 := s := (p-a) + (q-b).
# !! Prove: n//4 <= nr1 <= v.
# nr1 == (p-a) + (q-b) >= q-b == (c-b)//2 == n2//2 >= ceil(n/2)//2 == (n+1)//4.  !! Is this symmetrical?
#
# Second recursive call: (p+(q-b), q, c), total number of items: nr2 := (q-p) + (q-b) + (c-q) == (q-p) + (c-b).
# !! Prove: n//4 <= nr2 <= v.
#
# x := min(nr1_min, nr2_min) == (n+1)//4. !! Prove it. For nr1: 
#
# y := n-x
#
# T(n) := maximum total number of swaps for an in-place merge of total size n.
#
# Theorem (!! prove it): T(first) + T(second) <= T(x) + T(n-x).
#
# If n <= 1: T(n) == 0.
# If n == 2: T(n) == 1.
# If n > 2: T(n) <= v(n) + T(x(n)) + T(y(n))
#
# CALCT1: [0, 0, 1, 4, 7, 11, 16, 18, 23, 26, 32, 36, 39]
#
# n   v  x  y  T(n)<=
# ------------------------------
#  0  -  -  -   0
#  1  -  -  -   0
#  2  -  -  -   1
#  3  3  1  2   4 == 3+T(1)+T(2)
#  4  3  1  3   7 == 3+T(1)+T(3)
#  5  4  1  4  11 == 4+T(1)+T(4)
#  6  5  1  5  16 == 5+T(1)+T(5)
#  7  6  2  5  18 == 6+T(2)+T(5)
#  8  6  2  6  23 == 6+T(2)+T(6)
#  9  7  2  7  26 == 7+T(2)+T(7)
# 10  8  2  8  32 == 8+T(2)+T(8)
# 11  9  3  8  36 == 9+T(3)+T(8)
# 12  9  3  9  39 == 9+T(3)+T(9)
#
# If n >= 100, then n*cc >= n*3/4+1.  n*(cc-3/4) >= 1.  cc >= 1/n+3/4.  <=  cc >= 1/100+3/4.  cc >= 76/100.

# T(n) <= n*3/4 + 1 + T(n/4) + T(n*3/4).
# T(n) <= n*76/100 + T(n/4) + T(n*3/4).
#
# T(n) <= z*n*log2(n).
#
# T(n) <= n*76/100 + T(n/4) + T(n*3/4) <= n*76/10 + T(n/4) + T(3*n/4)
#      <= n*76/100 + z*n/4*log2(n/4) + z*n*3/4*log2(n*3/4)
#      <= n*76/100 + z*n/4*log2(n) + z*n/4*log2(1/4) + z*n*3/4*log2(n) + z*n*3/4*log2(3/4)
#      == n*76/100 + z*n*log2(n) + z*n/4*log2(1/4) + z*n*3/4*log2(3/4)
#      == n*(76/100+z*(1/4*log2(1/4)+3/4*log2(3/4))) + z*n*log2(n)
#
# We need: 76/100+z*(4*log2(1/4)+3/4*log2(3/4)) <= 0
#          .76+z*-0.8112781244591328 <= 0
#          .76 <= z*0.8112781244591328
#          .76/0.8112781244591328 <= z
#          z >= 0.9367934091735566
#          z >= 0.9368  # !! This is too small, it should be about 0.9522.
#


def calct1(n, _cache=[0, 0, 1]):
  if n < 0:
    raise ValueError
  while len(_cache) <= n:
    nn = len(_cache)
    _cache.append(((nn * 3 + 3) >> 2) + _cache[(nn + 1) >> 2] + _cache[nn - ((nn + 1) >> 2)])
  return _cache[n]


def calct2(n, _cache=[0, 0, 1]):
  if n < 0:
    raise ValueError
  while len(_cache) <= n:
    nn = len(_cache)
    _cache.append(((nn * 3 + 3) >> 2) + (_cache[nn - ((nn + 1) >> 2)]) << 1)
  return _cache[n]


def main(argv):
  print 'CALCT1:', [calct1(n) for n in xrange(13)]
  assert [calct1(n) for n in xrange(13)] == [0, 0, 1, 4, 7, 11, 16, 18, 23, 26, 32, 36, 39]
  if 1:
    for n in xrange(2, 40):
      t1 = calct1(n)
      u1 = n * (math.log(n) / math.log(2))
      print (n, t1, u1, t1 / u1)
    print '---'
    maxr1 = 0
    for n in xrange(100, 10000):
      t1 = calct1(n)
      u1 = n * (math.log(n) / math.log(2))
      r1 = t1 / u1
      if r1 > maxr1:
        maxr1 = r1
        print (n, t1, u1, r1)  # r1 seems to be limited.
      assert (n * 3 + 3) >> 2 <= n * 76 // 100
  if 0:
    print 'CALCT2:', [calct2(n) for n in xrange(13)]
    for n in xrange(2, 4000):
      t2 = calct2(n)
      u2 = n * (math.log(n) / math.log(2))
      print (n, t2, u2, t2 / u2)  # t2 / u2 doesn't seem to be limited.
  


 


# ---

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


# 
#
# n   n1  n2  v  b-p q-b
#  0  ------
#  1  ------
#  2   1   1           rotate(1, 1) == swap
#  3   1   2    1 + 2: rotate(1, 1)  swap
#  4   1   3    1 + 3: rotate(2, 1)
#  4   2   2    1 + 3
#  5   1   4    2 + 3
#  5   2   3    1 + 4
#  6   1   5    2 + 4
#  6   2   4    2 + 4
#  6   3   3    1 + 5
#  7   1   6    3 + 4
#  7   2   5    4 + 3
#  7   3   4    2 + 5
#  8   1   7    3 + 5
#  8   2   6    3 + 5
#  8   3   5    2 + 6
#  8   4   4
#  9   1   8    4 + 5
#  9   2   7    3 + 6
#  9   3   6    3 + 6
#  9   4   5    2 + 7
# 10   1   9    4 + 6
# 10   2   8    4 + 6
# 10   3   7    3 + 7
# 10   4   6    3 + 7
# 10   5   5    2 + 8
# 11   1  10    5 + 6
# 11   2   9    4 + 7
# 11   3   8    4 + 7
# 11   4   7    3 + 8
# 11   5   6    3 + 8
# 12   1  11
# 12   2  10
# 12   3   9
# 12   4   8
# 12   5   7
# 12   6   6
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

def old_main(argv):
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
