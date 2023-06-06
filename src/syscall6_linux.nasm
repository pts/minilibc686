;
; written by pts@fazekas.hu at Mon Jun  5 23:50:24 CEST 2023
; Compile to i386 ELF .o object: nasm -O999999999 -w+orphan-labels -f elf -o syscall6_linux.o syscall6_linux.nasm
;
; Code size: 0x24 bytes.
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
mini_syscall6_AL:  ; void *mini_syscall6(long number, int arg1, int arg2, int arg3, int arg4, int arg5, int arg6);
; TODO(pts): Get rid of mini_syscall6_AL with smart linking, if unused.
		movzx eax, al  ; Argument number.
		; Fall through to mini_syscall6_RP1.
mini_syscall6_RP1:  ; void *mini_syscall6(long number, int arg1, int arg2, int arg3, int arg4, int arg5, int arg6);
		push ebx
		push esi
		push edi
		push ebp
		lea esi, [esp+5*4]
		;lodsd  ; EAX already contains the syscall number.
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
		int 0x80  ; Linux i386 syscall.
		pop ebp
		pop edi
		pop esi
		;pop ebx
		jmp strict near mini___M_jmp_pop_ebx_syscall_return

%ifdef CONFIG_PIC  ; Already position-independent code.
%endif

; __END__
