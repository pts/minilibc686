;
; written by pts@fazekas.hu at Tue Apr  9 21:17:17 CEST 2024
; Compile to i386 ELF .o object: nasm -O999999999 -w+orphan-labels -f elf -o strncpy.o strncpy.nasm
;
; Code size: 0x20 bytes.
;
; Uses: %ifdef CONFIG_PIC
;

bits 32
cpu 386

global mini_strncpy
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
mini_strncpy:  ; char *mini_strncpy(char *dest, const char *src, size_t n);
		mov ecx, [esp+0xc]  ; Argument n.
		push edi  ; Save.
		mov edi, [esp+8]  ; Argument dest.
		mov edx, [esp+0xc]  ; Argument src.
		push edi
.1:		test ecx, ecx
		jz short .2
		dec ecx
		mov al, [edx]
		stosb
		inc edx
		test al, al
		jnz short .1
		rep stosb  ; Fill the rest of dest with \0. This is different from mini_strcpy(...).
.2:		pop eax  ; Result: pointer to dest.
		pop edi  ; Restore.
		ret

%ifdef CONFIG_PIC  ; Already position-independent code.
%endif

; __END__
