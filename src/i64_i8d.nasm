;
; Compile to i386 ELF .o object: nasm -O999999999 -w+orphan-labels -f elf -o i64_i8d.o i64_i8d.nasm
;
; Uses: %ifdef CONFIG_PIC
;

bits 32
cpu 386

global __I8D
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

section .text
__I8D:
; Used by OpenWatcom directly, and used by GCC through the __udivdi3 wrapper.
; It uses __U8D.
;
; Divide (signed) EDX:EAX by ECX:EBX, store the result in EDX:EAX and the modulo in ECX:EBX.
; Keep other registers (except for EFLAGS) intact.
		or edx, edx
		js .2
		or ecx, ecx
		js .1
		jmp strict near __U8D  ; NASM linking could make this jump shorter, smart linking can't.
.1:		neg ecx
		neg ebx
		sbb ecx, byte 0
		call __U8D
		jmp short .4
.2:		neg edx
		neg eax
		sbb edx, byte 0
		or ecx, ecx
		jns .3
		neg ecx
		neg ebx
		sbb ecx, byte 0
		call __U8D
		neg ecx
		neg ebx
		sbb ecx, byte 0
		ret
.3:		call __U8D
		neg ecx
		neg ebx
		sbb ecx, byte 0
.4:		neg edx
		neg eax
		sbb edx, byte 0
		ret

%ifdef CONFIG_PIC  ; Already position-independent code.
%endif

; __END__
