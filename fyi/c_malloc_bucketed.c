/*
 * c_malloc_bucketed.c: malloc+free+realloc implemented as a bucket-pool allocator
 * by pts@fazekas.hu at Sun Jun 25 22:43:09 CEST 2023
 *
 * This is a short and fast (O(1) per operation) allocator, but it wastes
 * memory (less than 50%).
 *
 * It returns pointer aligned to a multiple of 4 bytes (or size_t, whichever
 * is larger). Each malloc(...), free(...) and realloc(...) call takes O(1)
 * time. Less than 50% of the allocated memory is wasted because of
 * occasional rounding up to the next power of 2. If there is no free(...)
 * or reallocating realloc(...) call, then the overhead per block is just 4
 * bytes + alignment (0..3 bytes).
 *
 * New memory blocks are requested from the system using
 * mini_malloc_simple_unaligned(...), which eventually calls sys_brk(...).
 * There are 30 buckets (corresponding to block sizes 1<<2 .. 1<<31), each
 * containing a signly linked list of free()d blocks. When a new block is
 * allocated, the corresponding bucket size is tried. Blocks remain in their
 * respective buckets, they are never joined or split. The rounding up to
 * the next power of 2 happens in realloc(...) only, thus free()d blocks in
 * the buckets don't have a power-of-2 size. To combat fragmentation (in a
 * limited way), a best fit match of up to BEST_FIT_LIMIT (16) free()d
 * blocks is tried in the previous (1 smaller) bucket, so a malloc(n) after
 * a recent free(n) would assign the same block, without fragmentation.
 *
 * Other allocators considered:
 *
 * * uClibc
 * * diet libc
 * * newlib
 * * picolibc
 * * https://moss.cs.iit.edu/cs351/slides/slides-malloc.pdf
 * * https://github.com/jterrazz/42-malloc
 *   https://medium.com/a-42-journey/how-to-create-your-own-malloc-library-b86fedd39b96
 * * https://codereview.stackexchange.com/questions/209981/simple-malloc-implementation
 * * https://www.math.uni-bielefeld.de/~rehmann/Ckurs-f/b04/alloc.h
 * * https://stackoverflow.com/questions/3752604/simple-c-malloc
 * * https://github.com/sonugiri1043/Malloc-Free
 * * https://gist.github.com/mshr-h/9636fa0adcf834103b1b
 * * http://ccodearchive.net/info/antithread/alloc.html
 *
 * The allocators aober were either too long or too slow (O(n) for each
 * operation).
 */

#define BEST_FIT_LIMIT 16
#undef CONFIG_MALLOC_VERBOSE
#define NULL ((void*)0)
#ifdef __SIZE_TYPE__
  typedef __SIZE_TYPE__ size_t;
#else
  typedef unsigned long size_t;
#endif
extern void *mini_malloc_simple_unaligned(size_t size);
extern void *mini_memcpy(void *dest, const void *src, size_t n);
typedef char assert_size_t_size[sizeof(size_t) == 2 || sizeof(size_t) == 4 || sizeof(size_t) == 8 || sizeof(size_t) == 16 ? 1 : -1];
typedef char assert_voidp_size[sizeof(void*) == 2 || sizeof(void*) == 4 || sizeof(void*) == 8 || sizeof(void*) == 16 ? 1 : -1];

/* Each bucket is a linked list of blocks to reuse.
 * -2 because malloc below aligns to a multiple of 4, thus (1 << 2) is the minimum alloc size.
 */
static void *free_bucket_heads[sizeof(size_t) * 8 - (sizeof(size_t) > 8 ? 4 : sizeof(size_t) > 4 ? 3 : sizeof(size_t) > 2 ? 2 : 1)];
void *realloc(void *ptr, size_t size1) {
  size_t size, size2, best_fit;
  void *ptr1;
  void **bucketp, **prev_ptr, **best_prev_ptr;
  unsigned char best_fit_limit;
  if (size1 >= (size_t)1 << (sizeof(size_t) * 8 - 1)) return NULL;  /* Desired memory block too large. */
  if (!ptr) {  /* malloc(...). */
    if (sizeof(void*) > sizeof(size_t)) {
#if !defined(__WATCOMC__) || !defined(__386__)
      if (size1 < sizeof(void*)) size1 = sizeof(void*);
#endif
    } else {
      if (!size1) ++size1;
    }
    size1 = (size1 + sizeof(size_t) - 1) & -sizeof(size_t);  /* Align to multiple of 4. */
    /* No need to check overflow of size2, we've already checked size1 above (deisred memory block too large). */
    for (size2 = sizeof(void*) > sizeof(size_t) ? sizeof(void*) : sizeof(size_t), bucketp = free_bucket_heads; size2 < size1; size2 <<= 1, ++bucketp) {}
    if (size1 & (size1 - 1)) {  /* Try best-fit from the 1 smaller bucket. */
      prev_ptr = bucketp - 1;
      best_fit = (size_t)-1;
      best_prev_ptr = NULL;
      best_fit_limit = BEST_FIT_LIMIT;
      for (ptr = *prev_ptr; best_fit_limit > 0 && ptr; prev_ptr = (void**)ptr, ptr = *(void**)ptr, --best_fit_limit) {
        size = *(size_t*)((char*)ptr - sizeof(size_t));
        if (size >= size1) {
          if (size - size1 < best_fit) {
            best_fit = size - size1;
            best_prev_ptr = prev_ptr;
          }
        } else {
#        ifdef CONFIG_MALLOC_VERBOSE
          fprintf(stderr, "MV MALLOC_NOT_FROM_SMALLER_BUCKET 0x%lx < 0x%lx\n", (unsigned long)size, (unsigned long)size1);
#        endif
        }
      }
      if (best_prev_ptr) {
#        ifdef CONFIG_MALLOC_VERBOSE
          fprintf(stderr, "MV MALLOC_FROM_SMALLER_BUCKET 0x%lx >= 0x%lx\n", (unsigned long)(size1 + best_fit), (unsigned long)size1);
#        endif
        ptr = *best_prev_ptr;
        *best_prev_ptr = *(void**)ptr;  /* Remove ptr from the linked list. */
        return ptr;
      }
    }
    if ((ptr1 = *bucketp) != NULL) {  /* Reuse from bucket. */
#    ifdef CONFIG_MALLOC_VERBOSE
      fprintf(stderr, "MV MALLOC_FROM_BUCKET 0x%lx\n", (unsigned long)size2);
#    endif
      *bucketp = *(void**)ptr1;  /* Remove from beginning of linked list. */
      return ptr1;
    }
    if (!(ptr1 = mini_malloc_simple_unaligned(size1 + sizeof(size_t)))) return NULL;  /* Actually, it's aligned if only this malloc(...) calls it. */
    *(size_t*)ptr1 = size1;
    return (char*)ptr1 + sizeof(size_t);
  } else if (!size1) {  /* free(...) with non-NULL ptr. */
    ptr1 = NULL;  /* Return value. */
    size = *(size_t*)((char*)ptr - sizeof(size_t));
   do_free:
    /* No need to check overflow of size2, we've already checked size1 above (deisred memory block too large). */
    for (size2 = sizeof(void*) > 4 ? sizeof(void*) : 4, bucketp = free_bucket_heads; size2 <= size; size2 <<= 1, ++bucketp) {}
    --size2; --bucketp;
#    ifdef CONFIG_MALLOC_VERBOSE
      fprintf(stderr, "MV FREE_TO_BUCKET 0x%lx\n", (unsigned long)size2);
#    endif
    *(void**)ptr = *bucketp;
    *bucketp = ptr;
    return ptr1;
  } else {  /* realloc(...) existing. */
    size = *(size_t*)((char*)ptr - sizeof(size_t));
    if (size1 <= size) return ptr;
    /* Round up to next multiple of 2. This is to make the number of copies
     * in successive realloc(...)s O(n) instead of O(n**2).
     */
    for (size2 = sizeof(void*); size2 < size1; size2 <<= 1) {}  /* No need to check overflow of size2, we've already checked size1 above (deisred memory block too large). */
    if ((ptr1 = realloc(NULL, size2)) == NULL) return NULL;
    mini_memcpy(ptr1, ptr, size);
    goto do_free;
  }
}

void *malloc(size_t size) {
  return realloc(NULL, size);
}

void free(void *ptr) {
  if (ptr) realloc(ptr, 0);
}
