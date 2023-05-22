;
; written by pts@fazekas.hu at Sun May 21 21:00:32 CEST 2023
; Compile to i386 ELF .o object: nasm -O999999999 -w+orphan-labels -f elf -o isatty_linux.o isatty_linux.nasm
;
; Code size: 0x1d bytes.
;
; Uses: %ifdef CONFIG_PIC
;

bits 32
cpu 386

global mini_isatty
%ifdef CONFIG_SECTIONS_DEFINED
%elifidn __OUTPUT_FORMAT__, bin
section .text align=1
section .rodata align=4
section .data align=4
section .bss align=4
mini_ioctl equ +0x12345679
%else
extern mini_ioctl
section .text align=1
section .rodata align=1
section .data align=1
section .bss align=1
%endif

section .text
mini_isatty:  ; int mini_isatty(int fd);
		sub esp, strict byte 0x24
		push esp  ; 3rd argument of ioctl TCGETS.
		push strict dword 0x5401  ; TCGETS.
		push dword [esp+0x24+4+2*4]  ; fd argument of ioctl.
		call mini_ioctl
		add esp, strict byte 0x24+3*4  ; Clean up everything pushed.
		; Now convert result EAX: 0 to 1, everything else to 0.
		cmp eax, byte 1
		sbb eax, eax
		neg eax
		ret

%ifdef CONFIG_PIC  ; Already position-independent code.
%endif

; __END__
