;
; written by pts@fazekas.hu at Sun May 21 15:41:41 CEST 2023
; Compile to i386 ELF .o object: nasm -O999999999 -w+orphan-labels -f elf -o syscall_linux.o syscall_linux.nasm
;
; Code size: 0x25 bytes.

; Uses: %ifdef CONFIG_PIC
;

bits 32
cpu 386

global mini_syscall
%ifdef CONFIG_SECTIONS_DEFINED
%elifidn __OUTPUT_FORMAT__, bin
section .text align=1
section .rodata align=4
section .data align=4
section .bss align=4
mini___M_jmp_pop_ebx_syscall_return equ +0x12345678
%else
extern mini___M_jmp_pop_ebx_syscall_return
section .text align=1
section .rodata align=1
section .data align=1
section .bss align=1
%endif

section .text
mini_syscall:  ; long mini_syscall(long nr, ...);  /* Supports up to 6 arguments after nr, that's the maximum on Linux. */
; Most users should call mini_syscall0(nr) ... mini_syscall3(nr, ...); instead, because that's included in start_stdio_file_linux.nasm.
		mov ecx, esp
		push ebx
		push esi
		push edi
		push ebp
		mov eax, [ecx+1*4]  ; Argument nr.
		mov ebx, [ecx+2*4]  ; Argument arg1.
		mov edx, [ecx+4*4]  ; Argument arg3.
		mov esi, [ecx+5*4]  ; Argument arg4.
		mov edi, [ecx+6*4]  ; Argument arg5.
		mov ebp, [ecx+7*4]  ; Argument arg6.
		mov ecx, [ecx+3*4]  ; Argument arg2.
		int 0x80  ; Linux i386 syscall.
		pop ebp
		pop edi
		pop esi
		;pop ebx
		jmp strict near mini___M_jmp_pop_ebx_syscall_return

%ifdef CONFIG_PIC  ; Already position-independent code.
%endif

; __END__
