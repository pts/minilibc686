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
#define _GNU_SOURCE
#include <stdlib.h>
#include <stdio.h>
#include <string.h>

void mini_qsort(void *base, size_t n, size_t size, int (*cmp)(const void*, const void*));  /* Function under test. */

#if defined(__WATCOMC__) && defined(__386__)
#  define CMPDECL __cdecl
#else
#  define CMPDECL
#endif

#if 0
static int CMPDECL debugcmp(const void *a, const void *b) {
  printf("DEBUGCMP (%s) (%s)\n", a, b);
  return 42;
}
#endif

static int CMPDECL scmp(const void *a, const void *b) {
	return strcmp(*(char **)a, *(char **)b);
}

static int CMPDECL icmp(const void *a, const void *b) {
	return *(int*)a - *(int*)b;
}

static int CMPDECL ricmp(const void *a, const void *b) {  /* Sorts descending. */
	return *(int*)b - *(int*)a;
}

static unsigned cmp_count;
static int CMPDECL rhucmp(const void *a, const void *b) {  /* Sorts descending, ignores low 16 bits. */
	++cmp_count;
	return (*(unsigned*)b >> 16) - (*(unsigned*)a >> 16);
}

struct three {
    unsigned char b[3];
};

#define i3(x) { { (unsigned char) ((x) >> 16), (unsigned char) ((x) >> 8), (unsigned char) ((x) >> 0) } }

static int CMPDECL tcmp(const void *av, const void *bv) {
    const struct three *a = (const struct three*)av, *b = (const struct three*)bv;
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
	const char *s[] = {
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
	const int nx_sizes[] = {0, 1, 2, 3, 4, 5, 6, sizeof(nx) / sizeof(nx[0])};
	int nxsi;
	unsigned expected_cmp_count;

        struct three t[] = {
                i3(879045), i3(394), i3(99405644), i3(33434), i3(232323), i3(4334), i3(5454),
                i3(343), i3(45545), i3(454), i3(324), i3(22), i3(34344), i3(233), i3(45345), i3(343),
                i3(848405), i3(3434), i3(3434344), i3(3535), i3(93994), i3(2230404), i3(4334)
        };

	(void)argc; (void)argv;

#if 0
	{
		struct ip_cs cs;
		int r;
		cs.base = "HelloWorld"; cs.item_size = 3; cs.cmp = debugcmp;
		r = ip_cmp(&cs, 1, 2);
		printf("r=%d\n", r);
	}
#endif

	mini_qsort(s, sizeof(s)/sizeof(char *), sizeof(char *), scmp);
	for (i=0; i<(int) (sizeof(s)/sizeof(char *)-1); i++) {
		if (strcmp(s[i], s[i+1]) > 0) {
			FAIL("string sort");
			for (i=0; i<(int)(sizeof(s)/sizeof(char *)); i++)
				printf("\t%s\n", s[i]);
			break;
		}
	}

	mini_qsort(n, sizeof(n)/sizeof(int), sizeof(int), icmp);
	for (i=0; i<(int)(sizeof(n)/sizeof(int)-1); i++) {
		if (n[i] > n[i+1]) {
			FAIL("integer sort");
			for (i=0; i<(int)(sizeof(n)/sizeof(int)); i++)
				printf("\t%d\n", n[i]);
			break;
		}
	}

	mini_qsort(n, sizeof(n)/sizeof(int), sizeof(int), ricmp);
	for (i=0; i<(int)(sizeof(n)/sizeof(int)-1); i++) {
		if (n[i] < n[i+1]) {
			FAIL("integer sort inplace merge");
			for (i=0; i<(int)(sizeof(n)/sizeof(int)); i++)
				printf("\t%d\n", n[i]);
			break;
		}
	}

	for (nxsi = 0; nxsi + 0U < sizeof(nx_sizes) / sizeof(nx_sizes[0]); ++nxsi) {
		for (i = 0; i < nx_sizes[nxsi]; ++i) {
			nx[i] = ~(i >> 3) << 16 | (0xffff - i);
		}
		cmp_count = 0;
		mini_qsort(nx, nx_sizes[nxsi], sizeof(nx[0]), rhucmp);
#if DO_STABLE
		for (i=1; i < nx_sizes[nxsi]; i++) {
			if (nx[i-1] < nx[i]) {
				FAIL("integer sort inplace merge long already_sorted");
				for (i=0; i< nx_sizes[nxsi]; i++)
					printf("\t0x%04x\n", nx[i]);
				break;
			}
		}
		expected_cmp_count = nx_sizes[nxsi] == 0 ? 0 : nx_sizes[nxsi] - 1;
#if DO_SHORTCUT_OPT
		if (cmp_count != expected_cmp_count)
#else
		if (cmp_count < expected_cmp_count)
#endif
		{
			FAIL("too many comparisons for already sorted input");
			printf("cmp_count=%u expected=%u\n", cmp_count, expected_cmp_count);
		}
#endif
	}

	for (i = 0; i + 0U < sizeof(nx)/sizeof(nx[0]); ++i) {
		nx[i] = (i % 13) << 16 | (0xffff - i);
	}
	mini_qsort(nx, sizeof(nx)/sizeof(nx[0]), sizeof(nx[0]), rhucmp);
#if DO_STABLE
	for (i=0; i<(int)(sizeof(nx)/sizeof(nx[0])-1); i++) {
		if (nx[i] < nx[i+1]) {
			FAIL("integer sort inplace merge long");
			for (i=0; i<(int)(sizeof(nx)/sizeof(nx[0])); i++)
				printf("\t0x%04x\n", nx[i]);
			break;
		}
	}
#endif

        mini_qsort(t, sizeof(t)/sizeof(t[0]), sizeof(t[0]), tcmp);
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
