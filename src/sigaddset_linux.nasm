;
; written by pts@fazekas.hu at Mon Jul  3 21:07:51 CEST 2023
; Compile to i386 ELF .o object: nasm -O999999999 -w+orphan-labels -f elf -o sigaddset_linux.o sigaddset_linux.nasm
;
; Code size: 0x22 bytes.
;
; Uses: %ifdef CONFIG_PIC
;

bits 32
cpu 386

global mini_sigaddset
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
mini_sigaddset:  ; int mini_sigaddset(sigset_t *set, int signum);
		mov edx, [esp+1*4]  ; Argument `set'.
		mov ecx, [esp+2*4]  ; Argument signum.
		xor eax, eax
		dec ecx
		cmp ecx, byte 0x40
		jae .error  ; TODO(pts): Set errno := EINVAL.
		inc eax  ; EAX := 1.
		cmp ecx, byte 0x20
		jb .low
		add edx, byte 4
.low:		shl eax, cl  ; EAX := 1 << (ECX & 0x1f).
		or [edx], eax
		xor eax, eax  ; Return value := 0 (success).
		db 0xb2  ; `mov dl, ...', just ignore the next `dec eax' byte.
.error:		dec eax  ; Return value := -1 (error).
		ret

%ifdef CONFIG_PIC  ; Already position-independent code.
%endif

; __END__
