;
; written by pts@fazekas.hu at Tue May 16 13:38:22 CEST 2023
; Compile to i386 ELF .o object: nasm -O999999999 -w+orphan-labels -f elf -o exit_linux.o exit_linux.nasm
;
; Code size: 7 bytes.
;
; Uses: %ifdef CONFIG_PIC
;

bits 32
cpu 386

global mini__exit
%ifdef CONFIG_SECTIONS_DEFINED
%elifidn __OUTPUT_FORMAT__, bin
section .text align=1
section .rodata align=4
section .data align=4
section .bss align=4
%else
section .text align=1
section .rodata align=1
section .data align=1
section .bss align=1
%endif

section .text
mini__exit:  ; void mini__exit(int exit_code) __attribute__((__noreturn__));
		pop ebx  ; Return address.
		pop ebx  ; Argument exit_code.
		xor eax, eax
		inc eax  ; EAX := 1 == __NR_exit.
		int 0x80  ; Linux i386 syscall, exit(2) doesn't return.
		; Not reached, the syscall above doesn't return.

%ifdef CONFIG_PIC  ; Already position-independent code.
%endif

; __END__
