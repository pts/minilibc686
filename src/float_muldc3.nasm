;
; a bit manually optimized disassembly from libgcc.a of GCC 7.5.0
; Compile to i386 ELF .o object: nasm -O999999999 -w+orphan-labels -f elf -o float_chp.o float_chp.nasm
;
; The following libgcc.a versions were tried, and the shortest code was
; selected: 4.4, 4.6, 4.8, 7.5.0, 8, 9, 10, 11. C source cxmuldiv.c in
; pcc-libs-1.1.0.tgz was also tried with soptcc.pl.
;
; Uses: %ifdef CONFIG_PIC
; Uses: %ifdef CONFIG_I386
;

bits 32
%ifdef CONFIG_I386
cpu 386
%else
cpu 686
%endif

global __muldc3
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
  %macro _fucomip 2
    fucomp %1, %2
    fnstsw ax  ; !! TODO(pts): Is it OK to override AX? Check everywhere.
    sahf
  %endmacro
  %macro _fucomi 2
    fucom %1, %2
    fnstsw ax
    sahf
  %endmacro
%else
  %define _fucomip fucomip
  %define _fucomi fucomi
%endif  ; CONFIG_I386

section .text
; For PCC and GCC >= 4.3.
__muldc3:  ; double _Complex __muldc3(double a, double b, double c, double d);
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
		push esi
		sub esp, byte 0x44
		fld qword [esp+0x50]
		fld qword [esp+0x58]
		fld qword [esp+0x60]
		fld qword [esp+0x68]
		fld st3
		fmul st0, st2
		fstp qword [esp+0x20]
		fld st2
		fmul st0, st1
		fstp qword [esp+0x28]
		fld st3
		fmul st0, st1
		fstp qword [esp+0x30]
		fld st1
		fmul st0, st3
		fstp qword [esp+0x38]
		fld qword [esp+0x20]
		fld qword [esp+0x28]
		fst qword [esp]
		fld st1
		fsubrp st1, st0
		fld qword [esp+0x30]
		fst qword [esp+8]
		fld qword [esp+0x38]  ; !! TODO(pts): [esp+0x38] and [esp+0x10] (etc.) store the same value.
		fst qword [esp+0x10]
		faddp st1, st0
		_fucomi st0, st0
		fxch st1
		setp dl  ; isnan(x)?
		_fucomi st0, st0
		setp al  ; isnan(y)?
		and dl, al
		jne .4
		fstp st5
		jmp short .2
.1:		fstp st0
.2:		fstp st5
		fstp st0
		fstp st0
		fstp st0
.3:		mov eax, [esp+0x4c]  ; Struct return pointer. We return it in EAX according to the ABI.
		fstp qword [eax]
		fstp qword [eax+8]
		add esp, byte 0x44
		pop esi
		ret 4
.4:		fld st6
		fsub st0, st7
		fstp qword [esp+0x18]
		fxch st5
		_fucomi st0, st0
		fld st0
		setpo al
		mov esi, eax
		fsub st0, st1
		_fucomip st0, st0
		fxch st6
		setp al
		and esi, eax
		_fucomi st0, st0
		jp .5
		fld qword [esp+0x18]
		_fucomip st0, st0
		jp near .51
.5:		mov eax, esi
		test al, al
		jne near .29
.6:		fld st4
		fsub st0, st5
		fstp qword [esp+0x18]
		fxch st3
		_fucomi st0, st0
		fld st0
		setpo dl
		fsub st0, st1
		_fucomip st0, st0
		fxch st4
		setp al
		and edx, eax
		_fucomi st0, st0
		jp .7
		fld qword [esp+0x18]
		_fucomip st0, st0
		jp near .53
.7:		test dl, dl
		jne near .37
		mov eax, esi
		test al, al
		jne near .24
		fld st2
		fsub st0, st3
		fxch st3
		_fucomip st0, st0
		jp .8
		fxch st2
		_fucomip st0, st0
		jp .14
		jmp short .9
.8:		fstp st2
.9:		fld qword [esp]
		fld st0
		fsub st0, st1
		fxch st1
		_fucomip st0, st0
		jp .10
		_fucomip st0, st0
		jp .14
		jmp short .11
.10:		fstp st0
.11:		fld qword [esp+8]
		fld st0
		fsub st0, st1
		fxch st1
		_fucomip st0, st0
		jp .12
		_fucomip st0, st0
		jp .14
		jmp short .13
.12:		fstp st0
.13:		fld qword [esp+0x10]
		fld st0
		fsub st0, st1
		fxch st1
		_fucomip st0, st0
		jp .1
		_fucomip st0, st0
		jpo .2
.14:		fstp st0
		fstp st3
		fxch st1
		fxch st2
		fxch st1
.17:		_fucomi st0, st0
		jp near .48
		fxch st3
		jmp short .19
.18:		fxch st3
.19:		_fucomi st0, st0
		jp near .47
		fxch st1
		jmp short .21
.20:		fxch st1
.21:		_fucomi st0, st0
		jp near .46
		fxch st2
		jmp short .23
.22:		fxch st2
.23:		_fucomi st0, st0
		jp near .45
		jmp short .27
.24:		fstp st5
		fstp st0
		fstp st0
		jmp short .25b
.25:		fxch st3
.25b:		fxch st1
		fxch st2
		jmp short .28
.27:		fxch st2
		fxch st1
		fxch st3
		fxch st1
.28:		fld st1
		fmul st0, st1
		fld st4
		fmul st0, st4
		fsubp st1, st0
		push dword 0x7f800000  ; inf.
		fld dword [esp]
		pop eax
		fmul st1, st0
		fxch st3
		fmulp st4, st0
		fxch st1
		fmulp st4, st0
		fxch st2
		faddp st3, st0
		fmulp st2, st0
		jmp near .3
.29:		fxam
		fnstsw ax
		fstp st0
		test ah, 2
		fldz
		je .30
		fstp st0
		fldz
		fchs
.30:		fld1
		fxch st7
.31:		fxam
		fnstsw ax
		fstp st0
		fxch st6
		test ah, 2  ; True if st0 was negative when fxam was called.
		fabs
		je .32
		fchs
		fxch st4
		jmp short .33
.32:		fxch st4
.33:		_fucomi st0, st0
		jp near .49
		fxch st3
		jmp short .35
.34:		fxch st3
.35:		_fucomi st0, st0
%ifdef CONFIG_I386
		jp near .44
%else
		jp .44
%endif
.36:		fxch st3
		fxch st4
		fxch st6
		mov esi, edx
		jmp near .6
.37:		fstp st5
		fstp st0
		fstp st0
		fxch st1
		fxch st2
		fxam
		fnstsw ax
		fstp st0
		test ah, 2
		fldz
		je .38
		fstp st0
		fldz
		fchs
.38:		fld1
		fxch st3
.39:		fxam
		fnstsw ax
		fstp st0
		fxch st2
		test ah, 2
		fabs
		je .40
		fchs
		fxch st1
		jmp short .41
.40:		fxch st1
.41:		_fucomi st0, st0
		jp near .50
		fxch st3
		jmp short .43
.42:		fxch st3
.43:		_fucomi st0, st0
		jpo .25
		fxam
		fnstsw ax
		fstp st0
		test ah, 2
		fldz
		je .25
		fstp st0
		fldz
		fchs
		fxch st3
		fxch st1
		fxch st2
		jmp near .28
.44:		fxam
		fnstsw ax
		fstp st0
		test ah, 2
		fldz
		je .36
		fstp st0
		fldz
		mov esi, edx
		fchs
		fxch st3
		fxch st4
		fxch st6
		jmp near .6
.45:		fxam
		fnstsw ax
		fstp st0
		test ah, 2
		fldz
		je .27
		fstp st0
		fldz
		fchs
		fxch st2
		fxch st1
		fxch st3
		fxch st1
		jmp near .28
.46:		fxam
		fnstsw ax
		fstp st0
		test ah, 2
		fldz
		je .22
		fstp st0
		fldz
		fchs
		fxch st2
		jmp near .23
.47:		fxam
		fnstsw ax
		fstp st0
		test ah, 2
		fldz
		je .20
		fstp st0
		fldz
		fchs
		fxch st1
		jmp near .21
.48:		fxam
		fnstsw ax
		fstp st0
		test ah, 2
		fldz
		je .18
		fstp st0
		fldz
		fchs
		fxch st3
		jmp near .19
.49:		fxam
		fnstsw ax
		fstp st0
		test ah, 2
		fldz
		je .34
		fstp st0
		fldz
		fchs
		fxch st3
		jmp near .35
.50:		fxam
		fnstsw ax
		fstp st0
		test ah, 2
		fldz
		je .42
		fstp st0
		fldz
		fchs
		fxch st3
		jmp near .43
.51:		fxam
		fnstsw ax
		fstp st0
		test ah, 2
		fld1
		je .52
		fstp st0
		fld1
		fchs
.52:		mov eax, esi
		test al, al
		jne .30
		fldz
		fxch st7
		jmp near .31
.53:		fstp st5
		fstp st0
		fstp st0
		fxch st1
		fxch st2
		fxam
		fnstsw ax
		fstp st0
		test ah, 2
		fld1
		je .54
		fstp st0
		fld1
		fchs
.54:		test dl, dl
		jne .38
		fldz
		fxch st3
		jmp near .39

%ifdef CONFIG_PIC  ; Already position-independent code.
%endif

; __END__
