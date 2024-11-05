;
; stdio_medium_simple_vfprintf.nasm: a very simple (%s, %c, %u) vfprintf implementation
; Compile to i386 ELF .o object: nasm -O999999999 -w+orphan-labels -f elf -o stdio_medium_simplevfprintf.o stdio_medium_simplevfprintf.nasm
;
; Code+data size: ?? bytes.
;
; Limitation: It supports only format specifiers %s, %c, %u.
; Limitation: It doesn't work as a backend of snprintf(...) and vsnprintf(...) because it doesn't support FD_WRITE_SATURATE.
; Limitation: It doesn't return the number of bytes printed, it doesn't indicate error.
;

bits 32
cpu 386

global mini_vfprintf_simple
%ifidn __OUTPUT_FORMAT__, bin
section .text align=1
section .rodata align=1
section .data align=1
section .bss align=1
mini_fputc_RP3 equ $+0x12345678
mini___M_writebuf_relax_RP1 equ $+0x12345678
mini___M_writebuf_unrelax_RP1 equ $+0x1234567a
%else
section .text align=1
section .rodata align=1
section .data align=1
section .bss align=1
extern mini_fputc_RP3
extern mini___M_writebuf_relax_RP1
extern mini___M_writebuf_unrelax_RP1
%endif

section .text
mini_vfprintf_simple:  ; void mini_vfprintf_simple(FILE *filep, const char *format, va_list ap);
		push ebx  ; Save.
		push esi  ; Save.
		push edi  ; Save.
		sub esp, strict byte 12  ; Scratch buffer for %u.
		push strict byte 10  ; Divisor `div' below.
		mov eax, [esp+8*4]  ; filep.
		call mini___M_writebuf_relax_RP1  ; mini___M_writebuf_relax_RP1(filep); Subsequent bytes written will be buffered until mini___M_writebuf_relax_RP1 below.
		mov esi, [esp+9*4]  ; format.
		mov edi, [esp+10*4]  ; ap.
.next_fmt_char:	lodsb
		cmp al, '%'
		je strict short .specifier
		cmp al, 0
		je strict short .done
.write_char:	call .call_mini_putc
		jmp strict .next_fmt_char
.done:		mov eax, [esp+8*4]  ; filep.
		call mini___M_writebuf_unrelax_RP1  ; mini___M_writebuf_unrelax_RP1(filep);
		add esp, strict byte 16
		pop edi  ; Restore.
		pop esi  ; Restore.
		pop ebx  ; Restore.
		ret
.specifier:	lodsb
		cmp al, 's'
		je strict short .specifier_s
		cmp al, 'u'
		je strict short .specifier_u
		cmp al, 'c'
		jne strict short .write_char
		; Fall through.
.specifier_c:	mov al, [edi]
		add edi, strict byte 4
		jmp strict short .write_char
.specifier_s:	mov ebx, [edi]  ; EDI := start of NUL-terminated string.
.next_str_char:	mov al, [ebx]
		inc ebx
		cmp al, 0
		je strict short .done_str
		call .call_mini_putc
		jmp strict short .next_str_char
.done_str:	add edi, strict byte 4
		jmp strict short .next_fmt_char
.specifier_u:	lea ebx, [esp+4+12-1]  ; Last byte of the scratch buffer for %u.
		mov byte [ebx], 0  ; Trailing NUL.
		mov eax, [edi]
.next_digit:	xor edx, edx  ; Set high dword of the dividend. Low dword is in EAX.
		div dword [esp]  ; Divide by 10.
		add dl, '0'
		dec ebx
		mov [ebx], dl
		test eax, eax  ; Put next digit to the scratch buffer.
		jnz strict short .next_digit
		jmp strict short .next_str_char
.call_mini_putc:  ; Input: AL contains the byte to be printed. Can use EAX, EDX and ECX as scratch. Output: byte is written to the buffer.
		mov edx, [esp+8*4+4]  ; filep. (`4+' because of the return pointer of .call_mini_putc.)  AL contains the byte to be printed, the high 24 bits of EAX is garbage here.
		; Now we do inlined putc(c, filep). Memory layout must match <stdio.h> and c_stdio_medium.c.
		; int putc(int c, FILE *filep) { return (((char**)filep)[0]/*->buf_write_ptr*/ == ((char**)filep)[1]/*->buf_end*/) || (_STDIO_SUPPORTS_LINE_BUFFERING && (unsigned char)c == '\n') ? mini_fputc_RP3(c, filep) : (unsigned char)(*((char**)filep)[0]/*->buf_write_ptr*/++ = c); }
		mov ecx, [edx]  ; ECX := buf_write_ptr.
		cmp ecx, [edx+4]  ; buf_end.
		je short .call_mini_fputc
		cmp al, 10  ; '\n'.
		je short .call_mini_fputc  ; In case filep == stdout and it's line buffered (_IOLBF).
		mov [ecx], al  ; *buf_write_ptr := AL.
		inc dword [edx]  ; buf_write_ptr += 1.
		ret
.call_mini_fputc:
		; movsx eax, al : Not needed, mini_fputc ignores the high 24 bits anyway.
		call mini_fputc_RP3  ; With extra smart linking, we could hardcore an EOF (-1) return if only mini_snprintf(...) etc., bur no mini_fprintf(...) etc. is used.
		ret
		
%ifdef CONFIG_PIC  ; Already position-independent code.
%endif

; __END__
