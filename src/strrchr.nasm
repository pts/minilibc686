;
; written by pts@fazekas.hu at Fri Jun 23 16:32:00 CEST 2023
; Compile to i386 ELF .o object: nasm -O999999999 -w+orphan-labels -f elf -o strrchr.o strrchr.nasm
;
; Code size: 0x1a bytes. The i686 version isn't shorter either, but it's a bit faster.

; Uses: %ifdef CONFIG_PIC
;

bits 32
%ifdef CONFIG_I386
cpu 386
%else
cpu 686
%endif

global mini_strrchr
global mini_rindex
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
mini_strrchr:  ; char *mini_strrchr(const char *s, int c);
mini_rindex:  ; char *mini_rindex(const char *s, int c);
		push esi
		mov ah, [esp+0xc]
		mov esi, [esp+8]
		xor edx, edx
%ifdef CONFIG_I386
.next:		lodsb
		cmp al, ah
		jne .different
		mov edx, esi
		dec edx
.different:	test al, al
		jnz .next
%else
		inc edx
.next:		lodsb
		cmp al, ah
		cmove edx, esi
		test al, al
		jnz .next
		dec edx
%endif  ; else CONFIG_I386
		xchg eax, edx  ; EAX := pointer to last match; EDX := junk.
		pop esi
		ret

%ifdef CONFIG_PIC  ; Already position-independent code.
%endif

; __END__
