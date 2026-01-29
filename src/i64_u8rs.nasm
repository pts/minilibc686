;
; Compile to i386 ELF .o object: nasm -O999999999 -w+orphan-labels -f elf -o i64_u8rs.o i64_u8rs.nasm
;
; Uses: %ifdef CONFIG_PIC
;

bits 32
cpu 386

global __U8RS
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

section .text
; For OpenWatcom.
__U8RS:  ; unsigned long long __watcall_but_ruins_ecx __U8RS(unsigned long long a, int b) { return a >> b; }
; Input: EDX:EAX == a; EBX == b.
; Output: EDX:EAX == ((unsigned long long)a >> b); EBX == b; ECX == junk.
		mov ecx, ebx
		;and cl, 0x3f  ; Not needed, CL&0x1f is used by shift instructions.
		test cl, 0x20
		jnz .1
		shrd eax, edx, cl
		shr edx, cl
		ret
.1:		mov eax, edx
		;sub ecx, byte 0x20  ; Not needed, CL&0x1f is used by shift instructions.
		xor edx, edx
		shr eax, cl
		ret

%ifdef CONFIG_PIC  ; Already position-independent code.
%endif

; __END__
