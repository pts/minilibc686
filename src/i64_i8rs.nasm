;
; Compile to i386 ELF .o object: nasm -O999999999 -w+orphan-labels -f elf -o i64_i8rs.o i64_i8rs.nasm
;
; Uses: %ifdef CONFIG_PIC
;

bits 32
cpu 386

global __I8RS
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
; For OpenWatcom.
__I8RS:  ; long long __watcall_but_ruins_ecx __I8RS(long long a, int b) { return a >> b; }
; Input: EDX:EAX == a; EBX == b.
; Output: EDX:EAX == ((long long)a >> b); EBX == b; ECX == junk.
		mov ecx, ebx
		and cl, 0x3f
		test cl, 0x20
		jnz .2
		shrd eax, edx, cl
		sar edx, cl
		ret
.2:		mov eax, edx
		sub cl, 0x20
		sar edx, 0x1f
		sar eax, cl
		ret

%ifdef CONFIG_PIC  ; Already position-independent code.
%endif

; __END__
