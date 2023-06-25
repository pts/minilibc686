;
; Compile to i386 ELF .o object: nasm -O999999999 -w+orphan-labels -f elf -o tcc_cvt_ftol.o tcc_cvt_ftol.nasm
;

bits 32
cpu 386

global __tcc_cvt_ftol
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
; Needed by the TCC (__TINYC__) compiler 0.9.26 https://github.com/anael-seghezzi/tcc-0.9.26
__tcc_cvt_ftol:
		push ebp
		mov ebp, esp
		sub esp, byte 0x10
		fnstcw [ebp-0x4]
		mov eax, [ebp-0x4]
		or eax, 0xc00
		mov [ebp-0x8], eax
		fldcw [ebp-0x8]
		fistp qword [ebp-0x10]
		fldcw [ebp-0x4]
		mov eax, [ebp-0x10]
		mov edx, [ebp-0xc]
		leave
		ret

%ifdef CONFIG_PIC  ; Already position-independent code.
%endif

; __END__
