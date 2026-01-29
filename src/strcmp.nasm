;
; based on the assembly code in uClibc-0.9.30.1/libc/string/i386/strcmp.c
; Compile to i386 ELF .o object: nasm -O999999999 -w+orphan-labels -f elf -o strcmp.o strcmp.nasm
;
; Code size: 0x1d bytes.
;
; Uses: %ifdef CONFIG_PIC
;

bits 32
cpu 386

global mini_strcmp
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
mini_strcmp:  ; int mini_strcmp(const char *s1, const char *s2);
		push esi
		push edi
		mov esi, [esp+0xc]  ; s1.
		mov edi, [esp+0x10]  ; s2.
.5:		lodsb
		scasb
		jne .6
		cmp al, 0
		jne .5
		xor eax, eax
		jmp short .7
.6:		sbb eax, eax
		or al, 1
.7:		pop edi
		pop esi
		ret

%ifdef CONFIG_PIC  ; Already position-independent code.
%endif

; __END__
