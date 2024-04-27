;
; Compile to i386 ELF .o object: nasm -O999999999 -w+orphan-labels -f elf -o strcmp.o strcmp.nasm
;
; Code size: 0x1f bytes.
;
; Uses: %ifdef CONFIG_PIC
;

bits 32
cpu 386

global mini_strcspn
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
mini_strcspn:  ; size_t mini_strcspn(const char *s, const char *reject);
		or eax, byte -1
.2:		inc eax
		mov edx, [esp+4]
		mov cl, [edx+eax]
		test cl, cl
		je .1
		mov edx, [esp+8]
.5:		mov ch, [edx]
		test ch, ch
		je .2
		inc edx
		cmp ch, cl
		jne .5
.1:		ret

%ifdef CONFIG_PIC  ; Already position-independent code.
%endif

; __END__
