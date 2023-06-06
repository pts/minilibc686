;
; written by pts@fazekas.hu at Sun May 21 15:41:41 CEST 2023
; Compile to i386 ELF .o object: nasm -O999999999 -w+orphan-labels -f elf -o syscall_linux.o syscall_linux.nasm
;
; Code size: 0x22 bytes.

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
		push ebx
		push esi
		push edi
		push ebp
		lea esi, [esp+5*4]
		lodsd
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
