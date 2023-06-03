#ifndef _CTYPE_H
#define _CTYPE_H
#include <_preincl.h>

/* These functions are also included in minilibc686, but, the *_MINIRP3
 * variants are more efficient to use in newly compiled code.
 */
__LIBC_FUNC_MINIRP3(int, isalpha, (int c),);
__LIBC_FUNC_MINIRP3(int, isdigit, (int c),);
__LIBC_FUNC_MINIRP3(int, isxdigit, (int c),);
__LIBC_FUNC_MINIRP3(int, isspace, (int c),);
__LIBC_FUNC_MINIRP3(int, tolower, (int c),);
__LIBC_FUNC_MINIRP3(int, toupper, (int c),);

#endif  /* _CTYPE_H */
