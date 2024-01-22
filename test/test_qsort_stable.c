/* written by pts@fazekas.hu at Sun Jul 16 10:18:35 CEST 2023
 *
 * Compile: gcc -s -O2 -W -Wall  -ansi -pedantic test/test_qsort_stable.c && ./a.out && echo OK
 * Compile: pathbin/minicc --gcc -ansi -pedantic test/test_qsort_stable.c && ./a.out && echo OK
 * Compile: pathbin/minicc --wcc -ansi -pedantic test/test_qsort_stable.c && ./a.out && echo OK
 * Compile: pathbin/minicc --pcc -ansi -pedantic test/test_qsort_stable.c && ./a.out && echo OK
 * Compile: pathbin/minicc --tcc -ansi -pedantic test/test_qsort_stable.c && ./a.out && echo OK
 * Compile: owcc -I"$WATCOM"/lh -blinux -s -Os -W -Wall -fsigned-char -o a.out -std=c89 test/test_qsort_stable.c && ./a.out && echo OK
 */

#define _GNU_SOURCE
#include <alloca.h>
#include <stdlib.h>
#include <stdio.h>
#include <string.h>

/* --- Mergesort with inplace merge.
 *
 * It's stable, and it doesn't use any extra memory (except for constant *
 * log2(n) stack space for the recursion.
 *
 * Number of comparisons and number of item copies is <= constant * n *
 * log2(n) * log2(n).
 *
 * Based on ip_merge (C, simplest) at https://stackoverflow.com/a/22839426/97248
 * Based on __merge_without_buffer (C++) at https://github.com/gcc-mirror/gcc/blob/9ed4fcfe47f28b36c73d74109898514ef4da00fb/libstdc%2B%2B-v3/include/bits/stl_algo.h#L2426
 * Based on merge (Java) at http://thomas.baudel.name/Visualisation/VisuTri/inplacestablesort.html
 * Different from the adjacent-same-size-swapping algorithm in: https://xinok.wordpress.com/2014/08/17/in-place-merge-sort-demystified-2/
 * Different from the Practical In-Place Merging algorithm (https://citeseerx.ist.psu.edu/viewdoc/download?doi=10.1.1.88.1155&rep=rep1&type=pdf) also explained in a C++ code comment in https://keithschwarz.com/interesting/code/?dir=inplace-merge
 * Different from imsort based in Practical In-Place Merging, implemented in C: https://github.com/liuxinyu95/AlgoXY/blob/4488cd0654ccd2425b3cc0a34d2996b61025c372/sorting/merge-sort/src/mergesort.c#L81
 * Different from the non-stable algorithm in https://www.geeksforgeeks.org/in-place-merge-sort/
 * Different from block merge sort explained in Ratio based stable in-place merging article: https://github.com/BonzaiThePenguin/WikiSort/blob/master/tamc2008.pdf
 * Different from WikiSort (based on Ratio based stable in-place merging), uses a cache buffer by default: https://github.com/BonzaiThePenguin/WikiSort
 *
 * TODO(pts): Which one is faster: Practical In-Place Merging; Ratio based stable in-place merging; this?
 *
 * It works like this:
 *
 * * The input is an array of values (A...C) split into to two sorted
 *   subarrays (A...B and B...C).
 * * The output is the original array (A...C), sorted.
 * * Sorting is done in-place, recursively. In total, sorting uses only a
 *   constant bytes of memory in local variables, with a stack depth of at
 *   most constant * log2(n).
 * * Steps:
 *   * It finds the halfway value of the longer subarray (let it be
 *     B...C, without loss of generality) within the shorter subarray
 *     (A...B) using binary search, creating 4 sorted subarrays:
 *     A...P, P...B, B...Q, Q...C. Here Q is halfway between B and C, and
 #     B-A <= C-B.
 *   * It swaps (rotates) P...B and B...Q in-place, creating 4 sorted subarrays:
 *     A...P, P...D, D...Q, Q...C, where D-P == Q-B and Q-D == B-P.
 *   * Recursively, it merges A...P and P...D in-place to A...D.
 *   * Recursively, it merges D...Q and Q...C in-place to D...C.
 * * For correctness, we have to prove that A...C is sorted in the end.
 *   After the recursive merges, the subarrays A...D and D...C are sorted.
 *   All remaining to prove is that to prove that values in A...D are at most
 *   the values in D...C. For that, we prove these before-swap:
 *   * Values in A...P are at most the values in P...B. That's true because
 *     A...B is sorted in the input.
 *   * Values in B...Q are at most the values in P...B. That's because of
 *     the binary search: the value near P is the same as the value near Q.
 *   * Values in A...P are at most the values in Q...C. That's because of
 *     the binary search: the value near P is the same as the value near Q.
 *   * Values in B...Q are at most the values in Q...C. That's true because
 *     B...C is sorted in the input.
 * * Subarray sizes of calls:
 *   * Input: n1 and n2, where 0 <= n1 <= n2.
 *   * First recursive call: s and floor(n2/2), where 0 <= s <= n1 <= n2.
 *   * Second recursive call: n1-s and ceil(n2/2).
 * * Proof that stack depth is at most 2 * ceil(log2(n2)), for the memory
 *   upper bound:
 *   * It's enough to prove that in 1 and 2 recursion depth, n2 (size of the
 *     longer input subarray) is at most ceil(n2/2).
 *   * Let's observe that both recursive calls on level 1 have an input of at
 *     most n1 elements and another input of at most ceil(n2/2) elements.
 *   * If the first input size f of a recursive call on level 1 is at
 *     most ceil(n2/2), then one recursive calls on level 2 have an input
 *     of at most f elements and another input of at most ceil(ceil(n2/2)/2)
 *     elements. Thus one input has at most f <= ceil(n2/2) elements, and
 *     another input has at most ceil(ceil(n2/2)/2) <= ceil(n2/2) elements,
 *     thus both have at most ceil(n2/2) elements, and we are done.
 *   * If the first input size f of a recursive call on level 1 is more
 *     than ceil(n2/2), then both recursive calls on level 2 have an input
 *     of at most ceil(n2/2) elements and another input of at most ceil(f/2)
 *     elements, and since f <= n1 <= n2, ceil(f/2) <= ceil(n2/2),
 *     thus both have at most ceil(n2/2) elements, and we are done.
 * * We still need to prove that execution time is at most constant * n *
 *   log2(n) log2(n) for each operation type (comparisons, copies etc.).
 *   TODO(pts): Write this.
 */

#if defined(__WATCOMC__) && defined(__386__)
  /* !! TODO(pts): Do 2 bytes or 4 bytes at a time. */
  __declspec(naked) void __watcall reverse_(char *a, char *b) { (void)a; (void)b; __asm {
		push ecx
		dec edx
    Lagain:	cmp eax, edx
		jb Lswapc
		pop ecx
		ret
    Lswapc:	mov cl, [eax]
		xchg cl, [edx]
		mov [eax], cl
		inc eax
		dec edx
		jmp Lagain
  } }
#else
void reverse_(char *a, char *b) {
    char c;
    for (--b; a < b; a++, b--) {
      c = *a; *a = *b; *b = c;
    }
  }
#endif

#if CONFIG_QSORT_STABLE_MULTIPLY_ONCE  /* 1 multiplication, 0 divisions. */

/* swap the sequence [p,b) with [b,q). */
static void rotate_(void *v, size_t npsize, size_t nbsize, size_t nqsize) {
  char * const p = (char*)v + npsize;
  char * const b = (char*)v + nbsize;
  char * const q = (char*)v + nqsize;
  if (npsize != nbsize && nbsize != nqsize) {
    /* !! TODO(pts): There is a faster algorithm using GCD. */
    reverse_(p, b);
    reverse_(b, q);
    reverse_(p, q);
  }
}

/* inplace merge [0,b) and [b,b+c) to [0,b+c). */
static void ip_merge_(void *v, size_t nb, size_t nbsize, size_t nc, size_t ncsize, size_t size, int (*cmp)(const void*, const void*)) {
  char *r, *key;
  size_t i, isize;
  size_t np, nq, nr, nxsize, npsize, nqsize;
  int is_lower;
  if (nb == 0 || nc == 0) return;
  if (nb + nc == 2) {
    if (cmp((char*)v + size, v) < 0) {  /* The rhucmp test checks that 0 is the only correct value here. */
      rotate_(v, 0, size, size << 1);  /* !! TODO(pts): Implement this with memswap. */
    }
    return;
  }
  is_lower = (nb > nc);
  if (is_lower) {
    np = (nb >> 1);
    npsize = nbsize;
    if (nb & 1) npsize -= size;
    npsize >>= 1;
    nr = nb;
    r = (char*)v + nbsize;
    i = nc;
    isize = ncsize;
  } else {
    np = nb + (nc >> 1);
    npsize = ncsize;
    if (nc & 1) npsize -= size;
    npsize >>= 1;
    npsize += nbsize;
    if (npsize != np * size) abort();
    nr = 0;
    r = (char*)v;
    i = nb;
    isize = nbsize;
  }
  key = (char*)v + npsize;
  nc += nb;
  ncsize += nbsize;
  nxsize = nbsize;
  nb = np - nb;
  nbsize = npsize - nbsize;
  /* bound_(r, i, key, is_lower, size, cmp); -- Use binary search to find upper or lower bound. */
  while (i != 0) {
    if (isize != i * size) abort();
    if (i & 1) isize -= size;
    isize >>= 1;  /* isize = (i >> 1) * size. */
    if (cmp(key, r + isize) >= is_lower) {  /* The rhucmp test checks that 1 is the only correct value here. */
      if (r + isize + size != r + ((i >> 1) + 1) * size) abort();
      r += isize + size;
      nr += (i >> 1) + 1;
      i--;
      if (i & 1) isize -= size;
      if (isize != (i >> 1) * size) abort();
    }
    i >>= 1;
  }
  /* End of bound_. Result is in r. */
  if (is_lower) {
    nq = nr;
    nqsize = r - (char*)v;
  } else {
    nq = np;
    nqsize = npsize;
    np = nr;
    npsize = r - (char*)v;
  }
  rotate_(v, npsize, nxsize, nqsize);
  nr += nb;
  if (r + nbsize != (char*)v + nr * size) abort();
  nxsize = r - (char*)v + nbsize;
  ip_merge_(v, np, npsize, nr - np, nxsize - npsize, size, cmp);  /* !! TODO(pts): Manual stack. */
  ip_merge_(r + nbsize, nq - nr, nqsize - nxsize, nc - nq, ncsize - nqsize, size, cmp);  /* !! TODO(pts): Manual tail recursion. */
}

static void ip_mergesort_low_(void *v, size_t n, size_t nsize, size_t size, int (*cmp)(const void*, const void*)) {
  size_t h, hsize;
  if (n > 1) {  /* !! TODO(pts): Use insertion sort for 2 <= n <= 16 etc. */
    h = n >> 1;
    hsize = nsize;
    if (n & 1) hsize -= size;
    hsize >>= 1;
    ip_mergesort_low_(v, h, hsize, size, cmp);
    n -= h;
    nsize -= hsize;
    ip_mergesort_low_((char*)v + hsize, n, nsize, size, cmp);
    ip_merge_(v, h, hsize, n, nsize, size, cmp);
  }
}

/* The signature is the same as of qsort(3). */
void ip_mergesort(void *v, size_t n, size_t size, int (*cmp)(const void*, const void*)) {
  if (n > 1) {
    /* This is the only multiplication, there is no division. */
    ip_mergesort_low_(v, n, n * size, size, cmp);
  }
}

#else  /* Many multiplications, 0 divisions. */

#if defined(__WATCOMC__) && defined(__386__)
  static __declspec(naked) void __watcall rotate_(char *p, char *b, char *q) { (void)p;  /* EAX. */ (void)b;  /* EDX. */  (void)q;  /* EBX. */ __asm {
#  ifdef CONFIG_MERGE_SLOW_ROTATE  /* Slower but shorter. The other one moves 4 or 2 bytes at a time, if possible. */
		cmp eax, edx
		je Ldone
		cmp edx, ebx
		je Ldone
		push edx
		add edx, edx
		sub edx, eax
		cmp edx, ebx
		pop edx
		jne Lreverses
		push ecx
    Lnextc:	cmp edx, ebx
		je Ldone_ecx
		mov cl, [eax]
		xchg cl, [edx]
		mov [eax], cl
		inc eax
		inc edx
		jmp Lnextc
    Ldone_ecx:	pop ecx
		jmp Ldone
    Lreverses:	push 0  /* Sentinel for end of reverses. */
		push eax  /* reverse_(eax, ebx); */
		push ebx
		push eax  /* reverse_(eax, edx); */
		push edx
		push edx  /* reverse_(edx, ebx); */
		push ebx
    Lrevnext:	pop edx
		test edx, edx
		jz Ldone
		pop eax
		push ecx
		dec edx
    Lswapc:	mov cl, [eax]
		xchg cl, [edx]
		mov [eax], cl
		inc eax
		dec edx
		cmp eax, edx
		jb Lswapc
		pop ecx
		jmp Lrevnext
    Ldone:	ret
#  else  /* else CONFIG_MERGE_SLOW_ROTATE */
		cmp eax, edx
		je short Ldone
		cmp edx, ebx
		je short Ldone
		push edx
		add edx, edx
		sub edx, eax
		cmp edx, ebx
		pop edx
		jne Lreverses
		push ecx
		mov ecx, ebx
		sub ecx, edx
		test cl, 3
		jz Lnextc4
		test cl, 1
		jz Lnextc2

    Lnextc1:	mov cl, [eax]
		xchg cl, [edx]
		mov [eax], cl
		inc eax
		inc edx
		cmp edx, ebx
		jne Lnextc1
		jmp short Ldone_ecx

    Lnextc2:	mov cx, [eax]
		xchg cx, [edx]
		mov [eax], cx
		inc eax
		inc eax
		inc edx
		inc edx
		cmp edx, ebx
		jne Lnextc2
		jmp short Ldone_ecx

    Lnextc4:	mov ecx, [eax]
		xchg ecx, [edx]
		mov [eax], ecx
		add eax, 4
		add edx, 4
		cmp edx, ebx
		jne Lnextc4
		jmp short Ldone_ecx
		/* Fall through. */
    Ldone_ecx:	pop ecx

    Ldone:	ret
    Lreverses:	push 0  /* Sentinel for end of reverses. */
		push eax  /* reverse_(eax, ebx); */
		push ebx
		push eax  /* reverse_(eax, edx); */
		push edx
		push edx  /* reverse_(edx, ebx); */
		push ebx
		sub ebx, edx
		sub edx, eax
		or edx, ebx
		test dl, 3
		jz Lrevnext4
		test dl, 1
		jz Lrevnext2

    Lrevnext1:	pop edx
		test edx, edx
		jz short Ldone
		pop eax
		dec edx
    Lswapc1:	mov bl, [eax]
		xchg bl, [edx]
		mov [eax], bl
		inc eax
		dec edx
		cmp eax, edx
		jb Lswapc1
		jmp Lrevnext1

    Lrevnext2:	pop edx
		test edx, edx
		jz short Ldone
		pop eax
		dec edx
		dec edx
    Lswapc2:	mov bx, [eax]
		xchg bx, [edx]
		mov [eax], bx
		inc eax
		inc eax
		dec edx
		dec edx
		cmp eax, edx
		jb Lswapc2
		jmp Lrevnext2

    Lrevnext4:	pop edx
		test edx, edx
		jz short Ldone
		pop eax
		jmp Lswape4
    Lswapc4:	mov ebx, [eax]
		xchg ebx, [edx]
		mov [eax], ebx
		add eax, 4
    Lswape4:	sub edx, 4
		cmp eax, edx
		jb Lswapc4
		jmp Lrevnext4
#endif  /* else CONFIG_MERGE_SLOW_ROTATE */
  } }
#elif (defined(__GNUC__) || defined(__TINYC__)) && defined(__i386__)
/* !! TODO(pts): Segfault:`clang -m32 -fsanitize=address'; -- why no segfault with GCC? why no addr? */
#  undef E
#  ifdef __TINYC__
#    define E "L"  /* The inline assembler of TCC 0.9.26 doesn't support labels starting with `.'. TODO(pts): Fix pts-tcc, add support. */
#  else
#    define E ".L"  /* GNU as(1) supports labels starting with `.', and it won't put them to the .o file. */
#  endif
#  ifdef __PCC__
  __attribute__((__regparm__(0)))  /* PCC would ignore regparm(3). */
#  else
  __attribute__((__regparm__(3)))
#  endif
  void rotate_(char *p, char *b, char *q);  /* p == EAX; b == EDX; q == ECX. */
  __asm__(".global rotate_; rotate_:\n"
#  ifdef __PCC__
    "\
		mov 4(%esp), %eax;\
		mov 8(%esp), %edx;\
		mov 0xc(%esp), %ecx;\
    "
#  endif
#  ifdef CONFIG_MERGE_SLOW_ROTATE  /* Slower but shorter. The other one moves 4 or 2 bytes at a time, if possible. */
    "\
		cmp %edx, %eax;\
		je "E"done;\
		cmp %ecx, %edx;\
		je "E"done;\
		push %edx;\
		add %edx, %edx;\
		sub %eax, %edx;\
		cmp %ecx, %edx;\
		pop %edx;\
		jne "E"reverses;\
		push %ebx;\
    "E"nextb:	cmp %ecx, %edx;\
		je "E"done_ebx;\
		mov (%eax), %bl;\
		xchg (%edx), %bl;\
		mov %bl, (%eax);\
		inc %eax;\
		inc %edx;\
		jmp "E"nextb;\
    "E"done_ebx:\
		pop %ebx;\
		jmp "E"done;\
    "E"reverses:\
		pushl $0; "  /* Sentinel for end of reverses. */"\
		push %eax; "  /* reverse_(%eax, %ecx); */"\
		push %ecx;\
		push %eax;  " /* reverse_(%eax, %edx); */"\
		push %edx;\
		push %edx; "  /* reverse_(%edx, %ecx); */"\
		push %ecx;\
    "E"revnext:	pop %edx;\
		test %edx, %edx;\
		jz "E"done;\
		pop %eax;\
		dec %edx;\
    "E"swapb:	mov (%eax), %cl;\
		xchg (%edx), %cl;\
		mov %cl, (%eax);\
		inc %eax;\
		dec %edx;\
		cmp %edx, %eax;\
		jb "E"swapb;\
		jmp "E"revnext;\
    "E"done:	ret;\
    "
#else  /* else CONFIG_MERGE_SLOW_ROTATE */
    "\
		cmp %edx, %eax;\
		je "E"done;\
		cmp %ecx, %edx;\
		je "E"done;\
		push %edx;\
		add %edx, %edx;\
		sub %eax, %edx;\
		cmp %ecx, %edx;\
		pop %edx;\
		jne "E"reverses;\
		push %ebx;\
		mov %ecx, %ebx;\
		sub %edx, %ebx;\
		test $3, %bl;\
		jz "E"nextb4;\
		test $1, %bl;\
		jz "E"nextb2;\
		\
    "E"nextb1:	mov (%eax), %bl;\
		xchg (%edx), %bl;\
		mov %bl, (%eax);\
		inc %eax;\
		inc %edx;\
		cmp %ecx, %edx;\
		jne "E"nextb1;\
		jmp "E"done_ebx;\
		\
    "E"nextb2:	mov (%eax), %bx;\
		xchg (%edx), %bx;\
		mov %bx, (%eax);\
		inc %eax;\
		inc %eax;\
		inc %edx;\
		inc %edx;\
		cmp %ecx, %edx;\
		jne "E"nextb2;\
		jmp "E"done_ebx;\
		\
    "E"nextb4:	mov (%eax), %ebx;\
		xchg (%edx), %ebx;\
		mov %ebx, (%eax);\
		add $4, %eax;\
		add $4, %edx;\
		cmp %ecx, %edx;\
		jne "E"nextb4;\
		"  /* Fall through. */"\
    "E"done_ebx:\
		pop %ebx;\
		\
    "E"done:	ret;\
    "E"reverses:\
		pushl $0; "  /* Sentinel for end of reverses. */"\
		push %eax; "  /* reverse_(%eax, %ecx); */"\
		push %ecx;\
		push %eax; "  /* reverse_(%eax, %edx); */"\
		push %edx;\
		push %edx; "  /* reverse_(%edx, %ecx); */"\
		push %ecx;\
		sub %edx, %ecx;\
		sub %eax, %edx;\
		or %ecx, %edx;\
		test $3, %dl;\
		jz "E"revnext4;\
		test $1, %dl;\
		jz "E"revnext2;\
		\
    "E"revnext1:\
		pop %edx;\
		test %edx, %edx;\
		jz "E"done;\
		pop %eax;\
		dec %edx;\
    "E"swapb1:	mov (%eax), %cl;\
		xchg (%edx), %cl;\
		mov %cl, (%eax);\
		inc %eax;\
		dec %edx;\
		cmp %edx, %eax;\
		jb "E"swapb1;\
		jmp "E"revnext1;\
		\
    "E"revnext2:\
		pop %edx;\
		test %edx, %edx;\
		jz "E"done;\
		pop %eax;\
		dec %edx;\
		dec %edx;\
    "E"swapb2:	mov (%eax), %cx;\
		xchg (%edx), %cx;\
		mov %cx, (%eax);\
		inc %eax;\
		inc %eax;\
		dec %edx;\
		dec %edx;\
		cmp %edx, %eax;\
		jb "E"swapb2;\
		jmp "E"revnext2;\
		\
    "E"revnext4:\
		pop %edx;\
		test %edx, %edx;\
		jz "E"done;\
		pop %eax;\
		jmp "E"swape4;\
    "E"swapb4:	mov (%eax), %ecx;\
		xchg (%edx), %ecx;\
		mov %ecx, (%eax);\
		add $4, %eax;\
    "E"swape4:	sub $4, %edx;\
		cmp %edx, %eax;\
		jb "E"swapb4;\
		jmp "E"revnext4;\
    "
#  endif  /* else CONFIG_MERGE_SLOW_ROTATE */
  );
#elif (defined(__GNUC__) || defined(__TINYC__)) && (defined(__amd64__) || defined(__x86_64__))
/* !! TODO(pts): Do we have segfault:`clang -fsanitize=address'; -- why no segfault with GCC? why no addr? */
#  undef E
#  ifdef __TINYC__
#    define E "L"  /* The inline assembler of TCC 0.9.26 doesn't support labels starting with `.'. TODO(pts): Fix pts-tcc, add support. */
#  else
#    define E ".L"  /* GNU as(1) supports labels starting with `.', and it won't put them to the .o file. */
#  endif
#  ifdef __PCC__
  __attribute__((__regparm__(0)))  /* PCC would ignore regparm(3). */
#  else
  __attribute__((__regparm__(3)))
#  endif
  void rotate_(char *p, char *b, char *q);  /* p == RDI; b == RSI; q == RDX. */
  __asm__(".global rotate_; rotate_:\n"
#  ifdef CONFIG_MERGE_SLOW_ROTATE  /* Slower but shorter. The other one moves 8 or 4 or 2 bytes at a time, if possible. */
    "\
		cmp %rsi, %rdi;\
		je "E"done;\
		cmp %rdx, %rsi;\
		je "E"done;\
		push %rsi;\
		add %rsi, %rsi;\
		sub %rdi, %rsi;\
		cmp %rdx, %rsi;\
		pop %rsi;\
		jne "E"reverses;\
    "E"nextb:	cmp %rdx, %rsi;\
		je "E"done;\
		mov (%rdi), %cl;\
		xchg (%rsi), %cl;\
		mov %cl, (%rdi);\
		inc %rdi;\
		inc %rsi;\
		jmp "E"nextb;\
    "E"reverses:\
		pushq $0; "  /* Sentinel for end of reverses. */"\
		push %rdi; "  /* reverse_(%rdi, %rdx); */"\
		push %rdx;\
		push %rdi;  " /* reverse_(%rdi, %rsi); */"\
		push %rsi;\
		push %rsi; "  /* reverse_(%rsi, %rdx); */"\
		push %rdx;\
    "E"revnext:	pop %rsi;\
		test %rsi, %rsi;\
		jz "E"done;\
		pop %rdi;\
		dec %rsi;\
    "E"swapb:	mov (%rdi), %cl; "  /* !! TODO(pts): Use lodsb etc. */"\
		xchg (%rsi), %cl;\
		mov %cl, (%rdi);\
		inc %rdi;\
		dec %rsi;\
		cmp %rsi, %rdi;\
		jb "E"swapb;\
		jmp "E"revnext;\
    "E"done:	ret;\
    "
#else  /* else CONFIG_MERGE_SLOW_ROTATE */
    "\
		cmp %rsi, %rdi;\
		je "E"done;\
		cmp %rdx, %rsi;\
		je "E"done;\
		push %rsi;\
		add %rsi, %rsi;\
		sub %rdi, %rsi;\
		cmp %rdx, %rsi;\
		pop %rsi;\
		jne "E"reverses;\
		mov %rdx, %rcx;\
		sub %rsi, %rcx;\
		test $7, %cl;\
		jz "E"nextb8;\
		test $3, %cl;\
		jz "E"nextb4;\
		test $1, %cl;\
		jz "E"nextb2;\
		\
    "E"nextb1:	mov (%rdi), %cl;\
		xchg (%rsi), %cl;\
		mov %cl, (%rdi);\
		inc %rdi;\
		inc %rsi;\
		cmp %rdx, %rsi;\
		jne "E"nextb1;\
		jmp "E"done;\
		\
    "E"nextb2:	mov (%rdi), %cx;\
		xchg (%rsi), %cx;\
		mov %cx, (%rdi);\
		add $2, %rdi;\
		add $2, %rsi;\
		cmp %rdx, %rsi;\
		jne "E"nextb2;\
		jmp "E"done;\
		\
    "E"nextb4:	mov (%rdi), %ecx;\
		xchg (%rsi), %ecx;\
		mov %ecx, (%rdi);\
		add $4, %rdi;\
		add $4, %rsi;\
		cmp %rdx, %rsi;\
		jne "E"nextb4;\
		jmp "E"done;\
		\
    "E"nextb8:	mov (%rdi), %rcx;\
		xchg (%rsi), %rcx;\
		mov %rcx, (%rdi);\
		add $8, %rdi;\
		add $8, %rsi;\
		cmp %rdx, %rsi;\
		jne "E"nextb8;\
		"  /* Fall through. */"\
    "E"done:	ret;\
    "E"reverses:\
		pushq $0; "  /* Sentinel for end of reverses. */"\
		push %rdi; "  /* reverse_(%rdi, %rdx); */"\
		push %rdx;\
		push %rdi; "  /* reverse_(%rdi, %rsi); */"\
		push %rsi;\
		push %rsi; "  /* reverse_(%rsi, %rdx); */"\
		push %rdx;\
		sub %rsi, %rdx;\
		sub %rdi, %rsi;\
		or %rsi, %rdx;\
		test $7, %dl;\
		jz "E"revnext8;\
		test $3, %dl;\
		jz "E"revnext4;\
		test $1, %dl;\
		jz "E"revnext2;\
		\
    "E"revnext1:\
		pop %rsi;\
		test %rsi, %rsi;\
		jz "E"done;\
		pop %rdi;\
		dec %rsi;\
    "E"swapb1:	mov (%rdi), %cl;\
		xchg (%rsi), %cl;\
		mov %cl, (%rdi);\
		inc %rdi;\
		dec %rsi;\
		cmp %rsi, %rdi;\
		jb "E"swapb1;\
		jmp "E"revnext1;\
		\
    "E"revnext2:\
		pop %rsi;\
		test %rsi, %rsi;\
		jz "E"done;\
		pop %rdi;\
		dec %rsi;\
		dec %rsi;\
    "E"swapb2:	mov (%rdi), %cx;\
		xchg (%rsi), %cx;\
		mov %cx, (%rdi);\
		add $2, %rdi;\
		sub $2, %rsi;\
		cmp %rsi, %rdi;\
		jb "E"swapb2;\
		jmp "E"revnext2;\
		\
    "E"revnext4:\
		pop %rsi;\
		test %rsi, %rsi;\
		jz "E"done;\
		pop %rdi;\
		jmp "E"swape4;\
    "E"swapb4:	mov (%rdi), %ecx;\
		xchg (%rsi), %ecx;\
		mov %ecx, (%rdi);\
		add $4, %rdi;\
    "E"swape4:	sub $4, %rsi;\
		cmp %rsi, %rdi;\
		jb "E"swapb4;\
		jmp "E"revnext4;\
		\
    "E"revnext8:\
		pop %rsi;\
		test %rsi, %rsi;\
		jz "E"done;\
		pop %rdi;\
		jmp "E"swape8;\
    "E"swapb8:	mov (%rdi), %rcx;\
		xchg (%rsi), %rcx;\
		mov %rcx, (%rdi);\
		add $8, %rdi;\
    "E"swape8:	sub $8, %rsi;\
		cmp %rsi, %rdi;\
		jb "E"swapb8;\
		jmp "E"revnext8;\
    "
#  endif  /* else CONFIG_MERGE_SLOW_ROTATE */
  );
#else
  /* swap the sequence [p,b) with [b,q). */
  static void rotate_(char *p, char *b, char *q) {
    char c;
    if (p != b && b != q) {
      if (b - p == q - b) {  /* Same size: swap. */
        /* memswap_(p, b, q - b); */
        for (; b != q; ++p, ++b) {
          c = *b;
          *b = *p;
          *p = c;
        }
      } else {
        /* !! TODO(pts): There is a faster algorithm using GCD. */
        reverse_(p, b);
        reverse_(b, q);
        reverse_(p, q);
      }
    }
  }
#endif

struct merge_task { char *v; size_t nb, nc; };

/* inplace all merge [0,st->nb) and [st->nb,st->b+st->c) to [0,st->b+st->c). */
static void ip_merge_(struct merge_task *st, size_t size, int (*cmp)(const void*, const void*)) {
  char *v, *r, *key;
  size_t i, isize, nb, nc, np, nq, nr, nx;
  int is_lower;
  struct merge_task *sp = st + 1;
  /*fprintf(stderr, "MERGE sn=%d %d %d\n", (int)(sp - st), (int)sp[-1].nb, (int)sp[-1].nc);*/
 pop_again:
  /*fprintf(stderr, "POP_AGAIN sn=%d\n", (int)(sp - st));*/
  if (st == sp) return;
  v = (--sp)->v;
  nb = sp->nb;
  nc = sp->nc;
 again:
  /*fprintf(stderr, "AGAIN sn=%d %d %d\n", (int)(sp - st), nb, nc);*/
  if (nb == 0 || nc == 0) goto pop_again;
  if (nb + nc == 2) {
    if (cmp(v + size, v) < 0) {  /* The rhucmp test checks that 0 is the only correct value here. */
      rotate_(v, v + size, v + (size << 1));
    }
    goto pop_again;
  }
  isize = nb * size;
  if (cmp(v + isize - size, v + isize) <= 0) goto pop_again;  /* Shortcut: nothing to do if the input is already merged. */
  is_lower = (nb > nc);
  if (is_lower) {
    np = (nb >> 1);
    nr = nb;
    r = v + isize;
    i = nc;
    isize = nc * size;
  } else {
    np = nb + (nc >> 1);
    nr = 0;
    r = v;
    i = nb;
  }
  key = v + np * size;
  nx = np - nb;
  /* bound_(r, i, key, is_lower, size, cmp); -- Use binary search to find upper or lower bound. */
  while (i != 0) {
    if (isize != i * size) abort();
    if (i & 1) isize -= size;
    isize >>= 1;  /* isize = (i >> 1) * size. */
    r += isize;
    if (cmp(key, r) >= is_lower) {  /* The rhucmp test checks that 1 is the only correct value here. */
      if (r + size != r - isize + ((i >> 1) + 1) * size) abort();
      r += size;
      nr += (i >> 1) + 1;
      i--;
      if (i & 1) isize -= size;
      if (isize != (i >> 1) * size) abort();
    } else {
      r -= isize;
    }
    i >>= 1;
  }
  /* End of bound_. Result is in r. */
  if (is_lower) {
    nq = nr;
  } else {
    nq = np;
    np = nr;
  }
  if (np != nb && nb != nq) {
    rotate_(v + np * size, v + nb * size, v + nq * size);
  }
  if (v + nr * size != r) abort();
  nr += nx;
  if (v + nr * size != r + nx * size) abort();
  /* ip_merge_(v + nr * size, nq - nr, nc + nb - nq, size, cmp); */
  sp->v = v + nr * size;
  sp->nb = nq - nr;
  sp->nc = nc + nb - nq;
  ++sp;
  /* ip_merge_(v, np, nr - np, size, cmp); */
  nb = np;
  nc = nr - np;
  goto again;
}

/* The signature is the same as of qsort(3). */
void ip_mergesort(void *v, size_t n, size_t size, int (*cmp)(const void*, const void*)) {
  size_t nb, i, idsize;
  char *vi;
  char *vend;
  struct merge_task *st;  /* Stack. */
  for (vi = (char*)v + size, vend = (char*)v + n * size; vi < vend; vi += size << 1) {  /* Without this speed optimization, `nb = 1' should be used instead of `nb = 2' below. */
    if (cmp(vi - size, vi) > 0) {  /* TODO(pts): Implement this with memswap. */
      rotate_(vi - size, vi, vi + size);
    }
  }
  if (n < 2) return;
  for (nb = 1, i = 1; nb < n; nb <<= 1, ++i) {}  /* !! TODO(pts): Use a CPU instruction to compute ceil(log2(..)). */
  st = alloca(i * (sizeof(struct merge_task) << 1));  /* 2 * ceil(log2(n)) * sizeof(struct merge_task). That's enough, because ip_merge_ splits the larger interval to halv every 2nd time. */
  for (nb = 2; nb < n; nb <<= 1) {  /* !! TODO(pts): Use insertion sort for 2 <= n <= 16 etc. */
    i = 0;
    vi = v;
    idsize = (nb << 1) * size;
    for (;;) {
      st->v = vi;
      st->nb = nb;
      if (n > i + (nb << 1)) {
        st->nc = nb;
        i += nb << 1;
        vi += idsize;
       do_merge:
        ip_merge_(st, size, cmp);
        if (!vi) break;
      } else if (n > i + nb) {
        st->nc = n - i - nb;
        vi = NULL;
        goto do_merge;
      } else {
        break;
      }
    }
  }
}

#endif


/*
 * Copyright © 2005-2020 Rich Felker
 *
 * Permission is hereby granted, free of charge, to any person obtaining
 * a copy of this software and associated documentation files (the
 * "Software"), to deal in the Software without restriction, including
 * without limitation the rights to use, copy, modify, merge, publish,
 * distribute, sublicense, and/or sell copies of the Software, and to
 * permit persons to whom the Software is furnished to do so, subject to
 * the following conditions:
 *
 * The above copyright notice and this permission notice shall be
 * included in all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
 * EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
 * MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
 * IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
 * CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
 * TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
 * SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 */

static int scmp(const void *a, const void *b) {
	return strcmp(*(char **)a, *(char **)b);
}

static int icmp(const void *a, const void *b) {
	return *(int*)a - *(int*)b;
}

static int ricmp(const void *a, const void *b) {  /* Sorts descending. */
	return *(int*)b - *(int*)a;
}

static unsigned cmp_count;
static int rhucmp(const void *a, const void *b) {  /* Sorts descending, ignores low 16 bits. */
	++cmp_count;
	return (*(unsigned*)b >> 16) - (*(unsigned*)a >> 16);
}

struct three {
    unsigned char b[3];
};

#define i3(x) { { (unsigned char) ((x) >> 16), (unsigned char) ((x) >> 8), (unsigned char) ((x) >> 0) } }

static int tcmp(const void *av, const void *bv) {
    const struct three *a = av, *b = bv;
    int c;
    int i;

    for (i = 0; i < 3; i++) {
        c = (int) a->b[i] - (int) b->b[i];
        if (c)
            return c;
    }
    return 0;
}

#define FAIL(m) do {                                            \
        printf(__FILE__ ":%d: %s failed\n", __LINE__, m);       \
        err++;                                                  \
    } while(0)

int main(int argc, char **argv) {
	int i;
	int err=0;
	/* 26 items -- even */
	char *s[] = {
		"Bob", "Alice", "John", "Ceres",
		"Helga", "Drepper", "Emeralda", "Zoran",
		"Momo", "Frank", "Pema", "Xavier",
		"Yeva", "Gedun", "Irina", "Nono",
		"Wiener", "Vincent", "Tsering", "Karnica",
		"Lulu", "Quincy", "Osama", "Riley",
		"Ursula", "Sam"
	};
	/* 23 items -- odd, prime */
	int n[] = {
		879045, 394, 99405644, 33434, 232323, 4334, 5454,
		343, 45545, 454, 324, 22, 34344, 233, 45345, 343,
		848405, 3434, 3434344, 3535, 93994, 2230404, 4334
	};

	int nx[256];

        struct three t[] = {
                i3(879045), i3(394), i3(99405644), i3(33434), i3(232323), i3(4334), i3(5454),
                i3(343), i3(45545), i3(454), i3(324), i3(22), i3(34344), i3(233), i3(45345), i3(343),
                i3(848405), i3(3434), i3(3434344), i3(3535), i3(93994), i3(2230404), i3(4334)
        };

	(void)argc; (void)argv;

	ip_mergesort(s, sizeof(s)/sizeof(char *), sizeof(char *), scmp);
	for (i=0; i<(int) (sizeof(s)/sizeof(char *)-1); i++) {
		if (strcmp(s[i], s[i+1]) > 0) {
			FAIL("string sort");
			for (i=0; i<(int)(sizeof(s)/sizeof(char *)); i++)
				printf("\t%s\n", s[i]);
			break;
		}
	}

	ip_mergesort(n, sizeof(n)/sizeof(int), sizeof(int), icmp);
	for (i=0; i<(int)(sizeof(n)/sizeof(int)-1); i++) {
		if (n[i] > n[i+1]) {
			FAIL("integer sort");
			for (i=0; i<(int)(sizeof(n)/sizeof(int)); i++)
				printf("\t%d\n", n[i]);
			break;
		}
	}

	ip_mergesort(n, sizeof(n)/sizeof(int), sizeof(int), ricmp);
	for (i=0; i<(int)(sizeof(n)/sizeof(int)-1); i++) {
		if (n[i] < n[i+1]) {
			FAIL("integer sort inplace merge");
			for (i=0; i<(int)(sizeof(n)/sizeof(int)); i++)
				printf("\t%d\n", n[i]);
			break;
		}
	}

	for (i = 0; i + 0U < sizeof(nx)/sizeof(nx[0]); ++i) {
		nx[i] = ~(i >> 3) << 16 | (0xffff - i);
	}
	cmp_count = 0;
	ip_mergesort(nx, sizeof(nx)/sizeof(nx[0]), sizeof(nx[0]), rhucmp);
	for (i=0; i<(int)(sizeof(nx)/sizeof(nx[0])-1); i++) {
		if (nx[i] < nx[i+1]) {
			FAIL("integer sort inplace merge long already_sorted");
			for (i=0; i<(int)(sizeof(nx)/sizeof(nx[0])); i++)
				printf("\t0x%04x\n", nx[i]);
			break;
		}
	}
	if (cmp_count != sizeof(nx)/sizeof(nx[0]) - 1) {
		FAIL("too many comparisons for already sorted input");
		printf("cmp_count=%d expected=%d\n", cmp_count, (int)(sizeof(nx)/sizeof(nx[0])));
	}

	for (i = 0; i + 0U < sizeof(nx)/sizeof(nx[0]); ++i) {
		nx[i] = (i % 13) << 16 | (0xffff - i);
	}
	ip_mergesort(nx, sizeof(nx)/sizeof(nx[0]), sizeof(nx[0]), rhucmp);
	for (i=0; i<(int)(sizeof(nx)/sizeof(nx[0])-1); i++) {
		if (nx[i] < nx[i+1]) {
			FAIL("integer sort inplace merge long");
			for (i=0; i<(int)(sizeof(nx)/sizeof(nx[0])); i++)
				printf("\t0x%04x\n", nx[i]);
			break;
		}
	}

        ip_mergesort(t, sizeof(t)/sizeof(t[0]), sizeof(t[0]), tcmp);
	for (i=0; i<(int)(sizeof(t)/sizeof(t[0])-1); i++) {
                if (tcmp(&t[i], &t[i+1]) > 0) {
			FAIL("three byte sort");
			for (i=0; i<(int)(sizeof(t)/sizeof(t[0])); i++)
                                printf("\t0x%02x%02x%02x\n", t[i].b[0], t[i].b[1], t[i].b[2]);
			break;
		}
	}


	return err;
}
