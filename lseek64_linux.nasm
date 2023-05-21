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
mini_lseek64:  ; off64_t mini_lseek64(int fd, off64_t offset, int whence);
		push ebx
		push esi
		push edi
		push ebx  ; High dword of result.
		push ebx  ; Low dword of result.
		xor eax, eax
		mov al, 140  ; __NR__lseek.
		mov ebx, [esp+0x14+4]  ; Argument fd.
		mov edx, [esp+0x14+8]  ; Argument offset (low dword).
		mov ecx, [esp+0x14+0xc]  ; Argument offset (high dword).
		mov esi, esp  ; &result.
		mov edi, [esp+0x14+0x10]  ; Argument whence.
		int 0x80  ; Linux i386 syscall.
		cmp eax, -0x100  ; Treat very large (e.g. <-0x100; with Linux 5.4.0, 0x85 seems to be the smallest) non-negative return values as success rather than errno. This is needed by time(2) when it returns a negative timestamp. uClibc has -0x1000 here.
		mov eax, [esi]
		mov edx, [esi+4]
		jna .final_result
		or edx, byte -1  ; EDX := -1 (error).
		or eax, byte -1  ; EAX := -1 (error).
.final_result:	pop ebx  ; Low word of result.
		pop ebx  ; High word of result.
		pop edi
		pop esi
		pop ebx
		ret

%ifdef CONFIG_PIC  ; Already position-independent code.
%endif

; __END__
