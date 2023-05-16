;
; written by pts@fazekas.hu at Tue May 16 18:16:29 CEST 2023
; Compile to i386 ELF .o object: nasm -O999999999 -w+orphan-labels -f elf -o strlen.o strlen.nasm
;
; Uses: %ifdef CONFIG_PIC
;

bits 32
cpu 386

global mini_strlen
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
mini_strlen:  ; size_t mini_strlen(const char *s);
		mov eax, [esp+4]  ; EAX := Address of string data.
		; TODO(pts): Add a faster (but longer?) implementation with rep scasb.
.next:		cmp byte [eax], 0
		je strict short .done
		inc eax
		jmp strict short .next
.done:		sub eax, [esp+4]
		ret

%ifdef CONFIG_PIC  ; Already position-independent code.
%endif

; __END__
