;
; written by pts@fazekas.hu at Tue May 16 18:16:29 CEST 2023
; Compile to i386 ELF .o object: nasm -O999999999 -w+orphan-labels -f elf -o getenv.o getenv.nasm
;
; Code size: 0x28 bytes.
;
; Uses: %ifdef CONFIG_PIC
;

bits 32
cpu 386

global mini_getenv
%ifdef CONFIG_SECTIONS_DEFINED
%elifidn __OUTPUT_FORMAT__, bin
section .text align=1
section .rodata align=4
section .data align=4
section .bss align=4
mini_environ equ +0x12345678
%else
extern mini_environ
section .text align=1
section .rodata align=1
section .data align=1
section .bss align=1
%endif

section .text
mini_getenv:  ; char *mini_getenv(const char *name);
		push esi
		push edi
		mov ecx, [mini_environ]
.next_var:	mov edi, [ecx]
		add ecx, byte 4
		test edi, edi
		jz .done
		mov esi, [esp+3*4]  ; Argument name.
.next_byte:	lodsb
		cmp al, 0
		je .end_name
		scasb
		je .next_byte
		jmp short .next_var
.end_name:	mov al, '='
		scasb
		jne .next_var
.done:		xchg eax, edi  ; EAX := EDI (pointer to var value); EDI := junk.
		pop edi
		pop esi
		ret

%ifdef CONFIG_PIC
%error Not PIC because it uses global variable mini_environ.
times 1/0 nop
%endif

; __END__
