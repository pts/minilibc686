;
; written by pts@fazekas.hu at Sun Jun  2 00:21:21 CEST 2024
; Compile to i386 ELF .o object: nasm -O999999999 -w+orphan-labels -f elf -o gettimeofday_linux.o gettimeofday_linux.nasm
;
; Code size: 0x7 bytes.
;
; Uses: %ifdef CONFIG_PIC
;

bits 32
cpu 386

global mini_gettimeofday
%ifdef CONFIG_SECTIONS_DEFINED
%elifidn __OUTPUT_FORMAT__, bin
section .text align=1
section .rodata align=4
section .data align=4
section .bss align=4
mini_syscall3_AL equ +0x12345679
%else
extern mini_syscall3_AL
section .text align=1
section .rodata align=1
section .data align=1
section .bss align=1
%endif

section .text
mini_gettimeofday:  ; int mini_gettimeofday(struct timeval *tv, struct timezone *tz);
		mov al, 78  ; __NR_gettimeofday.
		jmp strict near mini_syscall3_AL

%ifdef CONFIG_PIC  ; Already position-independent code.
%endif

; __END__
