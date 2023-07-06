# by pts@fazekas.hu at Thu Jul  6 00:50:05 CEST 2023

.text
.global main
main:  # int main(int argc, char **argv);
# #include <stdio.h>
# /* GCC 7.5.0 generates the assembly code below. */
# int main(int argc, char **argv) {
#   printf("Hello, %s!\n", argc < 2 ? "World" : argv[1]);
#   return 0;
# }
		push %ebp
		mov $str_world, %eax
		mov %esp, %ebp
		cmpl $1, 8(%ebp)
		jle .L14
		mov 0xc(%ebp), %eax
		mov 4(%eax), %eax  # argv[1].
.L14:		push %eax
		push $str_hello
		#call printf  # For non-minilibc686.
		call mini_printf
		xor %eax, %eax
		leave
		ret

.section .rodata
str_world:	.string "World"
str_hello:	.string "Hello, %s!\n"
