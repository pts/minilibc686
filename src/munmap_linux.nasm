;
; written by pts@fazekas.hu at Tue Jun  6 01:26:44 CEST 2023
; Compile to i386 ELF .o object: nasm -O999999999 -w+orphan-labels -f elf -o munmap_linux.o munmap_linux.nasm
;
; Code size: 7 bytes.

; Uses: %ifdef CONFIG_PIC
;

bits 32
cpu 386

global mini_munmap
%ifdef CONFIG_SECTIONS_DEFINED
%elifidn __OUTPUT_FORMAT__, bin
section .text align=1
section .rodata align=4
section .data align=4
section .bss align=4
mini_syscall3_AL equ +0x12345678
%else
extern mini_syscall3_AL
section .text align=1
section .rodata align=1
section .data align=1
section .bss align=1
%endif

section .text
mini_munmap:  ; int mini_munmap(void *addr, size_t length);
		mov al, 91  ; __NR_munmap.
		jmp strict near mini_syscall3_AL

%ifdef CONFIG_PIC  ; Already position-independent code.
%endif

; __END__
