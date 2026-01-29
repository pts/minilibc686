;
; written by pts@fazekas.hu at Sun Jun  4 13:34:21 CEST 2023
; Compile to i386 ELF .o object: nasm -O999999999 -w+orphan-labels -f elf -o getpid_linux.o getpid_linux.nasm
;
; Code size: 7 bytes.

; Uses: %ifdef CONFIG_PIC
;

bits 32
cpu 386

global mini_getpid
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
mini_getpid:  ; uid_t mini_getpid(void);
		mov al, 20  ; __NR_getpid.
		jmp strict near mini_syscall3_AL

%ifdef CONFIG_PIC  ; Already position-independent code.
%endif

; __END__
