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
 * Based on __merge_without_buffer https://github.com/gcc-mirror/gcc/blob/9ed4fcfe47f28b36c73d74109898514ef4da00fb/libstdc%2B%2B-v3/include/bits/stl_algo.h#L2426
 * Based on ip_merge in https://stackoverflow.com/a/22839426/97248
 * !! TODO(pts): Compare it with the Java version: http://thomas.baudel.name/Visualisation/VisuTri/inplacestablesort.html
 */

#if defined(__WATCOMC__) && defined(__386__)
  /* !! TODO(pts): Do 2 bytes or 4 bytes at a time. */
  static __declspec(naked) void __watcall reverse_(char *a, char *b) { (void)a; (void)b; __asm {
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
static void reverse_(char *a, char *b) {
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
    Lreverses:	push eax
		push edx
		push ebx
		call reverse_  /* reverse_(eax, edx); */
		pop edx
		pop eax
		pop ebx
		push eax
		push edx
		push ebx
		call reverse_  /* reverse_(edx. ebx); */
		pop eax
		pop edx
		pop ebx
		call reverse_
    Ldone:	ret
  } }
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
  /* !! TODO(pts): Use insertion sort for 2 <= n <= 16 etc. */
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
