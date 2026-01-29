;
; written by pts@fazekas.hu at Fri Jun 23 10:31:44 CEST 2023
; Compile to i386 ELF .o object: nasm -O999999999 -w+orphan-labels -f elf -o atoi.o atoi.nasm
;
; Uses: %ifdef CONFIG_PIC
;

bits 32
cpu 386

global mini_atoi
global mini_atol
%ifdef CONFIG_SECTIONS_DEFINED
%elifidn __OUTPUT_FORMAT__, bin
section .text align=1
section .rodata align=1
section .data align=1
section .bss align=1
mini_strtol equ +0x12345678
%else
extern mini_strtol
section .text align=1
section .rodata align=1
section .data align=1
section .bss align=1
%endif

section .text
mini_atoi:  ; int mini_atoi(const char *nptr);
mini_atol:  ; int mini_atol(const char *nptr);
; Like https://man7.org/linux/man-pages/man3/atoi.3.html and uClibc 0.9.30.1: strtol(nptr, NULL, 10);
		push byte 10
		push byte 0  ; NULL.
		push dword [esp+3*4]  ; Argument nptr.
		call mini_strtol
		add esp, byte 3*4  ; Clean up arguments of mini_strtol from the stack.
		ret

%ifdef CONFIG_PIC  ; Already position-independent code.
%endif

; __END__
