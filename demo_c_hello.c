#include <stdio.h>

#if !(defined(__WATCOMC__) && defined(__i386__))
  /* GCC 7.5.0 generates the assembly code below. */
  int main(int argc, char **argv) {
    printf("Hello, %s!\n", argc < 2 ? "World" : argv[1]);
    return 0;
  }
#else  /* For reproducible results, we implement main(...) in OpenWatcom assembly. */
  /* These compilations produce bit-by-bit identical executables:
   *
   * $ minicc -mprintf-mini -mno-envp -mconst-seg -o demo1 demo_c_hello.c
   * $ minicc --gcc -mprintf-mini -mno-envp -o demo2 demo_c_hello.c  # Only with GCC 7.5.0.
   * $ tools/nasm-0.98.39 -O999999999 -w+orphan-labels -f bin -o demo3 demo_hello_linux_printf.nasm && chmod +x demo3
   */
  static const char __based(__segname("_CONST")) str_world[] = "World";
  static const char __based(__segname("_CONST")) str_hello[] = "Hello, %s!\n";
  __declspec(naked) int main(int argc, char **argv) {
    (void)argc; (void)argv;
    __asm {
		push ebp
		mov eax, offset str_world
		dw 0xe589  /* mov ebp, esp */
		cmp dword ptr [ebp+8], 1
		jle short @$14  /* OpenWatcom doesn't optimized this jump without `short'. */
		mov eax, [ebp+0xc]
		mov eax, [eax+4]  /* argv[1]. */
      @$14:	push eax
		push offset str_hello
		call printf
		dw 0xc031  /* xor eax,eax */
		leave
		ret
    }
  }
#endif
