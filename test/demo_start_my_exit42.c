/*
 * demo_start_my_exit42.c: exit(42), with no library dependencies, code in inline assembly
 * by pts@fazekas.hu at Wed Jun  7 01:37:03 CEST 2023
 *
 * Supported C compilers: __GNUC__ (GCC, Clang), __WATCOMC__ (OpenWatcom
 * wcc386), __TINYC__ (TinyCC).
 */

#if (defined(__linux__) || defined(__LINUX__)) && (defined(__i386__) || defined(__386__))
#ifdef __WATCOMC__
#  define NORETURN __declspec(noreturn)
#else
#  define NORETURN __attribute__((__noreturn__))
#endif

#ifdef __WATCOMC__
#if 0  /* This works, but it generates an extra jmp. */
__declspec(naked) __declspec(noreturn) static void __watcall my_exit(int exit_code) {
  (void)exit_code;
  __asm {
  		xchg eax, ebx  /* EBX := EAX; EAX := junk. */
  		xor eax, eax
  		inc eax  /* EAX := 1 (__NR_exit). */
		int 0x80  /* Linux i386 syscall. _exit(2) doesn't return. */
  }
}
#else  /* This will be inlined to the call site. */
/* OpenWatcom is smart enough not to populate the higher bits of EBX. */
__declspec(noreturn) static void my_exit(unsigned char status);
#pragma aux my_exit = "xor eax, eax"  "inc eax"  "int 0x80"  __parm [ __bl ];
#endif
#else  /* __WATCOMC__ */  /* This works in __GNUC__ and __TINYC__. */
NORETURN static __inline__ void my_exit(unsigned char status) {
  __asm__ __volatile__ ("xor %%eax, %%eax ; inc %%eax; int $0x80" : : "b" (status) : "memory");
#ifndef __TINYC__
  __builtin_unreachable();
#endif
}
#endif  /* else __WATCOMC__ */
#else
#  error This program is written for Linux i386 target.
#endif  /* __linux__ */

NORETURN  /* Without ths, OpenWatcom (wcc386 without -of+) generates an unnecessary `push ebx' at the benning of _start. GCC and Clang generate the `push ebx' anyway. */
void _start(void) {
  my_exit(42);
}
