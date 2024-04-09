V;
; written by pts@fazekas.hu at Tue Apr  9 21:17:17 CEST 2024
; Compile to i386 ELF .o object: nasm -O999999999 -w+orphan-labels -f elf -o strncpy.o strncpy.nasm
;
; Code size: 0x2a bytes.
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
		push ebx
		mov eax, [esp+8]
		mov ecx, [esp+0x10]
		test ecx, ecx
		mov edx, [esp+0xc]
		push eax
		jz short .4
.1:		mov bl, [edx]
		mov [eax], bl  ; !! TODO(pts): Make it stosb.
		inc edx
		inc eax
		test bl, bl
		jnz short .3
.2:		dec ecx
		je short .4
		mov byte [eax], bl  ; 0.
		inc eax
		jmp short .2
.3:		dec ecx
		jne .1
.4:		pop eax
		pop ebx
		ret

; __END__

%ifdef CONFIG_PIC  ; Already position-independent code.
%endif

; __END__
