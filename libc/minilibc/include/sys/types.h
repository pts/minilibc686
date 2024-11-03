#ifndef _SYS_TYPES_H
#define _SYS_TYPES_H
#include <_preincl.h>

typedef unsigned size_t;
typedef int ssize_t;
typedef long off_t;  /* Still 32 bits only. */
__extension__ typedef long long loff_t;
__extension__ typedef long long off64_t;  /* __extension__ is to make it work with `gcc -ansi -pedantic'. */
typedef unsigned mode_t;
typedef int ptrdiff_t;
typedef unsigned uid_t;
typedef unsigned gid_t;
typedef int pid_t;
typedef int id_t;
__extension__ typedef long long quad_t;  /* Always 64-bit. */
__extension__ typedef unsigned long long u_quad_t;  /* Always 64-bit. */
#ifndef __LIBC_TIME_T_DEFINED
#  define __LIBC_TIME_T_DEFINED
  typedef long int time_t;  /* Also defined in <time.h> and <sys/time.h>. */
#endif

#endif  /* _SYS_TYPES_H */
