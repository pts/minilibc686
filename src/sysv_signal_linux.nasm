;
; written by pts@fazekas.hu at Mon Jul  3 20:30:39 CEST 2023
; Compile to i386 ELF .o object: nasm -O999999999 -w+orphan-labels -f elf -o sysv_signal_linux.o sysv_signal_linux.nasm
;
; Code size: 7 bytes.

; Uses: %ifdef CONFIG_PIC
;

bits 32
cpu 386

global mini_sysv_signal
global mini_sys_signal
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
mini_sysv_signal:  ; sighandler_t sysv_signal(int signum, sighandler_t handler);
mini_sys_signal:  ; sighandler_t sys_signal(int signum, sighandler_t handler);
		mov al, 48  ; __NR_signal.
		jmp strict near mini_syscall3_AL

%ifdef CONFIG_PIC  ; Already position-independent code.
%endif

; __END__
