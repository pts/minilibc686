;
; written by pts@fazekas.hu at Mon Nov 11 20:11:57 CET 2024
; Compile to i386 ELF .o object: nasm -O999999999 -w+orphan-labels -f elf -o stdio_medium_ungetc.o stdio_medium_ungetc.nasm
;
; Code size: 0x29 bytes.
;
; Uses: %ifdef CONFIG_PIC
;

bits 32
cpu 386

global mini_ungetc
global mini_ungetc_RP3
%ifdef CONFIG_SECTIONS_DEFINED
%elifidn __OUTPUT_FORMAT__, bin
section .text align=1
section .rodata align=1
section .data align=1
section .bss align=1
%else
section .text align=1
section .rodata align=4
section .data align=4
section .bss align=4
%endif

section .text
mini_ungetc:  ; int mini_ungetc(int c, FILE *stream);
		mov eax, [esp+4]  ; Argument c.
		mov edx, [esp+8]  ; Argument stream.
		; Fall through to mini_ungetc_RP3.
mini_ungetc_RP3:  ; int mini_ungetc_RP3(int c, FILE *stream) __attribute__((__regparm__(3)));
		; TODO(pts): With smart.nasm, omit the mini_ungetc(...) code if not used, saving 8 bytes above.
		test eax, eax
		js .err
		mov cl, [edx+0x14]  ; .dire.
		dec ecx  ; Shorter than `dec cl'.
		cmp cl, 2
		ja .err
		mov ecx, [edx+8]  ; .buf_read_ptr.
		cmp [edx+0x18], ecx  ; .buf_start.
		je .err
		dec ecx
		mov [edx+0x8], ecx  ; .buf_read_ptr.
		mov [ecx], al
		jmp short .ret
.err:		or eax, byte -1  ; Indicate error.
.ret:		ret

%ifdef CONFIG_PIC  ; Already position-independent code.
%endif

; __END__
