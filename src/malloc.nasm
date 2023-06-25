;
; written by pts@fazekas.hu at Sun Jun 25 23:29:13 CEST 2023
; Compile to i386 ELF .o object: nasm -O999999999 -w+orphan-labels -f elf -o malloc.o malloc.nasm
;
; Uses: %ifdef CONFIG_PIC
;

bits 32
cpu 386

global mini_malloc
%ifidn __OUTPUT_FORMAT__, bin
section .text align=1
section .rodata align=1
section .data align=1
section .bss align=1
mini_realloc  equ +0x12345678
%else
extern mini_realloc
section .text align=1
section .rodata align=1
section .data align=1
section .bss align=1
%endif

section .text
mini_malloc:  ; void *mini_malloc(size_t size);
		push dword [esp+4]
		push byte 0
		call mini_realloc
		times 2 pop edx  ; Clean up arguments of mini_realloc from the stack.
		ret

%ifdef CONFIG_PIC  ; Already position-independent code.
%endif

; __END__
