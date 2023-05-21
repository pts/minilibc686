;
; written by pts@fazekas.hu at Sun May 21 21:00:32 CEST 2023
; Compile to i386 ELF .o object: nasm -O999999999 -w+orphan-labels -f elf -o lseek64_set_linux.o lseek64_set_linux.nasm
;
; Uses: %ifdef CONFIG_PIC
;

bits 32
cpu 386

global mini_lseek64_set_RP3
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
mini_lseek64_set_RP3:  ; int mini_lseek64_set_RP3(int fd, off64_t offset) __attribute__((__regparm__(3)));
; Returns 0 on success, anything else (and sets errno) on error. The
; implementation quite shorter than lseek64(...).
;
; Arguments: EAX == fd, EDX == low dword of offset, ECX == high dword of offset.
		push ebx
		push esi
		push edi
		push ebx  ; High dword of result (will be ignored).
		push ebx  ; Low dword of result (will be ignored).
		xchg ebx, eax  ; EBX := fd. EAX := scratch.
		mov eax, 140  ; __NR__lseek.
		;mov ecx, arg_ecx  ; offset >> 32.
		;mov edx, arg_edx  ; offset.
		mov esi, esp  ; &result.
		xor edi, edi  ; SEEK_SET.
		int 0x80  ; Linux i386 syscall.
		pop ebx  ; Low dword of result.
		pop ebx  ; High dword of result.
		pop edi
		pop esi
		pop ebx
		cmp eax, -0x100  ; Treat very large (e.g. <-0x100; with Linux 5.4.0, 0x85 seems to be the smallest) non-negative return values as success rather than errno. This is needed by time(2) when it returns a negative timestamp. uClibc has -0x1000 here.
		jna .final_result
		or edx, byte -1  ; EDX := -1 (error).
		or eax, byte -1  ; EAX := -1 (error).
.final_result:	ret

%ifdef CONFIG_PIC  ; Already position-independent code.
%endif

; __END__
