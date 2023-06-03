#ifndef _STDINT_H
#define _STDINT_H
#include <_preincl.h>

#define __int8_t_defined
typedef signed char int8_t;
typedef short int int16_t;
typedef int int32_t;
__extension__ typedef long long int int64_t;  /* __extension__ is to make it work with `gcc -ansi -pedantic'. */
typedef unsigned char uint8_t;
typedef unsigned short int uint16_t;
typedef unsigned int uint32_t;
__extension__ typedef unsigned long long int uint64_t;  /* __extension__ is to make it work with `gcc -ansi -pedantic'. */

#endif  /* _STDINT_H */
