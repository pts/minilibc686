;
; written by pts@fazekas.hu at Mon Jun  5 23:50:24 CEST 2023
; Compile to i386 ELF .o object: nasm -O999999999 -w+orphan-labels -f elf -o sys_mmap2_linux.o sys_mmap2_linux.nasm

; Uses: %ifdef CONFIG_PIC
;

bits 32
cpu 386

global mini_sys_mmap2
%ifdef CONFIG_SECTIONS_DEFINED
%elifidn __OUTPUT_FORMAT__, bin
section .text align=1
section .rodata align=1
section .data align=1
section .bss align=1
mini_syscall6_AL equ +0x12345678
%else
extern mini_syscall6_AL
section .text align=1
section .rodata align=1
section .data align=1
section .bss align=1
%endif

section .text
mini_sys_mmap2:  ; void *mini_sys_mmap2(void *addr, size_t length, int prot, int flags, int fd, off_t offset);
		mov al, 192  ; __NR_mmap2.
		jmp strict near mini_syscall6_AL

%ifdef CONFIG_PIC  ; Already position-independent code.
%endif

; __END__
