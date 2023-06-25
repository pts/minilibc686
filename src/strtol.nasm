;
; Written manually and optimized for size, based on looking at c_strtol.c.
; Compile to i386 ELF .o object: nasm -O999999999 -w+orphan-labels -f elf -o strtol.o strtol.nasm
;
; Code+data size: 0xd7 bytes; best with C compiler (c_strtol.c): 0x112 bytes.
;
; Limitation: it doesn't set errno, see c_strtol.c for that.
;
; Uses: %ifdef CONFIG_PIC
; Uses: %ifdef CONFIG_THIS_STRTOUL
;

bits 32
cpu 386

%ifndef CONFIG_THIS_STRTOUL
  %ifndef CONFIG_THIS_STRTOL
    %define CONFIG_THIS_STRTOL  ; Default.
  %endif
%endif

%ifdef CONFIG_THIS_STRTOUL
  global mini_strtoul
%elifdef CONFIG_THIS_STRTOL
  global mini_strtol
%else
  %error Missing CONFIG_THIS_...
  times 1/0 nop
%endif
%ifidn __OUTPUT_FORMAT__, bin
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
%ifdef CONFIG_THIS_STRTOUL
  mini_strtoul:  ; unsigned long strtoul(const char *nptr, char **endptr, int base);
%elifdef CONFIG_THIS_STRTOL
  mini_strtol:  ; long mini_strtol(const char *nptr, char **endptr, int base);
%endif
; Register allocation:
;
; EAX: Scratch for input bytes (`byte [esi]') and digits. After the main loop (.after_loop), it's the (return) value.
; EBX: Usually var_base variable, initial value coming from ARG_BASE. Near the beginning and near the end, scratch for [ARG_ENDPTR].
; ECX: CH is [var_overflow] (0 or 1), CL is a bitfield (var_minus=1, var_at_least_one_digit=2). Other bits are 0.
; EDX: Before the main loop: stratch. During the main loop: the (return) value. After the main loop: scratch.
; ESI: var_p (pointer starting at nptr).
; EDI: var_overflow_limit. After initialization, its value is 0xffffffff / var_base.
; EBP: Unused.
; ESP: Stack pointer. Stack at ESP: (0)saved_EDI (4)saved_ESI (8)saved_EBX (0xc)return_address (0x10)ARG_NPTR (0x14)ARG_ENDPTR (0x18)ARG_BASE.
;
; We dn't make ARG_* ebp+... (rather than esp+...), because the size saving
; (1 byte per use in an effective address) is 0 (push ebp ++ mov ebp, esp ++
; pop ebp == 4 bytes).
%define ARG_NPTR esp+0x10
%define ARG_ENDPTR ARG_NPTR+4
%define ARG_BASE ARG_ENDPTR+4
		push ebx
		push esi
		push edi
		mov esi, [ARG_NPTR]
		mov ebx, [ARG_ENDPTR]
		test ebx, ebx
		jz .endptr_null_1
		mov [ebx], esi
.endptr_null_1:	
.isspace_next:	lodsb
		sub al, 9  ; ASCII 9 is the smallest allowed whitespace.
		cmp al, ' '-9  ; ASCII 32 (space).
		je .isspace_next
		cmp al, 13-9  ; ASCII 9+4 == 13 is the largest allowed non-space whitespace.
		jna .isspace_next
		dec esi
		xor ecx, ecx  ; CH (var_overflow) := 0; CL (var_minus) := 0.
		lodsb
		cmp al, '-'
		jne .not_minus
		inc ecx  ; CL (var_minus) := 1.
		jmp short .after_sign
.not_minus:	cmp al, '+'
		je .after_sign
		dec esi
.after_sign:	mov ebx, [ARG_BASE]
		cmp ebx, byte 16
		je .maybe_base_16
		test ebx, ebx
		jnz .base_nonzero
.maybe_base_16: cmp byte [esi], '0'
		jne .maybe_base_8
		mov al, [esi+1]
		or al, 0x20
		cmp al, 'x'
		jne .maybe_base_8
		inc esi
		inc esi
		mov bl, 16  ; EBX (var_base) := 16.
		jmp short .base_nonzero
.maybe_base_8:	test ebx, ebx
		jnz .base_nonzero
		cmp byte [esi], '0'
		mov bl, 8  ; [var_base] := 8.
		je .base_nonzero
		mov bl, 10  ; [var_base] := 10.
.base_nonzero:  lea eax, [ebx-2]
		cmp eax, byte 36-2
		jbe .base_valid
		xor eax, eax  ; [var_value] := 0, indicating EDOM/EINVAL error.
		jmp short .done
.base_valid:	xor edx, edx
		or eax, byte 0xffffffff  ; EAX := 0xfffffff.
		div ebx  ; EAX := 0xffffffff / EBX (var_base); EDX := junk (remainder).
		xchg eax, edi  ; [var_overflow_limit] := 0xfffffff / [var_base]; EAX := junk.
		xor eax, eax  ; Clear higher bits, AL will contain a single byte below, from [var_p].
		xor edx, edx  ; [var_value] := 0.
.next_digit:	mov al, [esi]  ; Main loop body starts here.
		sub al, '0'
		cmp al, 9
		jbe .good_digit
		add al, '0'
		or al, 0x20  ; Convert to lowercase.
		sub al, 'a'
		cmp al, 26
		jnc short .after_loop  ; Bad digit.
		add al, 10
.good_digit:	cmp eax, ebx
		jnb short .after_loop  ; Jump iff [var_digit] >= [var_base].
.below_digit:	inc esi
		or cl, 2
		cmp edx, edi
		jna .no_overflow_1
		mov ch, 1
.no_overflow_1:	imul edx, ebx  ; [var_value] *= [var_base].
		add edx, eax
		jnc .no_overflow_2
		mov ch, 1
.no_overflow_2: jmp short .next_digit
.after_loop:	test cl, 2
		jz .endptr_null_2
		mov ebx, [ARG_ENDPTR]
		test ebx, ebx
		jz .endptr_null_2
		mov [ebx], esi
.endptr_null_2:	xchg eax, edx  ; EAX := value; EDX := junk. From now on we use EAX as value and EDX as scratch.
		test ch, ch
%ifdef CONFIG_THIS_STRTOUL
		jz .no_overflow
		or eax, byte -1  ; Indicate overflow as saturated 0xffffffff.
%else  ; Signed overflow check.
		jnz .has_overflow
		mov edx, 0x80000000
		cmp eax, edx
		jb .no_overflow
		jne .has_overflow
		test cl, 1  ; [var_minus].
		jnz .no_overflow
.has_overflow:	; Overflow would be indicated by setting errno := ERANGE, but we don't set it, because this libc doesn't support errno.
		xchg eax, edx  ; EAX := 0x80000000; EDX := junk.
		test cl, 1  ; [var_minus].
		jnz .done  ; If negative, indicate overflow (actually underflow) as saturated -0x80000000.
		dec eax  ; If nonnegative, indicate overflow as saturated 0x7fffffff.
%endif
		jmp short .done
.no_overflow:	test cl, 1
		jz .done
		neg eax
.done:		pop edi
		pop esi
		pop ebx
		ret

%ifdef CONFIG_PIC  ; Already position-independent code.
%endif

; __END__
