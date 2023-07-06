;
; optimized manually by pts@fazekas.hu at Wed Jul  5 20:03:44 CEST 2023
; It supports format flags '-', '+', '0', and length modifiers.
; Based on vfprintf_plus.nasm, with stdio_medium buffering added.
; Compile to i386 ELF .o object: nasm -O999999999 -w+orphan-labels -f elf -o stdio_medium_vfprintf.o stdio_medium_vfprintf.nasm
;
; Code+data size: 0x210 bytes (of which long-long support is 0x40 bytes); +1 bytes with CONFIG_PIC.
;
; Uses: %ifdef CONFIG_PIC
; Uses: %ifdef CONFIG_VFPRINTF_IS_FOR_S_PRINTF_ONLY
; Uses: %ifdef CONFIG_VFPRINTF_POP_ESP_BEFORE_RET
; Uses: %ifdef CONFIG_VFPRINTF_NO_PLUS
; Uses: %ifdef CONFIG_VFPRINTF_NO_OCTAL
; Uses: %ifdef CONFIG_VFPRINTF_NO_LONG
; Uses: %ifdef CONFIG_VFPRINTF_NO_LONGLONG
;
; Limitation: Printing `%...c' is incorrect if `...' is not empty and c is '\0'.
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

%ifndef   CONFIG_VFPRINTF_NO_LONGLONG
  %undef  CONFIG_VFPRINTF_NO_LONGS
%elifndef CONFIG_VFPRINTF_NO_LONG
  %undef  CONFIG_VFPRINTF_NO_LONGS
%else
  %define CONFIG_VFPRINTF_NO_LONGS
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
%define SIZEOF_print_buf 24  ; !! TODO(pts): Use less memory (11 or 21 bytes only).
%define VAR_print_buf esp  ; char[24]. 11 would be enough for no-long-long, 21 would be enough for long-long.
%define VAR_b esp+0x18  ; uint32_t.
%define VAR_pad esp+0x1c  ; uint8_t.
%define VAR_neg esp+0x1d  ; uint8_t.
%define VAR_letbase esp+0x1e  ; uint8_t.
%define VAR_c esp+0x1f  ; uint8_t.
%define REG_VAR_formati esi  ; char*.
%define REG_VAR_s ebx  ; char*.
%define REG_VAR_pc ebp  ; uint32_t.
%define REG_VAR_width edi  ; uint32_t.
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
		jmp short .next_fmtchr
.putc_al_cont:
		call .call_mini_putc
.next_fmtchr:
		xor eax, eax  ; Set highest 24 bits of EAX to 0.
		lodsb  ; mov al, [REG_VAR_formati] ++ inc REG_VAR_formati.
		test al, al
%ifdef CONFIG_VFPRINTF_NO_LONGLONG
		jz short .done
%else
		jz short .jdone
%endif
		cmp al, '%'
		jne short .putc_al_cont
		mov byte [VAR_pad], 0
		xor REG_VAR_width, REG_VAR_width
		lodsb  ; mov al, [REG_VAR_formati] ++ inc REG_VAR_formati.
		test al, al
.jdone:
		jz short .done
		cmp al, '%'
		je short .putc_al_cont
		cmp al, '-'
		jne short .2
		mov byte [VAR_pad], PAD_RIGHT
		jmp short .4cont
%ifdef CONFIG_VFPRINTF_NO_PLUS
.4cont:
		lodsb  ; mov al, [REG_VAR_formati] ++ inc REG_VAR_formati.
.2:
%else
.2:
		cmp al, '+'
		jne short .4al
		mov byte [VAR_pad], PAD_PLUS
.4cont:
		lodsb  ; mov al, [REG_VAR_formati] ++ inc REG_VAR_formati.
%endif
.4al:
		cmp al, '0'
		jne short .5al
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
		imul REG_VAR_width, byte 10
		add REG_VAR_width, eax
		jmp short .5cont
.6:
		mov edx, [ARG_ap]
		add dword [ARG_ap], byte 4
		mov ecx, [edx]  ; Next value to print.
%ifndef CONFIG_VFPRINTF_NO_LONGLONG
		xor REG_VAR_s, REG_VAR_s  ; Zero-extend ECX to REG_VAR_s:ECX.
%endif
%ifndef CONFIG_VFPRINTF_NO_LONGS
		cmp al, 'l'
		jne short .try_extend
		lodsb
%endif
%ifndef CONFIG_VFPRINTF_NO_LONGLONG
		cmp al, 'l'
		jne short .try_extend
		lodsb
		add edx, byte 4
		add dword [ARG_ap], byte 4
		mov REG_VAR_s, [edx]  ; High dword of value to print.
		jmp short .done_extend
.try_extend:	cmp al, 'd'
		jne short .done_extend
		; Sign-extend ECX to REG_VAR_s:ECX.
		mov REG_VAR_s, ecx
		sar REG_VAR_s, 31
.done_extend:
%else
.try_extend:
%endif
		cmp al, 's'
		je short .fmtchr_s
		cmp al, 'c'
		jne short .17
		xchg eax, ecx  ; AL := CL; rest of EAX := junk; ECX := junk.
		test REG_VAR_width, REG_VAR_width
%ifdef CONFIG_VFPRINTF_NO_LONGLONG
		jz short .putc_al_cont
%else
		jz near .putc_al_cont
%endif
		mov REG_VAR_s, VAR_print_buf
		mov [REG_VAR_s], ax  ; byte [REG_VAR_s] := AL; byte [REG_VAR_s+1] := 0.
		jmp near .do_print_s

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

.17:
		mov edx, ('a'-'0'-10)<<8 | 10 ; DL := 10; DH := 'a'-'0'-10.
		cmp al, 'd'
		je short .22
		cmp al, 'u'
		je short .22
%ifndef CONFIG_VFPRINTF_NO_OCTAL
		mov dl, 8
		cmp al, 'o'
		je short .22
%endif
		mov dl, 16
		cmp al, 'x'
		je short .22
		mov dh, 'A'-'0'-10
		cmp al, 'X'
		jne short .done  ; Stop on unknown format character.
.22:
		mov [VAR_letbase], dh
		mov dh, 0
		mov [VAR_b], edx
		mov dl, 0
		cmp al, 'd'
		jne short .24
%ifdef CONFIG_VFPRINTF_NO_LONGLONG
		test ecx, ecx
		jge short .23  ; Jump if integer to print is negative.
		mov dl, '-'
		neg ecx
%else  ; Negatve REG_VAR_s:ECX; EAX := junk.
		test REG_VAR_s, REG_VAR_s
		jge short .23  ; Jump if integer to print is negative.
		mov dl, '-'
                xor eax, eax
                neg ecx
                sbb eax, REG_VAR_s
                mov REG_VAR_s, eax
%endif
		jmp short .24

; Putting .fmtchr_s here for the `jmp short .fmtchr_s'.
.fmtchr_s:	mov REG_VAR_s, ecx
		test REG_VAR_s, REG_VAR_s
		jne short .not_null
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
.dpsj:		jmp short .do_print_s

.23:
%ifndef CONFIG_VFPRINTF_NO_PLUS
		test byte [VAR_pad], PAD_PLUS
		je short .24
		mov dl, '+'
%endif
.24:
		mov [VAR_neg], dl
%ifndef CONFIG_VFPRINTF_NO_LONGLONG
		xchg eax, REG_VAR_s  ; Copy highest 32 bits to EAX.
%endif
		xchg eax, ecx  ; EAX := nonnegative integer to print; ECX := (junk or highest 32 bits of nonnegative integer to print).
		lea REG_VAR_s, [VAR_print_buf+SIZEOF_print_buf-1]
		mov byte [REG_VAR_s], 0
.next_digit:

%ifndef CONFIG_VFPRINTF_NO_LONGLONG
; Input: ECX:EAX == uint64_t dividend; dword [VAR_b] == uint32_t divisor.
; Output: ECX:EAX == quotient; EDX == remainder.
		mov edx, ecx
		cmp edx, [VAR_b]
		jnb short .L2
		xor ecx, ecx
		jmp short .L3
.L2:		xchg ecx, eax  ; ECX := EAX (save lowest 32 bits of dividend); EAX := junk.
		xchg eax, edx  ; EAX := EDX; EDX := junk.
		xor edx, edx
		div dword [VAR_b]
		xchg ecx, eax  ; ECX := EAX; EAX := (lowest 32 bits of dividend).
.L3:
		div dword [VAR_b]
		; Result: EDX == ramainder.
%else
; Input: EAX == uint32_t dividend; dword [VAR_b] == uint32_t divisor.
; Output: EAX == quotient; EDX == remainder.
		xor edx, edx
		div dword [VAR_b]
%endif
		cmp dl, 10
		jb short .27
		add dl, [VAR_letbase]
.27:
		add dl, '0'
		dec REG_VAR_s
		mov [REG_VAR_s], dl
		; Now: EAX == quotient.
		test eax, eax
		jnz short .next_digit
		cmp byte [VAR_neg], 0
		je short .do_print_s
		test REG_VAR_width, REG_VAR_width
		jz short .28
		test byte [VAR_pad], PAD_ZERO
		jz short .28
		mov al, [VAR_neg]
		call .call_mini_putc
		dec REG_VAR_width  ; EDI contains the (remaining) width of the current number.
		jmp short short .28j
.28:
		dec REG_VAR_s
		mov al, [VAR_neg]
		mov [REG_VAR_s], al
.28j:		; Fall through to .do_print_s.

.do_print_s:
		mov byte [VAR_c], ' '
		test REG_VAR_width, REG_VAR_width
		jbe short .12
		xor edx, edx
		mov ecx, REG_VAR_s
.8:
		cmp byte [ecx], 0
		je short .9
		inc edx
		inc ecx
		jmp short short .8
.9:
		cmp edx, REG_VAR_width
		jb short .10
		xor REG_VAR_width, REG_VAR_width
		jmp short .11
.10:
		sub REG_VAR_width, edx
.11:
		test byte [VAR_pad], PAD_ZERO
		je short .12
		mov byte [VAR_c], '0'
.12:
		test byte [VAR_pad], PAD_RIGHT
		jne short .14
.13:
		test REG_VAR_width, REG_VAR_width
		jbe short .14
		mov al, [VAR_c]
		call .call_mini_putc
		dec REG_VAR_width
		jmp short .13
.14:
		mov al, [REG_VAR_s]
		test al, al
		je short .15
		call .call_mini_putc
		inc REG_VAR_s
		jmp short .14
.15:
		test REG_VAR_width, REG_VAR_width
		jbe near .next_fmtchr
		mov al, [VAR_c]
		call .call_mini_putc
		dec REG_VAR_width
		jmp short .15
		; End of .do_print_s. It has already jumped to .next_fmtchr.

.call_mini_putc:  ; Input: AL contains the byte to be printed. Can use EAX, EDX and ECX as scratch. Output: byte is written to the buffer, REG_VAR_pc is incremented on success only.
		mov edx, [4+ARG_filep]  ; filep. (`4+' because of the return pointer of .call_mini_putc.)  AL contains the byte to be printed, the high 24 bits of EAX is garbage here.
		; Now we do inlined putc(c, filep). Memory layout must match <stdio.h> and c_stdio_medium.c.
		; int putc(int c, FILE *filep) { return (((char**)filep)[0]/*->buf_write_ptr*/ == ((char**)filep)[1]/*->buf_end*/) || (_STDIO_SUPPORTS_LINE_BUFFERING && (unsigned char)c == '\n') ? mini_fputc_RP3(c, filep) : (unsigned char)(*((char**)filep)[0]/*->buf_write_ptr*/++ = c); }
		mov ecx, [edx]  ; ECX := buf_write_ptr.
		cmp ecx, [edx+4]  ; buf_end.
		je short .call_mini_fputc
%ifndef CONFIG_VFPRINTF_IS_FOR_S_PRINTF_ONLY
		cmp al, 10  ; '\n'.
		je short .call_mini_fputc  ; In case filep == stdout and it's line buffered (_IOLBF).
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
		jne short .not_saturate
		cmp ecx, [edx+4]  ; buf_end.
		je short .after_putc
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
