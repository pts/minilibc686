;
; converted from .dietlibc-0.34/i386/pow.S by pts@fazekas.hu at Sat Oct 26 23:40:40 CEST 2024
; Compile to i386 ELF .o object: nasm -O999999999 -w+orphan-labels -f elf -o pow.o pow.nasm
;
; Uses: %ifdef CONFIG_PIC
;

bits 32
cpu 386

global mini_pow
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
mini_pow:  ; double mini_pow(double x, double y);
		; As indicated in README.md, we can assume that an FPU is present. Even a 80387 provides fpow, so we are good.

; TODO(pts): Implement it powf(...) and powl(...) like this (even better, smart.nasm):
;powf:
;	flds 4(%esp)  ; x
;	flds 8(%esp)  ; y
;	jmp .powreg
;powl:
;	fldt 4(%esp)  ; x
;	fldt 16(%esp)  ; y
;	jmp .powreg
		fld qword [esp+4]
		fld qword [esp+3*4]
.powreg:  	; x^y; st0=y, st1=x
		ftst  ; y = 0 ?
		fstsw ax
		fld1  ; st0=1, st1=y, st2=x
		sahf
		jz short .1  ; return 1
		fcomp st1  ; y = 1 ?
		fstsw ax
		fxch st1  ; st0=x, st1=y
		sahf
		jz short .1  ; return x
		ftst  ; x = 0 ?
		fstsw ax
		sahf
		je short .1
		jnc short .finpow  ; x > 0
		fxch st1  ; st0=y, st1=x
		fld st0  ; st0=y, st1=y, st2=x
		frndint  ; st0=int(y)
		fcomp st1  ; y = int(y)?
		fstsw ax
		fxch st1
		sahf
		jnz short .finpow  ; fyl2x -> st0 = NaN
		; Is y even or odd?
		fld1
		fadd st0, st0  ; st0 = 2
		fdivr st0, st2  ; st0=st2/2
		frndint
		fadd st0, st0
		fcomp st2  ; # st0 = x, st1 = y
		fstsw ax  ; # st0 = -x  
		fchs  ; Change sign.
		sahf
		jz short .finpow  ; y is even.
		call .finpow  ; y is odd.
		fchs  ; Change sign.
.1:		ret
.finpow:  ; This can be the tail of exp(...) as well. TODO(pts): Share this with smart.nasm.	
		fyl2x
		fst st1
		frndint
		fst st2
		fsubp st1, st0
		f2xm1
		fld1
		faddp st1, st0
		fscale
		ret


%ifdef CONFIG_PIC  ; Already position-independent code.
%endif

; __END__
