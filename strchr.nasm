;
; written by pts@fazekas.hu at Tue May 16 18:44:34 CEST 2023
; Compile to i386 ELF .o object: nasm -O999999999 -w+orphan-labels -f elf -o strchr.o strchr.nasm
;
; Code size: !! 0x11 bytes.

; Uses: %ifdef CONFIG_PIC
;

bits 32
cpu 386

global mini_strchr
global mini_index
%ifdef CONFIG_SECTIONS_DEFINED
%elifidn __OUTPUT_FORMAT__, bin
section .text align=1
section .rodata align=4
section .data align=4
section .bss align=4
%else
extern main
section .text align=1
section .rodata align=1
section .data align=1
section .bss align=1
%endif

section .text
mini_strchr:  ; char *mini_strchr(const char *s, int c);
mini_index:  ; char *mini_index(const char *s, int c);
		push esi
		mov al, [esp+0xc]
		mov esi, [esp+8]
		mov ah, al
.next:		lodsb
		cmp al, ah
		je .found
		test al, al
		jnz .next
		xor esi, esi  ; Not found, we will return NULL.
		inc esi
.found:		xchg eax, esi  ; EAX := ESI; ESI := junk.
		dec eax
		pop esi
		ret

%ifdef CONFIG_PIC  ; Already position-independent code.
%endif

; __END__
