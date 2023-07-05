;
; optimized manually by pts@fazekas.hu at Wed Jul  5 20:03:44 CEST 2023
; It supports format flags '-', '+', '0', and length modifiers.
; Based on vfprintf_plus.nasm, with stdio_medium buffering added.
; Compile to i386 ELF .o object: nasm -O999999999 -w+orphan-labels -f elf -o stdio_medium_vfprintf.o stdio_medium_vfprintf.nasm
;
; Code+data size: 0x223 bytes; +1 bytes with CONFIG_PIC.
;
; Uses: %ifdef CONFIG_PIC
; Uses; %ifdef CONFIG_VFPRINTF_IS_FOR_S_PRINTF_ONLY
; Uses; %ifdef CONFIG_VFPRINTF_POP_ESP_BEFORE_RET
;
; TODO(pts): Add support for %p.
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
section .data align=1
section .bss align=1
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

PAD_RIGHT equ 1
PAD_ZERO equ 2
PAD_PLUS equ 4
%define SIZEOF_print_buf 11
%define VAR_print_buf esp  ; char[11].
%define VAR_b esp+0xc  ; uint32_t.
%define VAR_pad esp+0x10  ; uint8_t.
%define VAR_neg esp+0x14  ; uint8_t.
%define VAR_letbase esp+0x18  ; uint8_t.
%define VAR_c esp+0x1c  ; uint8_t.
%define REG_VAR_formati esi  ; char*.
%define REG_VAR_s ebx  ; char*.
%define REG_VAR_pc ebp  ; uint32_t.
%define ARG_filep esp+0x34  ; FILE*.
%define ARG_format esp+0x38  ; const char*.
%define ARG_ap esp+0x3c  ; va_list (32-bit). Will be modified in place, the calling convention allows it.

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
		mov eax, [ARG_filep]  ; filep.
		call mini___M_writebuf_relax_RP1  ; mini___M_writebuf_relax_RP1(filep); Subsequent bytes written will be buffered until mini___M_writebuf_relax_RP1 below.
%endif
		mov REG_VAR_formati, [ARG_format]  ; REG_VAR_formati := format.
		xor REG_VAR_pc, REG_VAR_pc
		jmp short .next_format_byte
.putc_al_cont:
		call .call_mini_putc
.next_format_byte:
		xor eax, eax  ; Set highest 24 bits of EAX to 0.
		lodsb  ; mov al, [REG_VAR_formati] ++ inc REG_VAR_formati.
		test al, al
		jz near .done
		cmp al, '%'
		jne short .putc_al_cont
		mov byte [VAR_pad], 0
		xor edi, edi
		lodsb  ; mov al, [REG_VAR_formati] ++ inc REG_VAR_formati.
		test al, al
		jz near .done  ; !! Optimize all near jumps.
		cmp al, '%'
		je short .putc_al_cont
		cmp al, '-'
		jne .2
		mov byte [VAR_pad], PAD_RIGHT
		jmp short .4cont
.2:
		cmp al, '+'  ; !! Make this conditional (CONFIG_VFPRINTF_NO_PLUS) and also others.
		jne .4al
		mov byte [VAR_pad], PAD_PLUS
.4cont:
		lodsb  ; mov al, [REG_VAR_formati] ++ inc REG_VAR_formati.
.4al:
		cmp al, '0'
		jne .5al
		or byte [VAR_pad], PAD_ZERO
		jmp short .4cont
.5cont:
		lodsb  ; mov al, [REG_VAR_formati] ++ inc REG_VAR_formati.
.5al:
		cmp al, '0'
		jl short .6
		cmp al, '9'
		jg short .6
		sub al, '0'
		imul edi, byte 10
		add edi, eax
		jmp short .5cont
.6:
		mov REG_VAR_s, VAR_print_buf
		mov ecx, [ARG_ap]
		add ecx, byte 0x4
		cmp al, 's'
		jne .16
		mov [ARG_ap], ecx
		mov REG_VAR_s, [ecx-0x4]
		test REG_VAR_s, REG_VAR_s
		jne .not_null
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
		pop REG_VAR_s  ; ESI := &.str_null.
%else  ; CONFIG_PIC
		mov REG_VAR_s, str_null
%endif  ; CONFIG_PIC
.not_null:
.do_print_s:
		mov byte [VAR_c], ' '
		test edi, edi
		jbe .12
		xor edx, edx
		mov ecx, REG_VAR_s
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
		test byte [VAR_pad], PAD_ZERO
		je .12
		mov byte [VAR_c], '0'
.12:
		test byte [VAR_pad], PAD_RIGHT
		jne .14
.13:
		test edi, edi
		jbe .14
		mov al, [VAR_c]
		call .call_mini_putc
		dec edi
		jmp short .13
.14:
		mov al, [REG_VAR_s]
		test al, al
		je .15
		call .call_mini_putc
		inc REG_VAR_s
		jmp short .14
.15:
		test edi, edi
		jbe .next_format_byte
		mov al, [VAR_c]
		call .call_mini_putc
		dec edi
		jmp short .15
.16:
		cmp al, 'c'
		jne .17
		mov [ARG_ap], ecx
		mov al, [ecx-0x4]
		test edi, edi
		jz near .putc_al_cont
		mov [VAR_print_buf], al
		mov byte [VAR_print_buf+1], 0x0
		jmp near .do_print_s
.17:
		mov [ARG_ap], ecx
		mov ecx, [ecx-0x4]
		cmp al, 0x64
		je .18
		cmp al, 0x75
		je .18
		mov dl, al
		or dl, 0x20
		cmp dl, 'x'
		jne near .done
.18:
		mov dl, al
		or dl, 0x20
		cmp dl, 'x'
		jne .19
		mov edx, 0x10
		jmp short .20
.19:
		mov edx, 0xa
.20:
		mov [VAR_b], edx
		cmp al, 0x58
		jne .21
		mov edx, 'A'
		jmp short .22
.21:
		mov edx, 'a'  ; !! TODO(pts): `or dl, 0x20'.
.22:
		sub edx, byte '0'+10
		mov [VAR_letbase], dl
		cmp al, 'd'
		jne .23
		cmp dword [VAR_b], byte 10
		jne .23
		test ecx, ecx
		jge .23
		mov byte [VAR_neg], '-'
		neg ecx
		jmp short .25
.23:
		test byte [VAR_pad], PAD_PLUS
		je .24
		mov byte [VAR_neg], '+'
		jmp short .25
.24:
		mov byte [VAR_neg], 0
.25:
		lea REG_VAR_s, [VAR_print_buf+SIZEOF_print_buf-1]
		mov byte [REG_VAR_s], 0
		xchg eax, ecx  ; EAX := positive number to print; ECX := junk.
.26:
		xor edx, edx
		div dword [VAR_b]
		xchg eax, edx  ; EAX := remainder; EDX := quotient.
		cmp al, 10
		jb .27
		add al, [VAR_letbase]
.27:
		add al, '0'
		dec REG_VAR_s
		mov [REG_VAR_s], al
		xchg edx, eax  ; After this: EAX == quotient.
		test eax, eax
		jnz .26
		cmp byte [VAR_neg], 0
		je near .do_print_s
		test edi, edi
		jz .28
		test byte [VAR_pad], PAD_ZERO
		jz .28
		mov al, [VAR_neg]
		call .call_mini_putc
		dec edi  ; EDI contains the (remaining) width of the current number.
		jmp short .28j
.28:
		dec REG_VAR_s
		mov al, [VAR_neg]
		mov [REG_VAR_s], al
.28j:		jmp near .do_print_s
.done:
%ifndef CONFIG_VFPRINTF_IS_FOR_S_PRINTF_ONLY
		mov eax, [ARG_filep]  ; filep.
		call mini___M_writebuf_unrelax_RP1  ; mini___M_writebuf_unrelax_RP1(filep);
%endif
		xchg eax, REG_VAR_pc  ; EAX := number of bytes written; REG_VAR_pc := junk.
		add esp, byte 0x20
		pop ebp
		pop edi
		pop esi
		pop ebx
%ifdef CONFIG_VFPRINTF_POP_ESP_BEFORE_RET
		pop esp
%endif
		ret
.call_mini_putc:  ; Input: AL contains the byte to be printed. Can use EAX, EDX and ECX as scratch. Output: byte is written to the buffer, REG_VAR_pc is incremented on success only.
		mov edx, [4+ARG_filep]  ; filep. (`4+' because of the return pointer of .call_mini_putc.)  AL contains the byte to be printed, the high 24 bits of EAX is garbage here.
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
		mov [ecx], al  ; *buf_write_ptr := AL.
		inc dword [edx]  ; buf_write_ptr += 1.
%ifdef CONFIG_VFPRINTF_IS_FOR_S_PRINTF_ONLY
.call_mini_fputc:  ; Assumes dire == FD_WRITE_SATURATE.
.after_putc:	inc REG_VAR_pc
		ret
%else
.after_putc:	inc REG_VAR_pc  ; Increment REG_VAR_pc on success (as per .call_mini_putc contract).
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
		sbb REG_VAR_pc, byte -1  ; If EAX wasn't -1 (EOF), then REG_VAR_pc += 1.
		ret
%endif  ; else CONFIG_VFPRINTF_IS_FOR_S_PRINTF_ONLY
		
%ifndef CONFIG_PIC
section .rodata
str_null:
		db '(null)', 0
%endif

%undef mini_vfprintf

; __END__
