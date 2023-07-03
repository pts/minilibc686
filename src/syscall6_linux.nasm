;
; written by pts@fazekas.hu at Mon Jun  5 23:50:24 CEST 2023
; Compile to i386 ELF .o object: nasm -O999999999 -w+orphan-labels -f elf -o syscall6_linux.o syscall6_linux.nasm
;
; With smart linking, the code in src/smart.nasm is used instead of this
; file.
;
; Uses: %ifdef CONFIG_PIC
;

bits 32
cpu 386

global mini_syscall6_AL
global mini_syscall6_RP1
%ifdef CONFIG_SECTIONS_DEFINED
%elifidn __OUTPUT_FORMAT__, bin
section .text align=1
section .rodata align=1
section .data align=1
section .bss align=1
mini___M_jmp_mov_syscall equ +0x12345678
%else
extern mini___M_jmp_mov_syscall
section .text align=1
section .rodata align=1
section .data align=1
section .bss align=1
%endif

section .text
mini_syscall6_AL:  ; void *mini_syscall6(long number, int arg1, int arg2, int arg3, int arg4, int arg5, int arg6);
		movzx eax, al  ; Argument number.
		; Fall through to mini_syscall6_RP1.
mini_syscall6_RP1:  ; void *mini_syscall6(long number, int arg1, int arg2, int arg3, int arg4, int arg5, int arg6);
		push ebx
		push esi
		push edi
		push ebp
		lea esi, [esp+5*4]
		jmp mini___M_jmp_mov_syscall

%ifdef CONFIG_PIC  ; Already position-independent code.
%endif

; __END__
