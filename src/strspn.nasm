;
; Compile to i386 ELF .o object: nasm -O999999999 -w+orphan-labels -f elf -o strcmp.o strcmp.nasm
;
; Code size: 0x21 bytes.
;
; Uses: %ifdef CONFIG_PIC
;

bits 32
cpu 386

global mini_strspn
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
mini_strspn:  ; size_t mini_strspn(const char *s, const char *accept);
		xor eax, eax
.2:		mov edx, [esp+4]
		mov cl, [edx+eax]
		test cl, cl
		jz .1
		mov edx, [esp+8]
		dec edx
.6:		inc edx
		mov ch, [edx]
		test ch, ch
		jz .1
		cmp ch, cl
		jne .6
		inc eax
		jmp .2
.1:		ret

%ifdef CONFIG_PIC  ; Already position-independent code.
%endif

; __END__
