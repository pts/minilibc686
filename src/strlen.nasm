;
; written by pts@fazekas.hu at Tue May 16 18:16:29 CEST 2023
; Compile to i386 ELF .o object: nasm -O999999999 -w+orphan-labels -f elf -o strlen.o strlen.nasm
;
; Code size: 0x11 bytes.
;
; This is the fast implementation (using `repne scasb'), but the slow
; implementation isn't shorter either.

; Uses: %ifdef CONFIG_PIC
;

bits 32
cpu 386

global mini_strlen
%ifdef CONFIG_SECTIONS_DEFINED
%elifidn __OUTPUT_FORMAT__, bin
section .text align=1
section .rodata align=1
section .data align=1
section .bss align=1
%else
section .text align=1
section .rodata align=1
section .data align=1
section .bss align=1
%endif

section .text
mini_strlen:  ; size_t mini_strlen(const char *s);
		push edi
		mov edi, [esp+8]  ; Argument s.
		xor eax, eax
		or ecx, byte -1  ; ECX := -1.
		repne scasb
		sub eax, ecx
		dec eax
		dec eax
		pop edi
		ret

%ifdef CONFIG_PIC  ; Already position-independent code.
%endif

; __END__
