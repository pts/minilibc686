;
; Manually optimized for size based on the output of soptcc.pl for c_stdio_medium_fputc_rp2.c
; Compile to i386 ELF .o object: nasm -O999999999 -w+orphan-labels -f elf -o c_stdio_medium_fputc_rp2.o c_stdio_medium_fputc_rp2.nasm

bits 32
cpu 386

global mini___M_fputc_RP2
%ifdef CONFIG_SECTIONS_DEFINED
%elifidn __OUTPUT_FORMAT__, bin
section .text align=1
section .rodata align=1
section .data align=1
section .bss align=1
mini_write equ +0x12345678
mini_fflush equ +0x12345679
%else
extern mini_write
extern mini_fflush
section .text align=1
section .rodata align=1
section .data align=4
section .bss align=4
%endif

section .text

mini___M_fputc_RP2:  ; int REGPARM2 mini___M_fputc_RP2(int c, FILE *filep);
		push ebx  ; Save EBX.
		mov ebx, edx
		push eax  ; Make room for local variable uc on the stack and set the lower 8 bits to c and the higher bits to junk.
		mov eax, [edx+0x4]
		cmp [edx], eax
		jne .16
		push edx
		call mini_fflush
		pop edx
		test eax, eax
		je .17
.20:		or eax, byte -0x1
		jmp short .done
.17:		mov eax, [ebx+0x4]
		cmp [ebx], eax
		jne .16
		mov eax, esp  ; Address of local variable uc.
		push byte 1
		push eax
		push dword [ebx+0x10]
		call mini_write
		add esp, byte 0xc
		dec eax
		jne .20
		inc dword [ebx+0x20]
.16:		mov edx, [ebx]
		inc edx
		mov [ebx], edx
		dec edx
		movzx eax, byte [esp]  ; Local variable uc.
		mov [edx], al
		cmp al, 0xa  ; Local variable uc.
		jne .done
		cmp byte [ebx+0x14], 0x6  ; FD_WRITE_LINEBUF.
		jne .done
		push eax  ; Save EAX (return value).
		push ebx
		call mini_fflush
		pop edx  ; Clean up the argument of mini_fflush from the stack. The pop register can be any of: EBX, ECX, EDX, ESI, EDI, EBP.
		pop eax  ; Restore EAX (return value).
.done:		pop edx  ; Remove local variable uc from the stack.
		pop ebx  ; Restore EBX.
		ret

%ifdef CONFIG_PIC  ; Already position-independent code.
%endif

; __END__
