;
; Compile to i386 ELF .o object: nasm -O999999999 -w+orphan-labels -f elf -o ldiv.o ldiv.nasm
;
; Uses: %ifdef CONFIG_PIC
;

bits 32
cpu 386

global mini_div
global mini_ldiv
%ifdef CONFIG_SECTIONS_DEFINED
%elifidn __OUTPUT_FORMAT__, bin
section .text align=1
section .rodata align=1
section .data align=1
section .bss align=1
__U8D equ +0x12345678
%else
extern __U8D
section .text align=1
section .rodata align=1
section .data align=1
section .bss align=1
%endif

%ifndef RET_STRUCT
  %define RET_STRUCT 4  ; GCC, TinyCC, PCC.
  ;%define RET_STRUCT  ; __WATCOMC__.
%endif

section .text
mini_div:  ; div_t mini_div(int numerator, int denominator);
mini_ldiv:  ; ldiv_t mini_ldiv(long numerator, long denominator);
		mov eax, [esp+8]  ; Argument numerator.
		cdq  ; Sign-extend numerator EAX to EDX:EAX.
		idiv dword [esp+0xc]  ; Argument denominator.
		mov ecx, [esp+4]  ; Result pointer.
		mov [ecx], eax  ; result.quot.
		mov [ecx+4], edx  ; result.rem.
		xchg eax, ecx  ; EAX := ECX (result pointer); ECX := junk.
		ret RET_STRUCT

%ifdef CONFIG_PIC  ; Already position-independent code.
%endif

; __END__
