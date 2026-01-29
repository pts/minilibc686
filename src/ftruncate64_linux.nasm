;
; written by pts@fazekas.hu at Thu Feb  6 15:36:51 CET 2025
; Compile to i386 ELF .o object: nasm -O999999999 -w+orphan-labels -f elf -o ftruncate64_linux.o ftruncate64_linux.nasm
;
; Code size: 0x7 bytes.
;
; Uses: %ifdef CONFIG_PIC
;

bits 32
cpu 386

global mini_ftruncate64
%ifdef CONFIG_SECTIONS_DEFINED
%elifidn __OUTPUT_FORMAT__, bin
section .text align=1
section .rodata align=1
section .data align=1
section .bss align=1
mini_syscall3_AL equ +0x12345679
%else
extern mini_syscall3_AL
section .text align=1
section .rodata align=1
section .data align=1
section .bss align=1
%endif

section .text
mini_ftruncate64:  ; int mini_ftruncate64(struct timeval *tv, struct timezone *tz);
		mov al, 194  ; __NR_ftruncate64.  ; Needs Linux >=2.4.
		jmp strict near mini_syscall3_AL

%ifdef CONFIG_PIC  ; Already position-independent code.
%endif

; __END__
