;
; written by pts@fazekas.hu at Sun May 21 19:43:56 CEST 2023
; Compile to i386 ELF .o object: nasm -O999999999 -w+orphan-labels -f elf -o tcc_alloca.o tcc_alloca.nasm
;

bits 32
cpu 386

global alloca
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
; Needed by the TCC (__TINYC__) compiler 0.9.26.
; The ABI (register arguments) is specific to alloca, doesn't depend on -mregparm=....
; TODO(pts): Make sure that GCC uses __builtin_alloca (-fbuiltin-alloca?).
alloca:
		pop edx
		pop eax
		add eax, byte 3
		and eax, byte ~3
		jz .1
		sub esp, eax
		mov eax, esp
.1:		push edx
		push edx
		ret

%ifdef CONFIG_PIC  ; Already position-independent code.
%endif

; __END__
