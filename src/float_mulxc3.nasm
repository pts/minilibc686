;
; a bit manually optimized disassembly from libgcc.a of GCC 7.5.0
; Compile to i386 ELF .o object: nasm -O999999999 -w+orphan-labels -f elf -o float_chp.o float_chp.nasm
;
; The following libgcc.a versions were tried, and the shortest code was
; selected: 4.4, 4.6, 4.8, 7.5.0, 8, 9, 10, 11. C source cxmuldiv.c in
; pcc-libs-1.1.0.tgz was also tried with soptcc.pl.
;
; TODO(pts): Implement all 3 sizes in terms of `long double'. Just adapt the stack.
;
; Uses: %ifdef CONFIG_PIC
; Uses: %ifdef CONFIG_I386
; Uses: %ifdef CONFIG_MULXC3_INLINE
;

bits 32
%ifdef CONFIG_I386
cpu 386
%else
cpu 686
%endif

global __mulxc3
%ifndef CONFIG_MULXC3_INLINE
global __mulxc3_sub
%endif
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

%ifdef CONFIG_I386  ; Emulate the missing i686 instructions using i386 instructions.
  %macro _fucomip 2  ; The emulation is not perfect, it ruins AX.
    fucomp %1, %2
    fnstsw ax
    sahf
  %endmacro
  %macro _fucomi 2  ; The emulation is not perfect, it ruins AX.
    fucom %1, %2
    fnstsw ax
    sahf
  %endmacro
%else
  %define _fucomip fucomip
  %define _fucomi fucomi
%endif  ; CONFIG_I386

;%define CONFIG_MULXC3_INLINE

section .text
; For PCC and GCC >= 4.3.
__mulxc3:  ; long double _Complex __muldc3(long double a, long double b, long double c, long double d);
; Returns: the product of a + ib and c + id.
;
; /* C source code below based on gcc-7.4.0/libgcc/libgcc2.c */
; #define CONCAT3(A,B,C)_CONCAT3(A,B,C)
; #define _CONCAT3(A,B,C) A##B##C
; #define CONCAT2(A,B) _CONCAT2(A,B)
; #define _CONCAT2(A,B) A##B
; #define isnan(x) __builtin_expect((x) != (x), 0)
; #define isfinite(x) __builtin_expect(!isnan((x) - (x)), 1)
; #define isinf(x) __builtin_expect(!isnan(x) & !isfinite(x), 0)
; #define INFINITY CONCAT2(__builtin_huge_val, CEXT)()
; /* Helpers to make the following code slightly less gross. */
; #define COPYSIGN CONCAT2(__builtin_copysign, CEXT)
; #define FABS CONCAT2(__builtin_fabs, CEXT)
; /* Verify that MTYPE matches up with CEXT. */
; extern void *compile_type_assert[sizeof(INFINITY) == sizeof(MTYPE) ? 1 : -1];
; /* Ensure that we've lost any extra precision. */
; #define TRUNC(x) __asm__("" : "=m"(x) : "m"(x))
; CTYPE CONCAT3(__mul,MODE,3)(MTYPE a, MTYPE b, MTYPE c, MTYPE d) {
;   MTYPE ac, bd, ad, bc, x, y;
;   CTYPE res;
;   ac = a * c; bd = b * d; ad = a * d; bc = b * c;
;   TRUNC(ac); TRUNC(bd); TRUNC(ad); TRUNC(bc);
;   x = ac - bd; y = ad + bc;
;   if (isnan(x) && isnan(y)) {
;     /* Recover infinities that computed as NaN + iNaN. */
;     _Bool recalc = 0;
;     if (isinf(a) || isinf(b)) {
;       /* z is infinite. "Box" the infinity and change NaNs in the other factor to 0. */
;       a = COPYSIGN(isinf(a) ? 1 : 0, a); b = COPYSIGN(isinf(b) ? 1 : 0, b);
;       if (isnan(c)) c = COPYSIGN(0, c);
;       if (isnan(d)) d = COPYSIGN(0, d);
;       recalc = 1;
;     }
;     if (isinf(c) || isinf(d)) {
;       /* w is infinite. "Box" the infinity and change NaNs in the other factor to 0. */
;       c = COPYSIGN(isinf(c) ? 1 : 0, c); d = COPYSIGN(isinf(d) ? 1 : 0, d);
;       if (isnan(a)) a = COPYSIGN(0, a);
;       if (isnan(b)) b = COPYSIGN(0, b);
;       recalc = 1;
;     }
;     if (!recalc && (isinf(ac) || isinf(bd) || isinf(ad) || isinf(bc))) {
;       /* Recover infinities from overflow by changing NaNs to 0. */
;       if (isnan(a)) a = COPYSIGN(0, a);
;       if (isnan(b)) b = COPYSIGN(0, b);
;       if (isnan(c)) c = COPYSIGN(0, c);
;       if (isnan(d)) d = COPYSIGN(0, d);
;       recalc = 1;
;     }
;     if (recalc) {
;       x = INFINITY * (a * c - b * d); y = INFINITY * (a * d + b * c);
;     }
;   }
;   __real__ res = x; __imag__ res = y;
;   return res;
; }
%ifdef CONFIG_MULXC3_INLINE
		enter 0x24, 0
		fld tword [ebp-0x24+0x2c+4]  ; Argument a.
		fld tword [ebp-0x24+0x44+4]  ; Argument c.
		fld st1
		fmul st0, st1
  %define MULXC3_ARG_B tword [ebp-0x24+0x38+4]
  %define MULXC3_ARG_D tword [ebp-0x24+0x50+4]
		fld MULXC3_ARG_B
		fld MULXC3_ARG_D
%else
		;push ebp
		;mov ebp, esp
		;sub esp, byte 0x3c
		enter 0x3c, 0
		fld tword [ebp+0xc]  ; Argument a.
		fld tword [ebp+0x24]  ; Argument c. (Order swapped with b!)
		fld tword [ebp+0x18]  ; Argument b.
		fld tword [ebp+0x30]  ; Argument d.
		call __mulxc3_sub
		mov eax, [ebp+8]  ; Struct return pointer. We return it in EAX according to the ABI.
		fstp tword [eax]
		fstp tword [eax+0xc]
		leave
		ret 4

__mulxc3_sub:	; a c b d
		fld st3
		fmul st0, st3
		; a c b d a*c
		fxch st2
		; a c a*c d b
		fxch st1
		; a c a*c b d
  %define MULXC3_ARG_B tword [ebp-0x3c]
  %define MULXC3_ARG_D tword [ebp-0x30]
		fld st1
		fstp MULXC3_ARG_B
		fld st0
		fstp MULXC3_ARG_D
%endif
		fmul st1, st0
		fxch st1
		fld st0
		fstp tword [ebp-0x24]
		fxch st1
		fmul st0, st4
		fld MULXC3_ARG_B
		fmul st0, st4
		fld st0
		fstp tword [ebp-0x24+0xc]
		fld st3
		fsubrp st3, st0
		fld st1
		faddp st1, st0
		_fucomi st0, st0
		fxch st2
		setp dl
		_fucomi st0, st0
		setp ch
		and dl, ch
		jne .4
		fstp st4
		fstp st0
		fstp st3
		fstp st0
%ifdef CONFIG_MULXC3_INLINE
		jmp short .3
%else
		ret
%endif
.1:		fstp st0
.2:		fstp st2
		fstp st0
		fxch st1
%ifdef CONFIG_MULXC3_INLINE
.3:		mov eax, [ebp-0x24+0x28+4]  ; Struct return pointer. We return it in EAX according to the ABI.
		fstp tword [eax]
		fstp tword [eax+0xc]
		leave
		ret 4
%else
		ret
%endif
.4:		fld st5
		fsub st0, st6
		fstp tword [ebp-0x24+0x18]
		fld MULXC3_ARG_B
		_fucomi st0, st0
		fsub st0, st0
		setpo ch
		_fucomip st0, st0
		fxch st5
		setp cl
		and cl, ch
		_fucomi st0, st0
		jp .5
		fld tword [ebp-0x24+0x18]
		_fucomip st0, st0
		jp near .46
.5:		test cl, cl
		jne near .24
.6:		fld st4
		fsub st0, st5
		fstp tword [ebp-0x24+0x18]
		fld MULXC3_ARG_D
		_fucomi st0, st0
		fld st0
		setpo dl
		fsubrp st1, st0
		_fucomip st0, st0
		fxch st4
		setp ch
		and dl, ch
		_fucomi st0, st0
		jp .7
		fld tword [ebp-0x24+0x18]
		_fucomip st0, st0
		jp near .48
.7:		test dl, dl
		jne near .29
		test cl, cl
		jne near .21
		fld st3
		fsub st0, st4
		fxch st4
		_fucomip st0, st0
		jp .8
		fxch st3
		_fucomip st0, st0
		jp .14
		jmp short .9
.8:		fstp st3
.9:		fld tword [ebp-0x24]
		fld st0
		fsub st0, st1
		fxch st1
		_fucomip st0, st0
		jp .10
		_fucomip st0, st0
		jp .14
		jmp short .11
.10:		fstp st0
.11:		fld st0
		fsub st0, st1
		fxch st1
		_fucomip st0, st0
		jp .12
		_fucomip st0, st0
		jp .15
		jmp short .13
.12:		fstp st0
.13:		fld tword [ebp-0x24+0xc+4]
		fld st0
		fsub st0, st1
		fxch st1
		_fucomip st0, st0
		jp .1
		_fucomip st0, st0
		jpo .2
		jmp short .15
.14:		fstp st0
.15:		fstp st0
		fstp st2
.17:		_fucomi st0, st0
		jp near .45
.18:		fld MULXC3_ARG_B
		_fucomi st0, st0
		jp near .43
		fstp st0
		fxch st1
.19:		_fucomi st0, st0
		jp near .41
.20:		fld MULXC3_ARG_D
		_fucomi st0, st0
		jp near .39
		fstp st0
		jmp short .23
.21:		fstp st5
		fstp st0
		fstp st0
.22:		fstp st0
		fxch st1
.23:		fld st1
		fmul st0, st1
		fld MULXC3_ARG_B
		fld MULXC3_ARG_D
		fmul st1, st0
		fxch st2
		fsubrp st1, st0
		push dword 0x7f800000  ; inf.
		fld dword [ebp-0x24]
		pop eax
		fmul st1, st0
		fxch st2
		fmulp st4, st0
		fld MULXC3_ARG_B
		fmulp st3, st0
		fxch st3
		faddp st2, st0
		fmulp st1, st0
		fxch st1
%ifdef CONFIG_MULXC3_INLINE
		jmp near .3
%else
		ret
%endif
.24:		fxam
		fnstsw ax
		fstp st0
		test ah, 2
		fldz
		je .25
		fstp st0
		fldz
		fchs
.25:		fld1
.26:		fld tword [ebp-0x24+0x38+4]  ; Argumend d.
		fxam
		fnstsw ax
		fstp st0
		test ah, 2
		fabs
		je .27
		fchs
.27:		fstp MULXC3_ARG_B
		fxch st4
		_fucomi st0, st0
		jp near .38
.28:		fld MULXC3_ARG_D
		_fucomip st0, st0
		jp near .36
		fxch st4
		mov cl, dl
		jmp near .6
.29:		fstp st5
		fstp st0
		fstp st0
		fstp st0
		fxch st1
		fxam
		fnstsw ax
		fstp st0
		test ah, 2
		fldz
		je .30
		fstp st0
		fldz
		fchs
.30:		fld1
.31:		fld MULXC3_ARG_D
		fxam
		fnstsw ax
		fstp st0
		test ah, 2
		fabs
		je .32
		fchs
.32:		fstp MULXC3_ARG_D
		fxch st1
		_fucomi st0, st0
		jp .35
.33:		fld MULXC3_ARG_B
		_fucomi st0, st0
		jpo .22
		fxam
		fnstsw ax
		fstp st0
		test ah, 2
		fldz
		je .34
		fstp st0
		fldz
		fchs
.34:		fstp MULXC3_ARG_B
		fxch st1
		jmp near .23
.35:		fxam
		fnstsw ax
		fstp st0
		test ah, 2
		fldz
		je .33
		fstp st0
		fldz
		fchs
		jmp short .33
.36:		fld MULXC3_ARG_D
		fxam
		fnstsw ax
		fstp st0
		test ah, 2
		fldz
		je .37
		fstp st0
		fldz
		fchs
.37:		fstp MULXC3_ARG_D
		fxch st4
		mov cl, dl
		jmp near .6
.38:		fxam
		fnstsw ax
		fstp st0
		test ah, 2
		fldz
		je .28
		fstp st0
		fldz
		fchs
		jmp near .28
.39:		fxam
		fnstsw ax
		fstp st0
		test ah, 2
		fldz
		je .40
		fstp st0
		fldz
		fchs
.40:		fstp MULXC3_ARG_D
		jmp near .23
.41:		fxam
		fnstsw ax
		fstp st0
		test ah, 2
		fldz
		je .42
		fstp st0
		fldz
		fchs
.42:		jmp near .20
.43:		fxam
		fnstsw ax
		fstp st0
		test ah, 2
		fldz
		je .44
		fstp st0
		fldz
		fchs
.44:		fstp MULXC3_ARG_B
		fxch st1
		jmp near .19
.45:		fxam
		fnstsw ax
		fstp st0
		test ah, 2
		fldz
		je .18
		fstp st0
		fldz
		fchs
		jmp near .18
.46:		fxam
		fnstsw ax
		fstp st0
		test ah, 2
		fld1
		je .47
		fstp st0
		fld1
		fchs
.47:		test cl, cl
		jne .25
		fldz
		jmp near .26
.48:		fstp st5
		fstp st0
		fstp st0
		fstp st0
		fxch st1
		fxam
		fnstsw ax
		fstp st0
		test ah, 2
		fld1
		je .49
		fstp st0
		fld1
		fchs
.49:		test dl, dl
		jne .30
		fldz
		jmp near .31

%ifdef CONFIG_PIC  ; Already position-independent code.
%endif

; __END__
