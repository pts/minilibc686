;
; written by pts@fazkeas.hu at Fri May 26 23:09:31 CEST 2023
; Compile to i386 ELF .o object: nasm -O999999999 -w+orphan-labels -f elf -o isnan_nofpu.o isnan_nofpu.nasm
;
; This implementation is not needed, because isnan.nasm also works on all
; targets supported by minilibc686. So this implementation is only for
; educational purposes.
;
; Code size: 0x22 bytes.
;
; Uses: %ifdef CONFIG_PIC
;

bits 32
cpu 386

global mini_isnan_nofpu
%ifidn __OUTPUT_FORMAT__, bin
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

mini_isnan_nofpu:  ; int mini_isnan_nofpu(double x);
		mov eax, [esp+8]
		xor edx, edx
		not eax
		test eax, 0x7ff00000
		jnz .done  ; Not special (inf or nan).
		inc edx
		not eax
		test eax, 0xfffff
		jnz .done  ; Not +-inf.
		cmp dword [esp+4], edx
		jnc .done  ; dword [esp+4] is nonzero => not +-inf.
.is_inf:	dec edx
.done:		xchg eax, edx  ; EAX := EDX (return value); EDX := junk.
		ret

%ifdef CONFIG_PIC  ; Already position-independent code.
%endif

; __END__
