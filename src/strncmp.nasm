;
; written by pts@fazekas.hu at Fri Jun 23 17:01:32 CEST 2023
; Compile to i386 ELF .o object: nasm -O999999999 -w+orphan-labels -f elf -o strncmp.o strncmp.nasm
;
; Code size: 0x29 bytes.
;
; Uses: %ifdef CONFIG_PIC
;

bits 32
cpu 386

global mini_strncmp
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
mini_strncmp:  ; int mini_strncmp(const void *s1, const void *s2, size_t n);
; Optimized for size. EAX == s1, EDX == s2, EBX(watcall) == n, ECX(rp3) == n.
		push esi
		push edi
		mov esi, [esp+0xc]  ; s1.
		mov edi, [esp+0x10]  ; s2.
		mov ecx, [esp+0x14]
		; TODO(pts): Make the code below shorter.
		xor eax, eax
		jecxz .done
.next:		lodsb
		scasb
		je .same_char
		mov al, 1  ; The highest 24 bits of EAX are already 0.
		jnc .done
		neg eax
		jmp short .done
.same_char:	test al, al
		jz .equal
		loop .next
.equal:		xor eax, eax
.done:		pop edi
		pop esi
		ret

%ifdef CONFIG_PIC  ; Already position-independent code.
%endif

; __END__
