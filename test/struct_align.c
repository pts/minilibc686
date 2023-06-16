#define STATIC_ASSERT(name, value) typedef char __static_assert_##name[(value) ? 1 : -1]

struct mystat64 { unsigned st_nlink; unsigned long long st_rdev; unsigned __pad2; unsigned long long st_ino; };
STATIC_ASSERT(mystat64_size, sizeof(struct mystat64) == 24);  /* Affected by `wcc386 -zp4'. */

struct mid { unsigned st_nlink; unsigned long long st_rdev; };
STATIC_ASSERT(mid_size, sizeof(struct mid) == 12);  /* Affected by `wcc386 -zp4'. */

struct midd { unsigned st_nlink; double d; };
STATIC_ASSERT(midd_size, sizeof(struct midd) == 12);  /* Affected by `wcc386 -zp4'. */

struct ci { char c; int i; };
STATIC_ASSERT(ci_size, sizeof(struct ci) == 8);

struct cs { char c; short s; };
STATIC_ASSERT(cs_size, sizeof(struct cs) == 4);

struct cc { char c1; char c2; };
STATIC_ASSERT(cc_size, sizeof(struct cc) == 2);
