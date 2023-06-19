/*
 * bitfield.c: demo program showing how bit fields are laid out in memory.
 * by pts@fazekas.hu at Mon Jun 19 12:32:11 CEST 2023
 *
 * For i386, The get_*_b(...) and get_*_n(...) functions are equivalent with
 * TCC, PCC, TinyCC, GCC and Clang.
 */

typedef char static_assert_unsigned_size[sizeof(unsigned) == 4 ? 1 : -1];

struct bfs {
  unsigned low : 1;
  unsigned middle : 30;
  unsigned high : 1;
};

struct normals {
  unsigned u;
};

unsigned get_low_b(const struct bfs *bfs) { return bfs->low; }
unsigned get_middle_b(const struct bfs *bfs) { return bfs->middle; }
unsigned get_high_b(const struct bfs *bfs) { return bfs->high; }

unsigned get_low_n(const struct normals *normals) { return normals->u & 1; }
#ifdef __WATCOMC__
  unsigned get_middle_n(const struct normals *normals) { return normals->u << 1 >> 2; }  /* Make the code math exactly, wcc386 will unify the functoin implementations. */
#else
  unsigned get_middle_n(const struct normals *normals) { return (normals->u >> 1) & ((1 << 30) - 1); }
#endif
unsigned get_high_n(const struct normals *normals) { return normals->u >> 31; }
