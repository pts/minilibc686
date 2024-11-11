;
; written by pts@fazekas.hu at Mon Nov 11 15:19:31 CET 2024
; Compile to i386 ELF .o object: nasm -O999999999 -w+orphan-labels -f elf -o prng_mix3_rp3.o prng_mix3_rp3.nasm
;
; Code size: 0x1b bytes.
;
; This is the fast implementation (using `repne scasb'), but the slow
; implementation isn't shorter either.

; Uses: %ifdef CONFIG_PIC
;

bits 32
cpu 386

global mini_prng_mix3_RP3
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
mini_prng_mix3_RP3:  ; uint32_t mini_prng_mix3_RP3(uint32_t key) __attribute__((__regparm__(3)));
; mini_prng_mix3 is a period 2**32-1 PNRG ([13,17,5]), to fill the seeds.
;
; https://stackoverflow.com/a/54708697 , https://stackoverflow.com/a/70960914
;
; if (!key) ++key;
; key ^= (key << 13);
; key ^= (key >> 17);
; key ^= (key << 5);
; return key;
		test eax, eax
		jnz .nz
		inc eax
.nz:		mov edx, eax
		shl edx, 13
		xor eax, edx
		mov edx, eax
		shr edx, 17
		xor eax, edx
		mov edx, eax
		shl edx, 5
		xor eax, edx
		ret

%ifdef CONFIG_PIC  ; Already position-independent code.
%endif

; __END__
