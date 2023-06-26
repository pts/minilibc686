;
; written by pts@fazekas.hu at Mon Jun 26 11:20:51 CEST 2023
; Compile to i386 ELF .o object: nasm -O999999999 -w+orphan-labels -f elf -o ffsll.o ffsll.nasm
;
; Code size: 0x17 bytes.
;
; Uses: %ifdef CONFIG_PIC
;

bits 32
cpu 386

global mini_ffsll
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
mini_ffsll:  ; int mini_ffsll(long long i);
		bsf eax, [esp+4]  ; Low dword of argument i.
		jz .low_is_0
		inc eax
		ret
.low_is_0:	bsf eax, [esp+8]  ; High dword of argument i.
		jz .zero
		add eax, byte 0x21
		ret
.zero:		xor eax, eax
		ret

%ifdef CONFIG_PIC  ; Already position-independent code.
%endif

; __END__
