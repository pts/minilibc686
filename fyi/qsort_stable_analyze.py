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
#
# Mergesort of: S(2**k):
# 1: 0
# 2: T(2) <= 1
# 4: 2*T(2)+T(4) <= 9
# 8: 4*T(2)+2*T(4)+T(8) <= 41
#
# S(2**k) <= 2*S(2**(k-1)) + T(2**k) if k >= 1.
#
# S(2**k) <= T(2**k) + 2*T(2**(k-1)) + ... 2**k*T(2**0)
#         == sum(2**(k-i) * T(2**i), i=0..k) <=
#         == sum(2**(k-i) * z*(2**i)*log2(2**i), i=0..k)
#         == 2**k*z * sum(i, i=0..k) == z*(2**k)*k*(k+1)/2
#         <= z*(2**k)*k*k.

def calct1(n, _cache=[0, 0, 1]):
  """Returns upper bound on maximum number of swaps in an in-place merge of size n."""
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


def calcs1(n, _cache=[0, 0]):
  """Returns upper bound on maximum number of swaps in a mergesort of size n."""
  if n < 0:
    raise ValueError
  while len(_cache) <= n:
    nn = len(_cache)
    kk = 1
    while kk << 1 < nn:
      kk <<= 1
    _cache.append(_cache[kk] + _cache[nn - kk] + calct1(nn))
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
  print 'CALCS1:', [calcs1(n) for n in xrange(33)]
  assert [calcs1(n) for n in xrange(33)] == [0, 0, 1, 5, 9, 20, 26, 32, 41, 67, 74, 82, 89, 107, 118, 128, 140, 206, 213, 222, 230, 245, 260, 272, 287, 319, 331, 342, 353, 381, 399, 415, 433]
  if 1:
    for n in xrange(2, 33):
      s1 = calcs1(n)
      u1 = n * ((math.log(n) / math.log(2)) * (math.log(n) / math.log(2)))
      print (n, s1, u1, s1 / u1)
    print '---'
    maxr1 = 0
    for n in xrange(2, 33):
      s1 = calcs1(n)
      u1 = n * ((math.log(n) / math.log(2)) * (math.log(n) / math.log(2)))
      r1 = s1 / u1
      if r1 > maxr1:
        maxr1 = r1
        print (n, s1, u1, r1)  # r1 seems so be limised.
    print '---'
    maxr1 = 0
    for n in xrange(33, 10000):
      s1 = calcs1(n)
      u1 = n * ((math.log(n) / math.log(2)) * (math.log(n) / math.log(2)))
      r1 = s1 / u1
      if r1 > maxr1:
        maxr1 = r1
        print (n, s1, u1, r1)  # r1 seems so be limised.
    # It seems that S(n) < 0.75 * n * log2(n) * log2(n) for any n >= 2. And S(n) == 0 for n < 2.


if __name__ == '__main__':
  sys.exit(main(sys.argv))
