/*
 * demo_c_obj.c: demonstrates various object file format features
 * by pts@fazekas.hu at Thu Jun  1 12:21:03 CEST 2023
 *
 * Compile: owcc -blinux -Os -fno-stack-check -fsigned-char -march=i386 -mabi=cdecl -W -Wall -Wextra -Werror -c -o demo_c_obj.wcc.obj demo_c_obj.c
 * Compile: wcc386 -q -bt=linux -os -s -j -ecc -W -w4 -wx -we -3r -fo=demo_c_obj.wcc.obj -fr demo_c_obj.c
 * Compile: gcc -m32 -march=i386 -static -fno-pic -U_FORTIFY_SOURCE -fcommon -fno-stack-protector -fno-unwind-tables -fno-asynchronous-unwind-tables -fno-builtin -fno-ident -fsigned-char -ffreestanding -fno-lto -nostdlib -nostdinc -Os -falign-functions=1 -falign-jumps=1 -falign-loops=1 -mpreferred-stack-boundary=2 -W -Wall -Werror -Werror=implicit-function-declaration -c -o demo_c_obj.gcc.o demo_c_obj.c
 */

extern int printf(const char *format, ...);

extern int extern_answers[];

char bss_global0[1];  /* _BSS segment, .bss section. */
int bss_global1[3];
int bss_global2[7];
static char bss_local3[2];

const char knock[] = "Knock?";  /* CONST2 segment, .rodata section (not a string literal). */

#ifdef __GNUC__
__attribute__((__aligned__(4)))  /* GCC 7.5.0 aligns this to 32 byte default. */
#endif
static void * const rodata_local[] = {  /* CONST2 segment, rodata section. Oddly enough, OpenWatcom doesn't align it. */
    (void*)5,
    (void*)6,
    extern_answers + 2,
    (void*)knock,
    bss_global2,
    bss_local3,
    (void*)"World",  /* CONST segment, .rodata.str1.1 section. */ /* OpenWatcom deduplicates this exact match. */
    /*(void*)extern_answers[3]*/  /* Doesn't work. */
};

#ifdef __GNUC__
__attribute__((__aligned__(4)))  /* GCC 7.5.0 aligns this to 32 byte default. */
#endif
static void *data_local[] = {  /* _DATA segment, .data section. */
    (void*)15,
    (void*)16,
    extern_answers + 12,
    bss_global2 + 1,
    bss_local3 + 1,
    (void*)(knock + 2),
    (void*)(rodata_local + 5),
    (void*)"rld",  /* OpenWatcom doesn't deduplicate this suffix match. GCC 7.5.0 deduplicates. */
    /*(void*)extern_answers[13]*/  /* Doesn't work. */
};

#ifdef __GNUC__
__attribute__((__aligned__(4)))  /* GCC 7.5.0 aligns this to 32 byte default. */
#endif
void *data_global[] = {  /* _DATA segment, .data section. */
    (void*)17,
    (void*)18,
    extern_answers + 12,
    bss_global2 + 1,
    bss_local3 + 1,
    (void*)(knock + 2),
    (void*)(rodata_local + 3),
    (void*)(data_local + 2),
    (void*)"rld",  /* OpenWatcom doesn't deduplicate this suffix match. GCC 7.5.0 deduplicates. */
    /*(void*)extern_answers[13]*/  /* Doesn't work. */
};

#ifdef __GNUC__
__attribute__((__aligned__(4)))  /* GCC 7.5.0 aligns this to 32 byte default. */
#endif
void * const rodata_global[] = {  /* CONST2 segment. Oddly enough, OpenWatcom doesn't align it. */
    (void*)7,
    (void*)8,
    extern_answers + 2,
    (void*)knock,
    bss_global2,
    bss_local3,
    (void*)(rodata_local + 4),
    (void*)(data_local + 1),
    (void*)(data_global + 2),
    (void*)"World",  /* CONST segment. */ /* OpenWatcom and GCC 7.5.0 deduplicate this exact match. */
    /*(void*)extern_answers[3]*/  /* Doesn't work. */
};

/* _TEXT segment, .text section. */
#ifdef __GNUC__
__attribute__((__noinline__))
#endif
static const char *get_addressee(int argc, char **argv) {
  return argc < 2 ? "World" : argv[1];
}

/* _TEXT segment, .text section. */
#ifdef __GNUC__
__attribute__((__noinline__))
#endif
int get_exit_code(int argc) {
  return argc >= 1 && argc <= 9;
}

/* _TEXT segment, .text.startup section. */
int main(int argc, char **argv) {  /* _TEXT segment. */
  printf("Hello, %s!\n", get_addressee(argc, argv));
  return get_exit_code(argc);
}
