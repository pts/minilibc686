;
; written by pts@fazekas.hu at Tue Jul  4 02:15:42 CEST 2023
; based on .nasm source file generated by soptcc.pl from c_stdio_medium_fopen.c
; Compile to i386 ELF .o object: nasm -O999999999 -w+orphan-labels -f elf -o stdio_mediump_jmp_freopen_low.o stdio_medium_jmp_freopen_low.nasm
;
; Uses: %ifdef CONFIG_PIC
;

bits 32
cpu 386

global mini___M_jmp_freopen_low
global mini___M_jmp_freopen_low.error
%ifdef CONFIG_SECTIONS_DEFINED
%elifidn __OUTPUT_FORMAT__, bin
section .text align=1
section .rodata align=1
section .data align=1
section .bss align=1
mini_open equ +0x12345678
mini___M_discard_buf equ +0x12345679
mini___M_start_flush_opened equ +0x1234567d
%else
extern mini_open
extern mini___M_discard_buf
extern mini___M_start_flush_opened
section .text align=1
section .rodata align=1
section .data align=1
section .bss align=1
%endif

section .text
; Input: EAX == junk, EBX == junk, ECX == junk, EDX == junk, ESI == FILE* pointer (.start, .end, .capacity_end already initialized), EDI == junk, EBP == anything.
; Input stack: [esp] == saved EBX, [esp+1*4]: saved ESI, [esp+2*4]: saved EDI, [esp+3*4]: return address, [esp+4*4]: argument pathname, [esp+5*5]: argument mode.
; Output: EAX == result FILE* pointer (or NULL), EBX == restored, ECX == junk, EDX == junk, ESI == restored, EDI == restored, EBP == unchanged.
; Output stack: poped up to and including the return address.
mini___M_jmp_freopen_low:
		mov edx, [esp+5*4]  ; Argument mode.
		mov dl, [edx]
		cmp dl, 'w'
		sete bl  ; is_write?
		xor eax, eax  ; EAX := O_RDONLY.
		cmp dl, 'a'
		sete cl
		or bl, cl
		je .have_flags
		cmp dl, 'a'
		; We may add O_LARGEFILE for opening files >= 2 GiB, but in a different stdio implementation. Without O_LARGEFILE, open(2) fails with EOVERFLOW.
		mov eax, 3101o  ; EAX := O_TRUNC | O_CREAT | O_WRONLY | O_APPEND.
		je .have_flags
		and ah, ~4  ; ~(O_APPEND>>8). EAX := O_TRUNC | O_CREAT | O_WRONLY. 
.have_flags:	; File open flags is now in EAX.
		push dword 666o
		push eax  ; File open flags.
		push dword [esp+6*4]  ; Argument pathname.
		call mini_open
		add esp, byte 0xc  ; Clean up arguments of mini_open(...) from the stack.
		test eax, eax
		jns .open_ok
.error:		xor eax, eax  ; EAX := NULL (return value, indicating error).
		jmp short .done
.open_ok:	cmp bl, 0x1
		sbb edx, edx
		and dl, -0x3
		add dl, 0x4
		mov [esi+0x10], eax
		mov [esi+0x14], dl
		xor eax, eax
		mov dword [esi+0x20], eax  ; .buf_off := 0.
		push esi
		call mini___M_discard_buf
		pop eax  ; Clean up argument of mini___M_discard_buf from the stack.
		xchg eax, esi  ; EAX := ESI (return value); ESI := junk.
.done:		pop ebx
		pop esi
		pop edi
		ret

%ifdef CONFIG_PIC  ; Already position-independent code.
%endif

; __END__
