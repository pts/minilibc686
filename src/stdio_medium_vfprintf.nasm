;
; It supports format flags '-', '+', '0', and length modifiers.
; Based on vfprintf_plus.nasm, with stdio_medium buffering added.
; Compile to i386 ELF .o object: nasm -O999999999 -w+orphan-labels -f elf -o stdio_medium_vfprintf.o stdio_medium_vfprintf.nasm
;
; Code+data size: 0x247 bytes; 0x248 bytes with CONFIG_PIC.
;
; Uses: %ifdef CONFIG_PIC
; Uses; %ifdef CONFIG_VFPRINTF_IS_FOR_S_PRINTF_ONLY
; Uses; %ifdef CONFIG_VFPRINTF_POP_ESP_BEFORE_RET
;

bits 32
cpu 386

%ifdef __NEED_mini___M_vfsprintf
  %define CONFIG_VFPRINTF_IS_FOR_S_PRINTF_ONLY
  %define mini_vfprintf mini___M_vfsprintf
%else
  %undef  CONFIG_VFPRINTF_IS_FOR_S_PRINTF_ONLY
  %undef  mini_vfprintf
%endif

%ifndef CONFIG_VFPRINTF_POP_ESP_BEFORE_RET
global mini_vfprintf
%endif

%ifdef CONFIG_SECTIONS_DEFINED
%elifidn __OUTPUT_FORMAT__, bin
section .text align=1
section .rodata align=1
section .data align=1
section .bss align=1
%else
section .text align=1
section .rodata align=1
section .data align=4
section .bss align=4
%endif

%ifndef CONFIG_VFPRINTF_IS_FOR_S_PRINTF_ONLY
  %ifidn __OUTPUT_FORMAT__, bin
    %ifndef UNDEFSYMS
      mini_fputc_RP3 equ $+0x12345678
      mini___M_writebuf_relax_RP1 equ $+0x12345679
      mini___M_writebuf_unrelax_RP1 equ $+0x1234567a
    %endif
  %else
    extern mini_fputc_RP3
    extern mini___M_writebuf_relax_RP1
    extern mini___M_writebuf_unrelax_RP1
  %endif
%endif

section .text
%ifndef CONFIG_VFPRINTF_POP_ESP_BEFORE_RET
mini_vfprintf:  ; int mini_vfprintf(FILE *filep, const char *format, va_list ap);
%endif
		push ebx
		push esi
		push edi
		push ebp
		sub esp, byte 0x20
%ifndef CONFIG_VFPRINTF_IS_FOR_S_PRINTF_ONLY
		mov eax, [esp+0x34]  ; filep.
		call mini___M_writebuf_relax_RP1  ; mini___M_writebuf_relax_RP1(filep); Subsequent bytes written will be buffered until mini___M_writebuf_relax_RP1 below.
%endif
		mov ebx, [esp+0x38]  ; EBX := format.
		xor ebp, ebp
.1:
		mov al, [ebx]
		test al, al
		je near .33
		cmp al, 0x25
		jne near .30
		xor eax, eax
		mov [esp+0x10], eax
		xor edi, edi
		inc ebx
		mov al, [ebx]
		test al, al
		je near .33
		cmp al, 0x25
		je near .30
		lea edx, [ebx+0x1]
		cmp al, 0x2d
		jne .2
		mov dword [esp+0x10], 0x1
		jmp short .3
.2:
		cmp al, 0x2b
		jne .4
		mov dword [esp+0x10], 0x4
.3:
		mov ebx, edx
.4:
		cmp byte [ebx], 0x30
		jne .5
		or byte [esp+0x10], 0x2
		inc ebx
		jmp short .4
.5:
		xor eax, eax
.5cont:
		mov al, [ebx]
		sub al, '0'
		jl short .6
		cmp al, 9
		jg short .6
		imul edi, byte 0xa
		add edi, eax
		inc ebx
		jmp short .5cont
.6:
		mov al, [ebx]
		mov esi, esp
		mov ecx, [esp+0x3c]
		add ecx, byte 0x4
		cmp al, 0x73
		jne .16
		mov [esp+0x3c], ecx
		mov esi, [ecx-0x4]
		test esi, esi
		jne .7
%ifdef CONFIG_PIC
		call .after_str_null
.str_null:
		; This is also valid i386 machine code:
		; db '(nu'  ;  sub [esi+0x75], ch
		; db 'l'  ; insb
		; db 'l'  ; insb
		; db ')', 0  ; sub [eax], eax
		db '(null)', 0
.after_str_null:
		pop esi  ; ESI := &.str_null.
%else  ; CONFIG_PIC
		mov esi, str_null
%endif  ; CONFIG_PIC
.7:
		mov byte [esp+0x1c], 0x20
		test edi, edi
		jbe .12
		xor edx, edx
		mov ecx, esi
.8:
		cmp byte [ecx], 0x0
		je .9
		inc edx
		inc ecx
		jmp short .8
.9:
		cmp edx, edi
		jb .10
		xor edi, edi
		jmp short .11
.10:
		sub edi, edx
.11:
		test byte [esp+0x10], 0x2
		je .12
		mov byte [esp+0x1c], 0x30
.12:
		test byte [esp+0x10], 0x1
		jne .14
.13:
		test edi, edi
		jbe .14
		mov al, byte [esp+0x1c]
		call .call_mini_putc
		dec edi
		jmp short .13
.14:
		mov al, [esi]
		test al, al
		je .15
		call .call_mini_putc
		inc esi
		jmp short .14
.15:
		test edi, edi
		jbe near .32
		mov al, byte [esp+0x1c]
		call .call_mini_putc
		dec edi
		jmp short .15
.16:
		cmp al, 0x63
		jne .17
		mov [esp+0x3c], ecx
		mov al, [ecx-0x4]
		mov [esp], al
		test edi, edi
		je near .31
		mov byte [esp+0x1], 0x0
		jmp near .7
.17:
		mov [esp+0x3c], ecx
		mov ecx, [ecx-0x4]
		cmp al, 0x64
		je .18
		cmp al, 0x75
		je .18
		mov dl, al
		or dl, 0x20
		cmp dl, 0x78
		jne near .33
.18:
		mov dl, al
		or dl, 0x20
		cmp dl, 0x78
		jne .19
		mov edx, 0x10
		jmp short .20
.19:
		mov edx, 0xa
.20:
		mov [esp+0xc], edx
		cmp al, 0x58
		jne .21
		mov edx, 0x41
		jmp short .22
.21:
		mov edx, 0x61
.22:
		sub edx, byte 0x3a
		mov [esp+0x18], dl
		cmp al, 0x64
		jne .23
		cmp dword [esp+0xc], byte 0xa
		jne .23
		test ecx, ecx
		jge .23
		mov byte [esp+0x14], 0x2d
		neg ecx
		jmp short .25
.23:
		test byte [esp+0x10], 0x4
		je .24
		mov byte [esp+0x14], 0x2b
		jmp short .25
.24:
		mov byte [esp+0x14], 0x0
.25:
		lea esi, [esp+0xa]
		mov byte [esi], 0x0
		xchg eax, ecx  ; EAX := positive number to print; ECX := junk.
.26:
		xor edx, edx
		div dword [esp+0xc]
		xchg eax, edx  ; EAX := remainder; EDX := quotient.
		cmp al, 10
		jb .27
		add al, [esp+0x18]
.27:
		add al, 0x30
		dec esi
		mov [esi], al
		xchg edx, eax  ; Ater this: EAX == quotient.
		test eax, eax
		jnz .26
		cmp byte [esp+0x14], 0x0
		je .7
		test edi, edi
		jz .28
		test byte [esp+0x10], 0x2
		jz .28
		mov al, byte [esp+0x14]
		call .call_mini_putc
		dec edi  ; EDI contains the (remaining) width of the current number.
.jmp7:		jmp near .7
.28:
		dec esi
		mov al, [esp+0x14]
		mov [esi], al
		jmp short .jmp7
.30:
		mov al, byte [ebx]
.31:
		call .call_mini_putc
.32:
		inc ebx  ; TODO(pts): Swap the role of EBX and ESI, and use lodsb.
		jmp near .1
.33:
%ifndef CONFIG_VFPRINTF_IS_FOR_S_PRINTF_ONLY
		mov eax, [esp+0x34]  ; filep.
		call mini___M_writebuf_unrelax_RP1  ; mini___M_writebuf_unrelax_RP1(filep);
%endif
		xchg eax, ebp  ; EAX := number of bytes written; EBP := junk.
		add esp, byte 0x20
		pop ebp
		pop edi
		pop esi
		pop ebx
%ifdef CONFIG_VFPRINTF_POP_ESP_BEFORE_RET
		pop esp
%endif
		ret
.call_mini_putc:  ; Input: AL contains the byte to be printed. Can use EAX, EDX and ECX as scratch. Output: byte is written to the buffer, EBP is incremented on success only.
		mov edx, [esp+0x38]  ; filep. AL contains the byte to be printed, the high 24 bits of EAX is garbage here.
		; Now we do inlined putc(c, filep). Memory layout must match <stdio.h> and c_stdio_medium.c.
		; int putc(int c, FILE *filep) { return (((char**)filep)[0]/*->buf_write_ptr*/ == ((char**)filep)[1]/*->buf_end*/) || (_STDIO_SUPPORTS_LINE_BUFFERING && (unsigned char)c == '\n') ? mini_fputc_RP3(c, filep) : (unsigned char)(*((char**)filep)[0]/*->buf_write_ptr*/++ = c); }
		mov ecx, [edx]  ; ECX := buf_write_ptr.
		cmp ecx, [edx+4]  ; buf_end.
		je .call_mini_fputc
%ifndef CONFIG_VFPRINTF_IS_FOR_S_PRINTF_ONLY
		cmp al, 10  ; '\n'.
		je .call_mini_fputc  ; In case filep == stdout and it's line buffered (_IOLBF).
%endif
.append_byte:
%if 1  ; With smart linking, exclude this if mini_snprintf(...) and mini_vsnprintf(...) are not used. !! Maybe ensure that it's not NULL here.
		test ecx, ecx  ; if buf_write_ptr is NULL, then don't write the AL byte, but still increment the counter in EBP. This is for mini_snprintf(...).
		jz .after_putc
%endif
		mov [ecx], al  ; *buf_write_ptr := AL.
		inc dword [edx]  ; buf_write_ptr += 1.
%ifdef CONFIG_VFPRINTF_IS_FOR_S_PRINTF_ONLY
.call_mini_fputc:  ; Assumes dire == FD_WRITE_SATURATE.
.after_putc:	inc ebp
		ret
%else
.after_putc:	inc ebp  ; Increment EBP on success (as per .call_mini_putc contract).
		ret
.call_mini_fputc:
%if 1  ; TODO(pts): With smart linking, exclude this if mini_snprintf(...) and mini_vsnprintf(...) are not used.
		cmp byte [edx+0x14], 7  ; dire == FD_WRITE_SATURATE?
		jne .not_saturate
		cmp ecx, [edx+4]  ; buf_end.
		je .after_putc
		jmp short .append_byte
.not_saturate:
%endif
		; movsx eax, al : Not needed, mini_fputc ignores the high 24 bits anyway.
		call mini_fputc_RP3  ; With extra smart linking, we could hardcore an EOF (-1) return if only mini_snprintf(...) etc., bur no mini_fprintf(...) etc. is used.
		add eax, byte 1  ; CF := (EAX != 1).
		sbb ebp, byte -1  ; If EAX wasn't -1 (EOF), then EBP += 1.
		ret
%endif  ; else CONFIG_VFPRINTF_IS_FOR_S_PRINTF_ONLY
		
%ifndef CONFIG_PIC
section .rodata
str_null:
		db '(null)', 0
%endif

%undef mini_vfprintf

; __END__
