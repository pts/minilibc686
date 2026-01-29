;
; written by pts@fazekas.hu at Mon May 22 14:57:48 CEST 2023
; Compile to i386 ELF .o object: nasm -O999999999 -w+orphan-labels -f elf -o isatty_linux_syscall.o isatty_linux_syscall.nasm
;
; Code size: 0x21 bytes.
;
; Limitation: it doesn't set errno.
;
; Uses: %ifdef CONFIG_PIC
;

bits 32
cpu 386

global mini_isatty
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
mini_isatty:  ; int mini_isatty(int fd);
		push ebx
		sub esp, strict byte 0x24
		xor eax, eax
		mov al,  54  ; __NR_ioctl.
		mov ebx, [esp+0x24+4+4]  ; fd argument of ioctl.
		mov ecx, 0x5401  ; TCGETS.
		mov edx, esp  ; 3rd argument of ioctl TCGETS.
		int 0x80  ; Linux i386 syscall.
		add esp, strict byte 0x24  ; Clean up everything pushed.
		pop ebx
		; Now convert result EAX: 0 to 1, everything else to 0.
		cmp eax, byte 1
		sbb eax, eax
		neg eax
		ret

%ifdef CONFIG_PIC  ; Already position-independent code.
%endif

; __END__
