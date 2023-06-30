;
; written by pts@fazekas.hu at Fri Jun 30 01:26:23 CEST 2023
; Compile to i386 ELF .o object: nasm -O999999999 -w+orphan-labels -f elf -o asctime.o asctime.nasm
;
; Uses: %ifdef CONFIG_PIC
;

bits 32
cpu 386

global mini_asctime
%ifdef CONFIG_SECTIONS_DEFINED
%elifidn __OUTPUT_FORMAT__, bin
section .text align=1
section .rodata align=1
section .data align=1
section .bss align=1
mini_asctime_r equ +0x12345678
mini___M_ctime_buf equ +0x12345679
%else
extern mini_asctime_r
extern mini___M_ctime_buf
section .text align=1
section .rodata align=1
section .data align=1
section .bss align=1
%endif

section .text
mini_asctime:  ; char *mini_asctime(const struct tm *tm);
		push mini___M_ctime_buf
		push dword [esp+8]  ; Argument tm.
		call mini_asctime_r  ; TODO(pts): Inline it with smart linking if only mini_asctime(...) is used.
		times 2 pop edx  ; Clean up arguments of mini_asctime_r from the stack.
		ret

%ifdef CONFIG_PIC
%error Not PIC because it uses global variable mini___M_ctime_buf.
times 1/0 nop
%endif

; __END__
