#include <stdio.h>

#if !((defined(__WATCOMC__) && defined(__386__)) || (defined(__GNUC__) && defined(__i386__)))
  /* GCC 7.5.0 generates the assembly code below. */
  int main(int argc, char **argv) {
    printf("Hello, %s!\n", argc < 2 ? "World" : argv[1]);
    return 0;
  }
#elif defined(__WATCOMC__)  /* For reproducible results, we implement main(...) in OpenWatcom assembly. */
  /* These compilations produce bit-by-bit identical executables:
   *
   * $ minicc -mprintf-mini -mno-envp -mconst-seg -o demo1 demo_c_hello.c
   * $ minicc --gcc=4.1 -mprintf-mini -mno-envp -o demo2 demo_c_hello.c  # Any GCC >=4.1.
   * $ minicc --pcc -mprintf-mini -mno-envp -o demo3 demo_c_hello.c
   * $ tools/nasm-0.98.39 -O999999999 -w+orphan-labels -f bin -o demo4 demo_hello_linux_printf.nasm && chmod +x demo3
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
#elif defined(__GNUC__)  /* Works with GCC >=4.1 (possibly earlier) and PCC 1.1.0. */
#  ifdef __MINILIBC686__
#    define MINI_PREFIX "mini_"
#  else
#    define MINI_PREFIX
#  endif
#  if 0  /* Unfortunately, the order of these depends on the GCC version, this only works for GCC >= 4.6. */
    __attribute__((__aligned__(1))) const char str_hello[] = "Hello, %s!\n";
    __attribute__((__aligned__(1))) const char str_world[] = "World";
#  endif
  __asm__("\
    .global main;\
    main:;\
		push %ebp;\
		mov $str_world, %eax;\
		mov %esp, %ebp;\
		cmpl $1, 8(%ebp);\
		jle .L14;\
		mov 0xc(%ebp), %eax;\
		mov 4(%eax), %eax  /* argv[1]. */;\
    .L14:	push %eax;\
		push $str_hello;\
		call " MINI_PREFIX "printf;\
		xor %eax, %eax;\
		leave;\
		ret;\
    .section .rodata;\
    str_world:	.string \"World\";\
    str_hello:	.string \"Hello, %s!\\n\";\
  ");
#endif
