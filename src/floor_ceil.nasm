;
; written by pts@fazekas.hu at Fri Nov  1 04:00:47 CET 2024
; Compile to i386 ELF .o object: nasm -O999999999 -w+orphan-labels -f elf -o ceil.o ceil.nasm
;
; Code size: 0x25 bytes.
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
%if 1  ; TODO(pts): Use smart linking to make this code 5 bytes shorter if only mini_floor(...) or mini_ceil(...) are used, like this.
	        mov ch, 4  ; Rounding mode for floor. ROUND_DOWN<<2.
	        jmp short mini_ceil.both  ; No way to shorten this to one-byte, skipping over the next instruction.
mini_ceil:  ; double mini_ceil(double x);
		mov ch, 8  ; Rounding mode for ceil. ROUND_UP<<2.
%endif
.both:		push eax  ; Make room for local variable.
		fnstcw word [esp]  ; Save FPU control word.
		pop eax  ; AX would have been enough, but using EAX makes the instructions shorter.
		push eax
		and ah, ~12
%if 1
		or ah, ch  ; Set rounding mode within AX.
%else  ; With smart.nasm, if only mini_floor(...) is used.
		or ah, 4  ; Set rounding mode within AX: ROUND_DOWN<<2.
%endif
		push eax
		mov eax, esp
		fld qword [eax+3*4]  ; x.
		fldcw word [eax] ; Set rounding mode in FPU control word.
		frndint
		fldcw word [eax+4]  ; Restore old FPU control word.
		fstp qword [eax]
		fld qword [eax]  ; Round result to double.
		pop eax  ; Clean up local variable.
		pop eax  ; Clean up local variable.
		ret

%ifdef CONFIG_PIC  ; Already position-independent code.
%endif

; __END__
