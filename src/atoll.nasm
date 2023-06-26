;
; written by pts@fazekas.hu at Mon Jun 26 01:26:15 CEST 2023
; Compile to i386 ELF .o object: nasm -O999999999 -w+orphan-labels -f elf -o atoll.o atoll.nasm
;
; Uses: %ifdef CONFIG_PIC
;

bits 32
cpu 386

global mini_atoll
%ifdef CONFIG_SECTIONS_DEFINED
%elifidn __OUTPUT_FORMAT__, bin
section .text align=1
section .rodata align=1
section .data align=1
section .bss align=4
mini_strtoll equ +0x12345678
%else
extern mini_strtoll
section .text align=1
section .rodata align=1
section .data align=1
section .bss align=4
%endif

section .text
mini_atoll:  ; long long mini_atoll(const char *nptr);
		push byte 10
		push byte 0  ; NULL.
		push dword [esp+3*4]  ; Argument nptr.
		call mini_strtoll
		add esp, byte 3*4  ; Clean up arguments of mini_strtol from the stack.
		ret

%ifdef CONFIG_PIC  ; Already position-independent code.
%endif

; __END__
