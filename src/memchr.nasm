;
; written by pts@fazekas.hu at Thu Jun  1 16:13:12 CEST 2023
; Compile to i386 ELF .o object: nasm -O999999999 -w+orphan-labels -f elf -o memchr.o memchr.nasm
;
; Code size: !! 0x11 bytes.

; Uses: %ifdef CONFIG_PIC
;

bits 32
cpu 386

global mini_memchr
global mini_index
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
mini_memchr:  ; char *mini_memchr(const char *s, int c, size_t n);
		push edi
		mov al, [esp+0xc]  ; Argument c.
		mov edi, [esp+8]  ; Argument s.
		mov ecx, [esp+0x10]  ; Argument n.
		jecxz .missing
.again:		repne scasb
		je .found
.missing:	xor edi, edi
		inc edi  ; EDI := 1 (for the NULL return value).
.found:		xchg eax, edi  ; EAX := EDI; EDI := junk.
		dec eax
.done:		pop edi
		ret

%ifdef CONFIG_PIC  ; Already position-independent code.
%endif

; __END__
