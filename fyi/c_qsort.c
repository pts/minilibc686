/* by pts@fazekas.hu at Thu Jun  1 02:48:00 CEST 2023
 *
 * Code based on
 * https://github.com/pts/pts-insertion-sort/blob/3f6834da20889ab80ea9698b909c1de3443d9e1a/insertion_sort.c#L1
 */

typedef unsigned size_t;

/* Same signature as qsort(3), but it implements the slower insertion sort
 * instead in compact code. It is stable, but very slow. For a faster
 * qsort(3) implementation, see sort_fast.c.
 *
 * Worst case number of comparisons and swaps: n*(n-1)/2. Best case is when
 * the input is sorted: n-1 comparisons and 0 swaps.
 *
 * Uses a constant amount of memory in addition to the input/output array.
 *
 * It implements swapping of elements by rotating a sequence of elements to
 * the right by 1 element. It rotates bytewise, so the constant factor is
 * quite slow.
 */
void mini_qsort(void *base, size_t n, size_t size,
                int (*cmp)(const void*, const void*)) {
  char *oldcur, *end, *newcur, *mid, tmp, *cur;
  if (nmemb > 1) {
    for (cur = (char*)base + size, end = (char*)base + (size * nmemb);
         cur != end;
         cur = newcur) {
      newcur = cur + size;
      if (cmp(cur, cur - size) < 0) {
        oldcur = cur;
        do {
          cur -= size;
        } while (cur != (char*)base && cmp(oldcur, cur - size) < 0);
        /* memrotate(cur, oldcur, size); */
        while (oldcur != newcur) {
          mid = oldcur;
          tmp = *mid;
          while (mid != cur) {
            *mid = *(mid - size);
            mid -= size;
          }
          *mid = tmp;
          ++oldcur;
          ++cur;
        }
      }
    }
  }
}
