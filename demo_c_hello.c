#include <stdio.h>

#if !(defined(__WATCOMC__) && defined(__i386__))
  /* GCC 7.5.0 generates the assembly code below. */
  int main(int argc, char **argv) {
    printf("Hello, %s!\n", argc < 2 ? "World" : argv[1]);
    return 0;
  }
#else  /* For reproducible results, we implement main(...) in assembly. */
  /* This is not bit-by-bit identical to demo_hello_linux_printf.prog, but the
   * byte size is equal. The difference is because str_world and str_hello are
   * put inside .text, not after it.
   */
  /* We put string literals to section .text, so that they are byte-aligned. */
  void str_world(void);
  void str_hello(void);
  __declspec(naked) int main(int argc, char **argv) {
    (void)argc; (void)argv;
    __asm {
                  push ebp
                  mov eax, offset str_world
                  mov ebp, esp
                  cmp dword ptr [ebp+8], 1
                  jle short @$14  /* OpenWatcom doesn't optimized this jump without `short'. */
                  mov eax, [ebp+0xc]
                  mov eax, [eax+4]  /* argv[1]. */
  @$14:		push eax
                  push offset str_hello
                  call printf
                  xor eax, eax
                  leave
                  ret
    }
  }
  __declspec(naked) void str_hello(void) { __asm { db 'Hell', 'o, %', 's!', 10, 0
  } }
  __declspec(naked) void str_world(void) { __asm { db 'Worl', 'd', 0
  } }
#endif
