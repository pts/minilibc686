;
; written by pts@fazekas.hu at Mon Jul  3 21:07:51 CEST 2023
; Compile to i386 ELF .o object: nasm -O999999999 -w+orphan-labels -f elf -o sigfillset_linux.o sigfillset_linux.nasm
;
; Code size: 0xd bytes.
;
; Uses: %ifdef CONFIG_PIC
;

bits 32
cpu 386

global mini_sigfillset
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
mini_sigfillset:  ; int mini_sigfillset(sigset_t *set);
		push edi
		mov edi, [esp+2*4]  ; Argument `set'.
		or eax, byte -1
		stosd  ; Set lowest 32 bits of the bitset to 0.
		stosd  ; Set highest 32 bits of the bitset to 0.
		pop edi
		inc eax  ; EAX := 0.
		ret  ; Returns 0 in EAX.

%ifdef CONFIG_PIC  ; Already position-independent code.
%endif

; __END__
