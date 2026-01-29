;
; written by pts@fazekas.hu at Sun May 21 15:41:41 CEST 2023
; Compile to i386 ELF .o object: nasm -O999999999 -w+orphan-labels -f elf -o strcat.o strcat.nasm
;
; Uses: %ifdef CONFIG_PIC
;

bits 32
cpu 386

global mini_strcat
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
mini_strcat:  ; char *mini_strcat(char *dest, const char *src);
		push edi
		push esi
		mov edi, [esp+0xc]  ; dest.
		mov esi, [esp+0x10]  ; src.
		push edi
		dec edi
.skipagain:	inc edi
		cmp byte [edi], 1
		jnc .skipagain
%if 0  ; TODO(pts): Do this with smart linking. Does it even work?
		jmp short strcpy_again
%else
.again:		lodsb
		stosb
		cmp al, 0
		jne .again
		pop eax			; Will return dest.
		pop esi
		pop edi
		ret
%endif

%ifdef CONFIG_PIC  ; Already position-independent code.
%endif

; __END__
