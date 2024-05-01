;
; Manually optimized for size based on the output of soptcc.pl for c_stdio_medium_fputc_rp2.c
; Compile to i386 ELF .o object: nasm -O999999999 -w+orphan-labels -f elf -o c_stdio_medium_fputc_rp2.o c_stdio_medium_fputc_rp2.nasm

bits 32
cpu 386

global mini_fputc_RP3
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

mini_fputc_RP3:  ; int REGPARM3 mini_fputc_RP3(int c, FILE *filep);
; #define _STDIO_SUPPORTS_EMPTY_BUFFERS 1
; int mini_fputc_calling_fwrite(int c, FILE *filep) {
;   const unsigned char uc = c;
;   if (filep->buf_write_ptr == filep->buf_end) {
;     if (mini_fflush(filep)) return EOF;  /* Also returns EOF if !IS_FD_ANY_WRITE(filep->dire). Good, because we don't want to write. */
;     if (_STDIO_SUPPORTS_EMPTY_BUFFERS && filep->buf_write_ptr == filep->buf_end) {
;       return mini_write(filep->fd, &uc, 1) == 1 ? uc : EOF;
;     }
;   }
;   *filep->buf_write_ptr++ = uc;
;   if (uc == '\n' && filep->dire == FD_WRITE_LINEBUF) mini_fflush(filep);
;   return uc;
; }
		push ebx  ; Save EBX.
		mov ebx, edx
		movzx eax, al  ; Local variable uc will become argument c.
		push eax  ; Make room for local variable uc on the stack and set the lower 8 bits to c and the higher bits to junk.
		mov eax, [edx+0x4]
		cmp [edx], eax
		jne .16
		push edx
		call mini_fflush
		pop edx
		test eax, eax
		je .17
.20:		pop eax
		push byte -1  ; Return value := -1.
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
		jnz .20
		jmp short .done
.16:		mov edx, [ebx]
		inc edx
		mov [ebx], edx  ; ++filep->buf_write_ptr++;
		dec edx
		pop eax  ; Local variable uc.
		push eax
		mov [edx], al
		cmp al, 0xa  ; Local variable uc.
		jne .done
		cmp byte [ebx+0x14], 0x6  ; FD_WRITE_LINEBUF.
		jne .done
		push ebx
		call mini_fflush
		pop edx  ; Clean up the argument of mini_fflush from the stack. The pop register can be any of: EBX, ECX, EDX, ESI, EDI, EBP.
.done:		pop eax  ; Remove zero-extended local variable uc from the stack, and use it as return value.
		pop ebx  ; Restore EBX.
		ret

%ifdef CONFIG_PIC  ; Already position-independent code.
%endif

; __END__
