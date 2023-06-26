;
; written by pts@fazekas.hu at Mon Jun 26 11:20:51 CEST 2023
; Compile to i386 ELF .o object: nasm -O999999999 -w+orphan-labels -f elf -o ffs.o ffs.nasm
;
; Code size: 0xc bytes.
;
; Uses: %ifdef CONFIG_PIC
;

bits 32
cpu 386

global mini_ffs
global mini_ffsl
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
mini_ffs:  ; int mini_ffs(int i);
mini_ffsl:  ; int mini_ffsl(long i);
		bsf eax, [esp+0x4]  ; Argument i.
		jz .zero
		inc eax
		ret
.zero:		xor eax, eax
		ret

%ifdef CONFIG_PIC  ; Already position-independent code.
%endif

; __END__
