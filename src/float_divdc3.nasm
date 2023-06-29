;
; based on disassemby from libgcc.a of GCC 7.5.0
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

global __divdc3
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
    fnstsw ax
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
__divdc3:  ; double _Complex __divdc3(double a, double b, double c, double d);
; Returns: the quotient of (a + ib) / (c + id).
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
; CTYPE CONCAT3(__div,MODE,3)(MTYPE a, MTYPE b, MTYPE c, MTYPE d) {
;   MTYPE denom, ratio, x, y;
;   CTYPE res;
;   /* ??? We can get better behavior from logarithmic scaling instead of
;    * the division.  But that would mean starting to link libgcc against
;    * libm.  We could implement something akin to ldexp/frexp as gcc builtins
;    * fairly easily...
;    */
;   if (FABS(c) < FABS(d)) {
;     ratio = c / d; denom = (c * ratio) + d;
;     x = ((a * ratio) + b) / denom; y = ((b * ratio) - a) / denom;
;   } else {
;     ratio = d / c; denom = (d * ratio) + c;
;     x = ((b * ratio) + a) / denom; y = (b - (a * ratio)) / denom;
;   }
;   /* Recover infinities and zeros that computed as NaN+iNaN; the only cases
;    * are nonzero/zero, infinite/finite, and finite/infinite.
;    */
;   if (isnan(x) && isnan(y)) {
;     if (c == 0.0 && d == 0.0 && (!isnan(a) || !isnan(b))) {
;       x = COPYSIGN(INFINITY, c) * a; y = COPYSIGN(INFINITY, c) * b;
;     } else if ((isinf(a) || isinf(b)) && isfinite(c) && isfinite(d)) {
;       a = COPYSIGN(isinf(a) ? 1 : 0, a); b = COPYSIGN(isinf(b) ? 1 : 0, b);
;       x = INFINITY * (a * c + b * d); y = INFINITY * (b * c - a * d);
;     } else if ((isinf(c) || isinf(d)) && isfinite(a) && isfinite(b)) {
;       c = COPYSIGN(isinf(c) ? 1 : 0, c); d = COPYSIGN(isinf(d) ? 1 : 0, d);
;       x = 0.0 * (a * c + b * d); y = 0.0 * (b * c - a * d);
;     }
;   }
;   __real__ res = x; __imag__ res = y;
;   return res;
; }
		push ebx
		fld qword [esp+0xc]
		fld qword [esp+0x14]
		fld qword [esp+0x1c]
		fld qword [esp+0x24]
		fld st1
		fabs
		fld st1
		fabs
		_fucomip st0, st1
		fstp st0
		jbe .8
		fld st1
		fdiv st0, st1
		fld st2
		fmul st0, st1
		fadd st0, st2
		fld st5
		fmul st0, st2
		fadd st0, st5
		fdiv st0, st1
		fxch st2
		fmul st0, st5
		fsub st0, st6
		fdivrp st1, st0
		jmp short .1
.8:		fld st0
		fdiv st0, st2
		fld st1
		fmul st0, st1
		fadd st0, st3
		fld st1
		fmul st0, st5
		fadd st0, st6
		fdiv st0, st1
		fxch st2
		fmul st0, st6
		fsubr st0, st5
		fdivrp st1, st0
.1:		_fucomi st0, st0  ; isnan(x)?
		jp .9
		fstp st5
		fstp st3
		jmp short .2b
.2:		fstp st4
		fstp st4
.2b:		fstp st0
		fstp st0
		jmp short .7
.3:		fstp st0
.4:		fstp st0
.5:		fstp st0
		fstp st3
		fstp st0
		fstp st0
		fxch st1
.7:		mov eax, [esp+8]  ; Struct return pointer. We return it in EAX according to the ABI.
		fstp qword [eax]
		fstp qword [eax+8]
		pop ebx
		ret 4
.9:		fxch st1
		_fucomi st0, st0  ; isnan(y)?
		jpo .2  ; if (!(isnan(x) && isnan(y))) goto .2;
		fxch st5
		_fucomi st0, st0
		fldz
		setpo bl  ; BL := !isnan(a).
		_fucomi st0, st4  ; c == 0.0?
		jp .13
		jne .13
		_fucomip st0, st3 ; d == 0.0?
		jp .14
		jne .14
		fxch st4
		_fucomi st0, st0
		jnp .10  ; if (!isnan(b)) goto .10;  Jump on PF=1, indicating unordered==nan (C2=1).
		test bl, bl
		jnz .10  ; if (!isnan(a)) goto .10;
		fld st4
		fsub st0, st5
		fxch st1
		fxch st5
		fxch st1
		jmp short .15
.10:
; x = COPYSIGN(INFINITY, c) * a; y = COPYSIGN(INFINITY, c) * b;
		fstp st5
		fstp st0
		fstp st0
		fxch st1
		fxch st2
		fxch st1
		fxam
		fnstsw ax
		fstp st0
		shr eax, 9
		shl eax, 31  ; EAX := (st0 was negative when fxam was called) ? 0x80000000 : 0.
		or eax, 0x7f800000  ; EAX := (st0 was negative when fxam was called) ? (f32)-inf : (f32)inf.
		push eax ; inf or -inf.
		fld dword [esp]  ; inf or -inf.
		pop eax
		fmul st2, st0
		fmulp st1, st0
		fxch st1
		jmp near .7
.13:		fstp st0
.14:		fld st0
		fsub st0, st1
		_fucomi st0, st0
		setp al
		and bl, al
		jnz near .30
.15:		fld st5
		fsub st0, st6
		fxch st6
		_fucomi st0, st0
		jp .16
		fxch st6
		_fucomip st0, st0
		jp near .30
		jmp short .17
.16:		fstp st6
.17:		fld st4
		fsub st0, st5
		fxch st5
		jmp short .19
.18:		fxch st5
.19:		_fucomi st0, st0
		fxch st5
		setpo al
		_fucomip st0, st0
		setp bl
		and al, bl
		jne .22
		fld st3
		fsub st0, st4
		fxch st4
		jmp short .21
.20:		fxch st4
.21:		_fucomi st0, st0
		jp .3
		fxch st4
		_fucomip st0, st0
		jpo .4
		xor eax, eax
.22:		_fucomip st0, st0
		jp .5
		fld st4
		fsub st0, st5
		_fucomip st0, st0
		jp .5
		fstp st5
		fstp st0
		fxch st1
		fxch st2
		fxch st3
		test al, al
		jne near .37
		fldz
		fxch st3
.23:		fxam
		fnstsw ax
		fstp st0
		fxch st2
		test ah, 2
		fabs
		je .24
		fchs
.24:		fld st1
		fsub st0, st2
		fxch st2
		_fucomi st0, st0
		jp .25
		fxch st2
		_fucomip st0, st0
		jp near .39
		jmp short .26
.25:		fstp st2
.26:		fldz
		fxch st2
.27:		fxam
		fnstsw ax
		fstp st0
		fxch st1
		test ah, 2
		fabs
		je .28
		fchs
.28:		fld st2
		fmul st0, st2
		fld st4
		fmul st0, st2
		faddp st1, st0
		fldz
		fmul st1, st0
		fxch st5
		fmulp st3, st0
		fxch st1
		fmulp st3, st0
		fxch st2
		fsubp st1, st0
		fmulp st2, st0
		jmp near .7
.30:		fld st4
		fsub st0, st5
		_fucomi st0, st0
		jp .18
		fstp st0
		fld st3
		fsub st0, st4
		_fucomi st0, st0
		jp .20
		fstp st0
		fstp st0
		fstp st5
		fstp st0
		fxch st1
		fxch st2
		fxch st3
		test bl, bl
		jnz .38
		fldz
		fxch st1
.31:		fxam
		fnstsw ax
		fstp st0
		test ah, 2
		fabs
		je .32
		fchs
.32:		fld st3
		fsub st0, st4
		fxch st4
		_fucomi st0, st0
		jp .33
		fxch st4
		_fucomip st0, st0
		jp .40
		jmp short .34
.33:		fstp st4
.34:		fldz
		fxch st4
.35:		fxam
		fnstsw ax
		fstp st0
		fxch st3
		test ah, 2
		fabs
		je .36
		fchs
.36:		fld st2
		fmul st0, st4
		fld st2
		fmul st0, st2
		faddp st1, st0
		push dword 0x7f800000
		fld dword [esp]
		pop ecx
		fmul st1, st0
		fxch st4
		fmulp st2, st0
		fxch st4
		fmulp st2, st0
		fsubrp st1, st0
		fmulp st1, st0
		fxch st1
		jmp near .7
.37:		fld1
		fxch st3
		jmp near .23
.38:		fld1
		fxch st1
		jmp short .31
.39:		fld1
		fxch st2
		jmp near .27
.40:		fld1
		fxch st4
		jmp short .35

%ifdef CONFIG_PIC  ; Already position-independent code.
%endif

; __END__
