;
; written by pts@fazekas.hu at Thu Jun  1 04:25:50 CEST 2023
; Compile to i386 ELF .o object: nasm -O999999999 -w+orphan-labels -f elf -o memswap_rp3.o memswap_rp3.nasm
;
; Code size: 0xe bytes.
;
; This is the fast implementation (using `repne scasb'), but the slow
; implementation isn't shorter either.

; Uses: %ifdef CONFIG_PIC
;

bits 32
cpu 386

global mini_memswap_RP3
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
mini_memswap_RP3:  ; __attribute__((__regparm__(3))) void static_mini_memswap_RP3(void *a, void *b, size_t size);
		push edi
		;mov eax, ... ; Argument a.
		;mov edx, ...  ; Argument b.
		;mov ecx, ...  ; Argument size.
		xchg eax, edi  ; EDI := argument a; EAX := junk.
		jecxz .done
.again:		mov al, [edi]
		xchg al, [edx]
		stosb
		inc edx
		loop .again
.done:		pop edi
		ret

%ifdef CONFIG_PIC  ; Already position-independent code.
%endif

; __END__
