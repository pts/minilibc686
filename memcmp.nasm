;
; based on the assembly code in uClibc-0.9.30.1/libc/string/i386/memcmp.c
; Compile to i386 ELF .o object: nasm -O999999999 -w+orphan-labels -f elf -o memcmp.o memcmp.nasm
;
; Code size: 0x1d bytes.
;
; Uses: %ifdef CONFIG_PIC
;

bits 32
cpu 386

global mini_memcmp
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
mini_memcmp:  ; int mini_memcmp(const void *s1, const void *s2, size_t n);
; Optimized for size. EAX == s1, EDX == s2, EBX(watcall) == n, ECX(rp3) == n.
		push esi
		push edi
		mov esi, [esp+0xc]  ; s1.
		mov edi, [esp+0x10]  ; s2.
		mov ecx, [esp+0x14]
		xor eax, eax
		jecxz .done
		repz cmpsb  ; Continue while equal.
		je .done
		inc eax
		jnc .done
		neg eax
.done:		pop edi
		pop esi
		ret

%ifdef CONFIG_PIC  ; Already position-independent code.
%endif

; __END__
