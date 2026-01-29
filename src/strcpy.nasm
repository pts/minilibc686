;
; written by pts@fazekas.hu at Sun May 21 15:41:41 CEST 2023
; Compile to i386 ELF .o object: nasm -O999999999 -w+orphan-labels -f elf -o strcpy.o strcpy.nasm
;
; Uses: %ifdef CONFIG_PIC
;

bits 32
cpu 386

global mini_strcpy
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
mini_strcpy:  ; char *mini_strcpy(char *dest, const char *src);
		push edi
		push esi
		mov edi, [esp+0xc]
		mov esi, [esp+0x10]
		push edi
.next3:		lodsb
		stosb
		test al, al
		jnz strict short .next3
		pop eax  ; Result: pointer to dest.
		pop esi
		pop edi
		ret

%ifdef CONFIG_PIC  ; Already position-independent code.
%endif

; __END__
