;
; written by pts@fazekas.hu at Sun Jul  2 16:26:22 CEST 2023
; Compile to i386 ELF .o object: nasm -O999999999 -w+orphan-labels -f elf -o wait_linux.o wait_linux.nasm
;
; Code size: 0x13 bytes.
;
; Uses: %ifdef CONFIG_PIC
;

bits 32
cpu 386

global mini_wait
%ifdef CONFIG_SECTIONS_DEFINED
%elifidn __OUTPUT_FORMAT__, bin
section .text align=1
section .rodata align=1
section .data align=1
section .bss align=1
mini_syscall3_AL equ $+0x12345678
%else
extern mini_syscall3_AL
section .text align=1
section .rodata align=1
section .data align=1
section .bss align=1
%endif

section .text
mini_wait:  ; pid_t mini_wait(int *status);
; pid_t wait(int *status) { return waitpid(-1, status, 0); } 
		mov al, 7  ; __NR_waitpid.
		push byte 0
		push dword [esp+2*4]  ; Argument status.
		push byte -1
		call mini_syscall3_AL
		add esp, byte 3*4  ; Clean up arguments of mini_syscall3_RP1 from the stack.
		ret

%ifdef CONFIG_PIC  ; Already position-independent code.
%endif

; __END__
