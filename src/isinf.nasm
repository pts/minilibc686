;
; written by pts@fazkeas.hu at Fri May 26 23:09:31 CEST 2023
; Compile to i386 ELF .o object: nasm -O999999999 -w+orphan-labels -f elf -o isinf.o isinf.nasm
;
; This implementation is not needed, because isnan.nasm also works on all
; targets supported by minilibc686. So this implementation is only for
; educational purposes.
;
; Code size: 0x19 bytes.
;
; This implementation is shorter than than doing it with the FPU.
;
; Uses: %ifdef CONFIG_PIC
;

bits 32
cpu 386

global mini_isinf
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

mini_isinf:  ; int mini_isinf(double x);
; int mini_isinf_u64(unsigned long long x) { return x == 0x7ff0000000000000ull || x == 0xfff0000000000000ull; }
		mov eax, [esp+0x8]
		and eax, 0x7fffffff
		xor eax, 0x7ff00000
		or eax, [esp+0x4]
		setz al
		and eax, byte 1
		ret

%ifdef CONFIG_PIC  ; Already position-independent code.
%endif

; __END__
