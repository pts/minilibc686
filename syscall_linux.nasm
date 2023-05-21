;
; written by pts@fazekas.hu at Sun May 21 15:41:41 CEST 2023
; Compile to i386 ELF .o object: nasm -O999999999 -w+orphan-labels -f elf -o syscall_linux.o syscall_linux.nasm
;
; Code size: 0x27 bytes.

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
%else
extern main
section .text align=1
section .rodata align=1
section .data align=1
section .bss align=1
%endif

section .text
mini_syscall:  ; long mini_syscall(long nr, ...);  /* Supports up to 6 arguments after nr, that's the maximum on Linux. */
; Most users should call mini_syscall0(nr) ... mini_syscall3(nr, ...); instead, because that's included in start_stdio_file_linux.nasm.
		pushad  ; This design is actually 2 bytes shorter than `push ebx ++ push esi ++ push edi ++ push ebp', and then pop.
		lea esi, [esp+0x24]
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
		cmp eax, -0x100  ; Treat very large (e.g. <-0x100; with Linux 5.4.0, 0x85 seems to be the smallest) non-negative return values as success rather than errno. This is needed by time(2) when it returns a negative timestamp. uClibc has -0x1000 here.
		jna .final_result
		or eax, byte -1  ; EAX := -1 (error).
.final_result:	mov [esp+0x1c], eax  ; popad will restore it back to EAX.
		popad
		ret

%ifdef CONFIG_PIC  ; Already position-independent code.
%endif

; __END__
