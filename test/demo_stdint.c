#include <stdint.h>

typedef char assert_int8_t[sizeof(int8_t) == 1 ? 1 : -1];
typedef char assert_int16_t[sizeof(int16_t) == 2 ? 1 : -1];
typedef char assert_int32_t[sizeof(int32_t) == 4 ? 1 : -1];
typedef char assert_int64_t[sizeof(int64_t) == 8 ? 1 : -1];  /* signed integer type with width of exactly 8, 16, 32 and 64 bits respectively with no padding bits and using 2's complement for negative values (provided only if the implementation directly supports the type) */
typedef char assert_int_fast8_t[sizeof(int_fast8_t) == 1 ? 1 : -1];
typedef char assert_int_fast16_t[sizeof(int_fast16_t) == 4 ? 1 : -1];
typedef char assert_int_fast32_t[sizeof(int_fast32_t) == 4 ? 1 : -1];
typedef char assert_int_fast64_t[sizeof(int_fast64_t) == 8 ? 1 : -1];  /* fastest signed integer type with width of at least 8, 16, 32 and 64 bits respectively */
typedef char assert_int_least8_t[sizeof(int_least8_t) == 1 ? 1 : -1];
typedef char assert_int_least16_t[sizeof(int_least16_t) == 2 ? 1 : -1];
typedef char assert_int_least32_t[sizeof(int_least32_t) == 4 ? 1 : -1];
typedef char assert_int_least64_t[sizeof(int_least64_t) == 8 ? 1 : -1];  /* smallest signed integer type with width of at least 8, 16, 32 and 64 bits respectively */
typedef char assert_intmax_t[sizeof(intmax_t) == 8 ? 1 : -1];  /* maximum width integer type */
typedef char assert_intptr_t[sizeof(intptr_t) == 4 ? 1 : -1];  /* integer type capable of holding a pointer */
typedef char assert_uint8_t[sizeof(uint8_t) == 1 ? 1 : -1];
typedef char assert_uint16_t[sizeof(uint16_t) == 2 ? 1 : -1];
typedef char assert_uint32_t[sizeof(uint32_t) == 4 ? 1 : -1];
typedef char assert_uint64_t[sizeof(uint64_t) == 8 ? 1 : -1];  /* unsigned integer type with width of exactly 8, 16, 32 and 64 bits respectively (provided only if the implementation directly supports the type) */
typedef char assert_uint_fast8_t[sizeof(uint_fast8_t) == 1 ? 1 : -1];
typedef char assert_uint_fast16_t[sizeof(uint_fast16_t) == 4 ? 1 : -1];
typedef char assert_uint_fast32_t[sizeof(uint_fast32_t) == 4 ? 1 : -1];
typedef char assert_uint_fast64_t[sizeof(uint_fast64_t) == 8 ? 1 : -1];  /* fastest unsigned integer type with width of at least 8, 16, 32 and 64 bits respectively */
typedef char assert_uint_least8_t[sizeof(uint_least8_t) == 1 ? 1 : -1];
typedef char assert_uint_least16_t[sizeof(uint_least16_t) == 2 ? 1 : -1];
typedef char assert_uint_least32_t[sizeof(uint_least32_t) == 4 ? 1 : -1];
typedef char assert_uint_least64_t[sizeof(uint_least64_t) == 8 ? 1 : -1];  /* smallest unsigned integer type with width of at least 8, 16, 32 and 64 bits respectively */
typedef char assert_uintmax_t[sizeof(uintmax_t) == 8 ? 1 : -1];  /* maximum width unsigned integer type */
typedef char assert_uintptr_t[sizeof(uintptr_t) == 4 ? 1 : -1];  /* unsigned integer type capable of holding a pointer */

