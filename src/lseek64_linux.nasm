;
; written by pts@fazekas.hu at Sun May 21 21:00:32 CEST 2023
; Compile to i386 ELF .o object: nasm -O999999999 -w+orphan-labels -f elf -o lseek64_linux.o lseek64_linux.nasm
;
; Uses: %ifdef CONFIG_PIC
;

bits 32
cpu 386

global mini_lseek64
%ifdef CONFIG_SECTIONS_DEFINED
%elifidn __OUTPUT_FORMAT__, bin
section .text align=1
section .rodata align=1
section .data align=1
section .bss align=1
%else
section .text align=1
section .rodata align=1
section .data align=1
section .bss align=1
%endif

section .text
mini_lseek64:  ; off64_t mini_lseek64(int fd, off64_t offset, int whence);
		push ebx
		push esi
		push edi
		push ebx  ; High dword of result.
		push ebx  ; Low dword of result.
		xor eax, eax
		mov al, 140  ; SYS__llseek.
		mov ebx, [esp+0x14+4]  ; Argument fd.
		mov edx, [esp+0x14+8]  ; Argument offset (low dword).
		mov ecx, [esp+0x14+0xc]  ; Argument offset (high dword).
		mov esi, esp  ; &result.
		mov edi, [esi+0x14+0x10]  ; Argument whence.
		int 0x80  ; Linux i386 syscall.
		test eax, eax
		lodsd  ; High dword of result.
		mov edx, [esi]  ; Low dword of result.
		jns .final_result  ; It's OK to check the sign bit, SYS__llseek won't return negative values as success.
		; !! TODO(pts): Update errno if the program uses errno.
		or eax, byte -1  ; EAX := -1 (error).
		cdq  ; EDX := -1. Sign-extend EAX (32-bit offset) to EDX:EAX (64-bit offset).
.final_result:	pop ebx  ; Discard low word of SYS__llseek result.
		pop ebx  ; Discard high word of SYS__llseek result.
		pop edi
		pop esi
		pop ebx
		ret

%ifdef CONFIG_PIC  ; Already position-independent code.
%endif

; __END__
