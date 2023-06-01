/* by pts@fazekas.hu at Thu Jun  1 02:48:00 CEST 2023 */

typedef unsigned size_t;

/* Swaps the contents of the memory regions of size `size' bytes, starting
 * at `a' and `b', respectively.
 */
static void memswap(void *a, void *b, size_t size) {
  char tmp, *ac, *bc;
  for (ac = (char*)a, bc = (char*)b; size > 0; --size) {
    tmp = *ac;
    *ac++ = *bc;
    *bc++ = tmp;
  }
}

/* Same signature as qsort(3), but it implements the fast-in-worst-case
 * heapsort. It is not stable.
 *
 * Worst case execution time: O(n*log(n)): less than 3*n*log_2(n)
 * comparisons and swaps. (The number of swaps is usually a bit smaller than
 * the number of comparisons.) The average number of comparisons is
 * 2*n*log_2(n)-O(n). It is very fast if all values are the same (but still
 * does lots of comparisons and swaps). It is not especially faster than
 * average if the input is already ascending or descending (with unique
 * values),
 *
 * Uses a constant amount of memory in addition to the input/output array.
 *
 * Based on heapsort algorithm H from Knuth TAOCP 5.2.3. The original uses a
 * temporary variable (of `size' bytes) and copies elements between it and
 * the array. That code was changed to swaps within the original array.
 */
void mini_qsort_fast(void *base, size_t n, size_t size,
                     int (*cmp)(const void*, const void*)) {
  char *ap = (char*)base, *lp = ap + size * (n >> 1);
  char *rp = ap + size * (n - 1), *tp, *ip, *jp;
  if (n < 2) return;
  for (;;) {
    if (lp != ap) {
      tp = lp -= size;
    } else {
      memswap(ap, rp, size);
      if ((rp -= size) == ap) break;
      tp = ap;
    }
    jp = lp;
    for (;;) {
      ip = jp;
      jp += (jp - ap) + size;
      if (jp > rp) break;
      if (jp < rp && cmp(jp, jp + size) < 0) jp += size;
      if (!(cmp(tp, jp) < 0)) break;
      memswap(ip, jp, size);
      tp = jp;
    }
    memswap(ip, tp, size);
  }
}
