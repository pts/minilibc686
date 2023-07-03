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

global mini___M_jmp_mov_syscall
global mini___M_jmp_syscall_pop_ebp_edi_esi_ebx_return
global mini___M_jmp_pop_ebp_edi_esi_ebx_syscall_return
%ifdef CONFIG_SECTIONS_DEFINED
%elifidn __OUTPUT_FORMAT__, bin
section .text align=1
section .rodata align=1
section .data align=1
section .bss align=1
mini___M_jmp_pop_ebx_syscall_return equ +0x12345678
%else
extern mini___M_jmp_pop_ebx_syscall_return
section .text align=1
section .rodata align=1
section .data align=1
section .bss align=1
%endif

section .text
mini___M_jmp_mov_syscall:  ; Input: EAX == syscall number; ESI == points to arguments on stack.
		; Load 6 syscall arguments from the stack (starting at ESI) to EBX, ECX, EDX, ESI, EDI, EBP.
		xchg eax, edx  ; EDX := EAX; EAX := junk.
		lodsd
		xchg eax, ebx  ; EBX := EAX; EAX := junk.
		lodsd
		xchg eax, ecx  ; ECX := EAX; EAX := junk.
		lodsd
		xchg eax, edx  ; Useeful swap.
		mov edi, [esi+1*4]
		mov ebp, [esi+2*4]
		mov esi, [esi]  ; This is the last one, it ruins the index in ESI.
mini___M_jmp_syscall_pop_ebp_edi_esi_ebx_return:
		int 0x80  ; Linux i386 syscall.
mini___M_jmp_pop_ebp_edi_esi_ebx_syscall_return:
		pop ebp
		pop edi
		pop esi
		jmp strict near mini___M_jmp_pop_ebx_syscall_return

%ifdef CONFIG_PIC  ; Already position-independent code.
%endif

; __END__
