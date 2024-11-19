;
; written by pts@fazekas.hu at Tue Nov 19 18:07:57 CET 2024
; Compile to i386 ELF .o object: nasm -O999999999 -w+orphan-labels -f elf -o strdup.o strdup.nasm
;
; Code size: 0x25 bytes.
;
; Uses: %ifdef CONFIG_PIC
;

bits 32
cpu 386

global mini_strdup
%ifdef CONFIG_SECTIONS_DEFINED
%elifidn __OUTPUT_FORMAT__, bin
section .text align=1
section .rodata align=4
section .data align=4
section .bss align=4
mini_realloc equ +0x12345678
%else
extern mini_realloc
section .text align=1
section .rodata align=1
section .data align=1
section .bss align=1
%endif

section .text
mini_strdup:  ; char *mini_strdup(const char *s);
		push esi  ; Save.
		push edi  ; Save.
		mov esi, [esp+3*4]  ; Argument s.
		xor ecx, ecx
.0:		inc ecx
		cmp byte [esi+ecx-1], 0
		jne short .0
		push ecx  ; Argument size of realloc.
		push byte 0  ; Argument ptr of realloc.
		call mini_realloc
		pop ecx  ; Clean up argument ptr of mini_realloc above.
		pop ecx  ; Clean up and reuse argument size of mini_realloc above. (mini_realloc doesn't modify this on the stack.) TODO(pts): Is this legal in the calling convention?
		test eax, eax
		jz .2
.1:		mov edi, eax
		rep movsb
.2:		pop edi  ; Restore.
		pop esi  ; Restore.
		ret

%ifdef CONFIG_PIC  ; Already position-independent code.
%endif

; __END__
