;
; written by pts@fazekas.hu at Sun May 21 21:00:32 CEST 2023
; Compile to i386 ELF .o object: nasm -O999999999 -w+orphan-labels -f elf -o ftruncate_linux.o ftruncate_linux.nasm
;
; Code size: 0x1d bytes.
;
; Uses: %ifdef CONFIG_PIC
;

bits 32
cpu 386

global mini_ftruncate
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
mini_ftruncate:  ; int mini_ftruncate(int fd, off_t length);
; This system call supports 32 bits only.
		mov al, 93  ; __NR_ftruncate.
		jmp strict near mini_syscall3_AL

%ifdef CONFIG_PIC  ; Already position-independent code.
%endif

; __END__
