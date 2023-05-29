#ifndef _SYS_TYPES_H
#define _SYS_TYPES_H

typedef unsigned size_t;
typedef int ssize_t;
typedef long off_t;  /* Still 32 bits only. */
__extension__ typedef long long off64_t;  /* __extension__ is to make it work with `gcc -ansi -pedantic'. */
typedef unsigned mode_t;

#endif  /* _SYS_TYPES_H */
