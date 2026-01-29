;
; written by pts@fazekas.hu at Sun Apr 28 00:29:12 CEST 2024
; Compile to i386 ELF .o object: nasm -O999999999 -w+orphan-labels -f elf -o time_linux.o time_linux.nasm
;
; Code size: 7 bytes.

; Uses: %ifdef CONFIG_PIC
;

bits 32
cpu 386

global mini_time
%ifdef CONFIG_SECTIONS_DEFINED
%elifidn __OUTPUT_FORMAT__, bin
section .text align=1
section .rodata align=1
section .data align=1
section .bss align=1
mini_syscall3_AL equ +0x12345678
%else
extern mini_syscall3_AL
section .text align=1
section .rodata align=1
section .data align=1
section .bss align=1
%endif

section .text
mini_time:  ; time_t time(time_t *tloc);
		mov al, 13  ; __NR_time.
		jmp strict near mini_syscall3_AL

%ifdef CONFIG_PIC  ; Already position-independent code.
%endif

; __END__
