;
; written by pts@fazekas.hu at Fri Nov  1 04:00:47 CET 2024
; Compile to i386 ELF .o object: nasm -O999999999 -w+orphan-labels -f elf -o ceil.o ceil.nasm
;
; Uses: %ifdef CONFIG_PIC
;

bits 32
cpu 386

global mini_ceil
global mini_floor
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

mini_floor:  ; double mini_floor(double x);
		; As indicated in README.md, we can assume that an FPU is present. Even a 80387 provides fldexp, so we are good.
	        mov ch, 4  ; Rounding mode for floor. ROUND_DOWN<<2.
	        jmp short mini_ceil.both  ; No way to shorten this to one-byte, skipping over the next instruction.
	        ; TODO(pts): Use smart linking to make this code 4 bytes shorter if only mini_floor(...) or mini_ceil(...) are used.
mini_ceil:  ; double mini_ceil(double x);
		mov ch, 8  ; Rounding mode for ceil. ROUND_UP<<2.
.both:		lea edx, [esp+4]
		push eax
		fstcw word [esp]  ; Get FPU control word to `word [esp]'.
		pop eax  ; We only need the low word (AX).
		push eax
		and ah, ~12  ; Keep all bits except for precision control bits.
		or ah, ch
		push eax
		fldcw word [esp]  ; Set FPU control word from `word [esp+6]'.
		pop eax
		fld qword [edx]
		frndint
		fldcw word [esp]  ; Restore FPU control word from `word [esp]'.
		pop eax
		fstp qword [edx]
		fld qword [edx]  ; Round result to double.
		ret

%ifdef CONFIG_PIC  ; Already position-independent code.
%endif

; __END__
