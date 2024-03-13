#! /usr/bin/python
# by pts@fazekas.hu at Mon Jan 22 15:55:07 CET 2024
#
# This Python script analyses the in-place mergesort implementation in
# test/test_qsort_stable_analyze.c. The analysis contans some mathematical
# proofs, but most of the final results are derived numerically, without
# rigorous proof.
#

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
# If n > 2: T(n) <= v(n) + T(x(n)) + T(n - x(n))
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
# Let K(n) be the largest power of smaller than n. Examples: K(15) == K(16) == 8, K(17) == 16.
#
# Let S(n) be the maximum number of swaps in an in-place mergesort fo size n:
#
# S(n) <= S(K(n)) + S(n - K(n)) + T(n).
#
# S(2**k) <= 2*S(2**(k-1)) + T(2**k) if k >= 1.
#
# S(2**k) <= T(2**k) + 2*T(2**(k-1)) + ... 2**k*T(2**0)
#         == sum(2**(k-i) * T(2**i), i=0..k) <=
#         == sum(2**(k-i) * z*(2**i)*log2(2**i), i=0..k)
#         == 2**k*z * sum(i, i=0..k) == z*(2**k)*k*(k+1)/2
#         <= z*(2**k)*k*k.
#
# !! Prove that S(n) <= z * n * log2(n) * log2(n).
# It has been proven if n is a power of 2.
#
# ---
#
# k(n) := ceil(log2(n // 2 + 1)).
#
# k(n) is the number of comparisons in the binary search of the in-place merge.
#
# Let D(n) be the maximum number of comparisons in an in-place merge of total size n.
#
# If n <= 1: D(n) == 0.
# If n == 2: D(n) == 1.
# If n >= 3: D(n) <= k(n) + D(x(n)) - D(n - x(n)).
# !! Prove that splits more even than x(n) are yield smaller recursive D + D.
#
# CALCD1: [0, 0, 1, 2, 4, 6, 8, 9, 12, 13, 16, 17, 18, 21, 22, 24, 26, 29, 30, 32, 34, 36, 39, 41, 42, 44, 46, 47, 49, 52, 54, 57, 59]
# !! Calculate the extra comparison for the shortcut.
#
# n   k  x  y  D(n)<=
# ------------------------------
#  0  -  -  -   0
#  1  -  -  -   0
#  2  -  -  -   1
#  3  1  1  2   2 == 1+D(1)+D(2)
#  4  2  1  3   4 == 2+D(1)+D(3)
#  5  2  1  4   6 == 2+D(1)+D(4)
#  6  2  1  5   8 == 2+D(1)+D(5)
#  7  2  2  5   9 == 2+D(2)+D(5)
#  8  3  2  6  12 == 3+D(2)+D(6)
#  9  3  2  7  13 == 3+D(2)+D(7)
# 10  3  2  8  16 == 3+D(2)+D(8)
# 11  3  3  8  17 == 3+D(3)+D(8)
# 12  3  3  9  18 == 3+D(3)+D(9)
#
# Let C(n) be the maximum number of comparisons in an in-place mergesort fo size n:
#
# C(n) <= C(K(n)) + C(n - K(n)) + D(n).
#

def calct1(n, _cache=[0, 0, 1]):
  """Returns upper bound on maximum number of swaps in an in-place merge of total size n."""
  if n < 0:
    raise ValueError
  while len(_cache) <= n:
    nn = len(_cache)
    _cache.append(((nn * 3 + 3) >> 2) + _cache[(nn + 1) >> 2] + _cache[nn - ((nn + 1) >> 2)])
  return _cache[n]


def calcs1(n, _cache=[0, 0]):
  """Returns upper bound on maximum number of swaps in an in-place mergesort of size n."""
  if n < 0:
    raise ValueError
  while len(_cache) <= n:
    nn = len(_cache)
    kk = 1
    while kk << 1 < nn:
      kk <<= 1
    _cache.append(_cache[kk] + _cache[nn - kk] + calct1(nn))
  return _cache[n]


def calcd1(n, _cache=[0, 0, 1]):
  """Returns upper bound on maximum number of comparisons in an in-place merge of total size n."""
  if n < 0:
    raise ValueError
  while len(_cache) <= n:
    nn = len(_cache)
    nnn = (nn >> 1) + 1
    k = 0
    while (1 << k) < nnn:
      k += 1
    _cache.append(k + _cache[(nn + 1) >> 2] + _cache[nn - ((nn + 1) >> 2)])
  return _cache[n]


def calcc1(n, _cache=[0, 0]):
  """Returns upper bound on maximum number of comparisons in an in-place mergesort of size n."""
  if n < 0:
    raise ValueError
  while len(_cache) <= n:
    nn = len(_cache)
    kk = 1
    while kk << 1 < nn:
      kk <<= 1
    _cache.append(_cache[kk] + _cache[nn - kk] + calcd1(nn))
  return _cache[n]


def calcd1sc(n, _cache={0: 0, 1: 0, 2: 1}):
  """Returns upper bound on maximum number of comparisons in an in-place merge of total size n.

  Uses a sparse cache.
  """
  if n < 0:
    raise ValueError
  v = _cache.get(n)
  if v is None:
    nnn = (n >> 1) + 1
    k = 0
    while (1 << k) < nnn:
      k += 1
    _cache[n] = v = k + calcd1sc((n + 1) >> 2) + calcd1sc(n - ((n + 1) >> 2))
  return v


def calcc1sc(n, _cache={0: 0, 1: 0}):
  """Returns upper bound on maximum number of comparisons in an in-place mergesort of size n.

  Uses a sparse cache.
  """
  if n < 0:
    raise ValueError
  v = _cache.get(n)
  if v is None:
    kk = 1
    while kk << 1 < n:
      kk <<= 1
    _cache[n] = v = calcc1sc(kk) + calcc1sc(n - kk) + calcd1sc(n)
  return v


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
        print (n, s1, u1, r1)  # r1 seems to be limited.
    print '---'
    maxr1 = 0
    for n in xrange(33, 10000):
      s1 = calcs1(n)
      u1 = n * ((math.log(n) / math.log(2)) * (math.log(n) / math.log(2)))
      r1 = s1 / u1
      if r1 > maxr1:
        maxr1 = r1
        print (n, s1, u1, r1)  # r1 seems to be limited.
    # It seems that S(n) < 0.75 * n * log2(n) * log2(n) for any n >= 2. And S(n) == 0 for n < 2.
  print 'CALCD1:', [calcd1(n) for n in xrange(33)]
  assert [calcd1(n) for n in xrange(33)] == [0, 0, 1, 2, 4, 6, 8, 9, 12, 13, 16, 17, 18, 21, 22, 24, 26, 29, 30, 32, 34, 36, 39, 41, 42, 44, 46, 47, 49, 52, 54, 57, 59]
  assert [calcd1sc(n) for n in xrange(33)] == [0, 0, 1, 2, 4, 6, 8, 9, 12, 13, 16, 17, 18, 21, 22, 24, 26, 29, 30, 32, 34, 36, 39, 41, 42, 44, 46, 47, 49, 52, 54, 57, 59]

  print 'CALCC1:', [calcc1(n) for n in xrange(33)]
  assert [calcc1(n) for n in xrange(33)] == [0, 0, 1, 3, 6, 12, 15, 18, 24, 37, 41, 44, 48, 57, 61, 66, 74, 103, 105, 109, 114, 122, 128, 133, 140, 155, 161, 165, 171, 183, 189, 197, 207]
  assert [calcc1sc(n) for n in xrange(33)] == [0, 0, 1, 3, 6, 12, 15, 18, 24, 37, 41, 44, 48, 57, 61, 66, 74, 103, 105, 109, 114, 122, 128, 133, 140, 155, 161, 165, 171, 183, 189, 197, 207]
  if 1:
    for n in xrange(2, 33):
      c1 = calcc1(n)
      u1 = n * ((math.log(n) / math.log(2)))
      print (n, c1, u1, c1 / u1)
    print '---LL'
    maxr1 = 0
    for n in xrange(33, 10000):
      c1 = calcc1(n)
      u1 = n * ((math.log(n) / math.log(2)) * (math.log(n) / math.log(2)))
      r1 = c1 / u1
      if r1 > maxr1:
        maxr1 = r1
        print (n, c1, u1, r1)  # r1 seems to be limited.
    print '---'
    maxr1 = 0
    for n in xrange(2, 33):
      c1 = calcc1(n)
      u1 = n * ((math.log(n) / math.log(2)))
      r1 = c1 / u1
      if r1 > maxr1:
        maxr1 = r1
        print (n, c1, u1, r1)  # r1 seems to be almost limited.
    print '---'
    maxr1 = 0
    for n in xrange(33, 10000):
      c1 = calcc1(n)
      u1 = n * ((math.log(n) / math.log(2)))
      r1 = c1 / u1
      if r1 > maxr1:
        maxr1 = r1
        print (n, c1, u1, r1)  # r1 seems to be almost limited.
    print '---'
    maxr1 = 0
    #sys.setrecursionlimit(20000)
    for k in xrange(1, 130):
      n = (1 << k) + 1
      c1 = calcc1sc(n)
      u1 = n * ((math.log(n) / math.log(2)))
      r1 = c1 / u1
      if r1 > maxr1:
        maxr1 = r1
        # (8193, 200461, 106510.44278309244, 1.8820783649189876)
        # (16385, 433962, 229391.44273906754, 1.8917968116780677)
        # (32769, 934593, 491536.4427170545, 1.901370720009837)
        # (65537, 2002784, 1048593.4427060478, 1.9099718903749052)
        # (131073, 4269122, 2228242.4427005444, 1.9159144975382427)
        # (262145, 9077484, 4718611.442697792, 1.9237617062213732)
        # (524289, 19200302, 9961492.442696417, 1.9274523481747263)
        # (1048577, 40571133, 20971541.44269573, 1.9345803984346939)
        # (2097153, 85306297, 44040214.44269539, 1.9370091194946282)
        # (4194305, 179317875, 92274711.44269522, 1.9433046410701664)
        # (8388609, 375295641, 192938008.44269514, 1.9451617855352084)
        # (16777217, 785371931, 402653209.4426951, 1.950492166912115)
        print (k, n, c1, u1, r1)  # r1 seems co be almost limited.


if __name__ == '__main__':
  sys.exit(main(sys.argv))
