;
; written by pts@fazekas.hu at Tue Jul  4 02:32:35 CEST 2023
; Compile to i386 ELF .o object: nasm -O999999999 -w+orphan-labels -f elf -o stdio_medium_freopen.o stdio_medium_freopen.nasm
;
; Uses: %ifdef CONFIG_PIC
;

bits 32
cpu 386

global mini_freopen
%ifdef CONFIG_SECTIONS_DEFINED
%elifidn __OUTPUT_FORMAT__, bin
section .text align=1
section .rodata align=1
section .data align=1
section .bss align=1
mini___M_jmp_freopen_low equ +0x12345678
mini___M_jmp_freopen_low.error equ +0x12345679
mini_fclose equ +0x1234567a
%else
extern mini___M_jmp_freopen_low
extern mini___M_jmp_freopen_low.error
extern mini_fclose
section .text align=1
section .rodata align=1
section .data align=1
section .bss align=1
%endif

section .text
mini_freopen:  ; FILE *mini_freopen(const char *pathname, const char *mode, FILE *filep);
		push edi
		push esi
		push ebx
		mov esi, [esp+6*4]  ; Argument filep.
		cmp byte [esi+0x14], 0x0  ; FD_CLOSED.
		je .closed
		push esi
		call mini_fclose
		pop edx  ; Clean up argument of mini_fclose from the stack.
		test eax, eax
		jnz strict near mini___M_jmp_freopen_low.error  ; TODO(pts): With smart linking, make this a short jump.
.closed:	jmp strict near mini___M_jmp_freopen_low  ; TODO(pts): With smart linking, make this a short jump.

%ifdef CONFIG_PIC
%error Not PIC because it uses global variables.
times 1/0 nop
%endif

; __END__
