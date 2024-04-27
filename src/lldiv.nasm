;
; Compile to i386 ELF .o object: nasm -O999999999 -w+orphan-labels -f elf -o lldiv.o lldiv.nasm
;
; Uses: %ifdef CONFIG_PIC
;

bits 32
cpu 386

global mini_lldiv
%ifdef CONFIG_SECTIONS_DEFINED
%elifidn __OUTPUT_FORMAT__, bin
section .text align=1
section .rodata align=4
section .data align=4
section .bss align=4
__I8D equ +0x12345678
%else
extern __I8D
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
mini_lldiv:  ; lldiv_t mini_lldiv(long long numerator, long long denominator);
		push ebx
		push esi
		mov esi, esp  ; Make subsequent movs shorter (1 byte each).
		mov eax, [esi+0x10]  ; Low  dword of numerator.
		mov edx, [esi+0x14]  ; High dword of numerator.
		mov ebx, [esi+0x18]  ; Low  dword of denominator.
		mov ecx, [esi+0x1c]  ; High dword of denominator.
		mov esi, [esi+0xc]   ; Result pointer.
		; Divides (signed) EDX:EAX by ECX:EBX, store the result in EDX:EAX and the remainder in ECX:EBX.
		; Keeps other registers (except for EFLAGS) intact.
		call __I8D
		mov [esi], eax       ; Low  dword of result.quot.
		mov [esi+4], edx     ; High dword of result.quot.
		mov [esi+8], ebx     ; Low  dword of result.rem.
		mov [esi+0xc], ecx   ; High dword of result.rem.
		xchg eax, esi  ; EAX := ESI (result pointer); ESI := junk.
		pop esi
		pop ebx
		ret RET_STRUCT

%ifdef CONFIG_PIC  ; Already position-independent code.
%endif

; __END__
