;
; Written manually and optimized for size, based on looking at c_strtol.c.
; Compile to i386 ELF .o object: nasm -O999999999 -w+orphan-labels -f elf -o strtol.o strtol.nasm
;
; Code size: 0xd7 bytes for mini_strtol(...); best with C compiler (c_strtol.c): 0x112 bytes.
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
    %ifndef CONFIG_THIS_STRTOULL
      %ifndef CONFIG_THIS_STRTOLL
        %define CONFIG_THIS_STRTOL  ; Default.
      %endif
    %endif
  %endif
%endif

%undef CONFIG_STRTOL_64BIT
%undef CONFIG_STRTOL_UNSIGNED
%ifdef CONFIG_THIS_STRTOUL
  %define CONFIG_STRTOL_UNSIGNED
  global mini_strtoul
%elifdef CONFIG_THIS_STRTOL
  global mini_strtol
%elifdef CONFIG_THIS_STRTOULL
  %define CONFIG_STRTOL_UNSIGNED
  %define CONFIG_STRTOL_64BIT
  global mini_strtoull
%elifdef CONFIG_THIS_STRTOLL
  %define CONFIG_STRTOL_64BIT
  global mini_strtoll
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
section .rodata align=1
section .data align=1
section .bss align=1
%endif

section .text
%ifdef CONFIG_THIS_STRTOUL
  mini_strtoul:  ; unsigned long strtoul(const char *nptr, char **endptr, int base);
%elifdef CONFIG_THIS_STRTOL
  mini_strtol:  ; long mini_strtol(const char *nptr, char **endptr, int base);
%elifdef CONFIG_THIS_STRTOULL
  mini_strtoull:  ; unsigned long long strtoull(const char *nptr, char **endptr, int base);
%elifdef CONFIG_THIS_STRTOLL
  mini_strtoll:  ; long long mini_strtol(const char *nptr, char **endptr, int base);
%endif
; Register allocation:
;
; EAX: Scratch for input bytes (`byte [esi]') and digits. After the main loop (.after_loop), it's the (return) value.
; EBX: Usually var_base variable, initial value coming from ARG_BASE. Near the beginning and near the end, scratch for [ARG_ENDPTR].
; ECX: CH is [var_overflow] (0 or 1), CL is a bitfield (var_minus=1, var_at_least_one_digit=2). Other bits are 0.
; EDX: Before the main loop: stratch. During the main loop: the (return) value. After the main loop: scratch.
; ESI: var_p (pointer starting at nptr).
; EDI: var_overflow_limit. After initialization, its value is 0xffffffff / var_base.
; EBP: During the main loop: high 64 bits of the (return) value.
; ESP: Stack pointer. Stack at ESP: (0)saved_EDI (4)saved_ESI (8)saved_EBX (0xc)return_address (0x10)ARG_NPTR (0x14)ARG_ENDPTR (0x18)ARG_BASE.
;
; We don't make ARG_* ebp+... (rather than esp+...), because the size saving
; (1 byte per use in an effective address) is 0 (push ebp ++ mov ebp, esp ++
; pop ebp == 4 bytes).
%ifdef CONFIG_STRTOL_64BIT
  %define ARG_NPTR esp+0x14
%else
  %define ARG_NPTR esp+0x10
%endif
%define ARG_ENDPTR ARG_NPTR+4
%define ARG_BASE ARG_ENDPTR+4
%ifdef CONFIG_STRTOL_64BIT
		push ebp
%endif
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
%ifdef CONFIG_STRTOL_64BIT
		xor edx, edx
		jmp near .done
%else
		jmp short .done
%endif
.base_valid:	xor edx, edx
		or eax, byte 0xffffffff  ; EAX := 0xfffffff.
		xor edx, edx
		div ebx  ; EAX := 0xffffffff / EBX (var_base); EDX := junk (remainder).
		xchg eax, edi  ; [var_overflow_limit] := 0xfffffff / [var_base]; EAX := junk.
		xor eax, eax  ; Clear higher bits, AL will contain a single byte below, from [var_p].
		xor edx, edx  ; [var_value] := 0.
%ifdef CONFIG_STRTOL_64BIT
		xor ebp, ebp  ; [var_value_high] := 0.
%endif
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
%ifdef CONFIG_STRTOL_64BIT
		cmp ebp, edi  ; [var_value] <=> [var_overflow_limit].
%else
		cmp edx, edi  ; [var_value] <=> [var_overflow_limit].
%endif
		jna .no_overflow_1
		mov ch, 1
.no_overflow_1:
%ifdef CONFIG_STRTOL_64BIT
		; [var_value] (EBP:EDX) *= [var_base] (EBX).
		push eax
		imul ebp, ebx
		mov eax, ebx
		mul edx
		xchg eax, edx
		add ebp, eax
		pop eax
		jc .add_overflow
		; [var_value] (EBP:EDX) += [var_digit] (EAX).
		add edx, eax
		adc ebp, byte 0
%else
		imul edx, ebx  ; [var_value] (EDX) *= [var_base] (EBX).
		add edx, eax  ; [var_value] (EDX) += [var_digit] (EAX).
%endif
		jnc .no_overflow_2
.add_overflow:	mov ch, 1
.no_overflow_2: jmp short .next_digit
.after_loop:	test cl, 2
		jz .endptr_null_2
		mov ebx, [ARG_ENDPTR]
		test ebx, ebx
		jz .endptr_null_2
		mov [ebx], esi
.endptr_null_2:	xchg eax, edx  ; EAX := value; EDX := junk. From now on we use EAX as value and EDX as scratch.
		test ch, ch
%ifdef CONFIG_STRTOL_UNSIGNED
		jz .no_overflow
		or eax, byte -1  ; Indicate overflow as saturated 0xffffffff.
  %ifdef CONFIG_STRTOL_64BIT
		or edx, byte -1  ; Indicate overflow as saturated 0xffffffff.
  %endif
%else  ; Signed overflow check.
		mov edx, 0x80000000
		jnz .has_overflow
  %ifdef CONFIG_STRTOL_64BIT
		cmp ebp, edx
  %else
		cmp eax, edx
  %endif
		jb .no_overflow
		jne .has_overflow
  %ifdef CONFIG_STRTOL_64BIT
		test eax, eax
		jnz .has_overflow
  %endif
		test cl, 1  ; [var_minus].
		jnz .no_overflow
.has_overflow:	; Overflow would be indicated by setting errno := ERANGE, but we don't set it, because this libc doesn't support errno.
  %ifdef CONFIG_STRTOL_64BIT
		xor eax, eax
  %else
		xchg eax, edx  ; EAX := 0x80000000; EDX := junk.
  %endif
		test cl, 1  ; [var_minus].
		jnz .done  ; If negative, indicate overflow (actually underflow) as saturated -0x80000000.
  %ifdef CONFIG_STRTOL_64BIT
		dec edx
  %endif
		dec eax  ; If nonnegative, indicate overflow as saturated 0x7fffffff.
%endif  ; else CONFIG_STRTOL_UNSIGNED
		jmp short .done
.no_overflow:	test cl, 1
%ifdef CONFIG_STRTOL_64BIT
		mov edx, ebp
%endif
		jz .done
%ifdef CONFIG_STRTOL_64BIT
		xor edx, edx
		neg eax
		sbb edx, ebp
%else
		neg eax
%endif
.done:		pop edi
		pop esi
		pop ebx
%ifdef CONFIG_STRTOL_64BIT
		pop ebp
%endif
		ret

%ifdef CONFIG_PIC  ; Already position-independent code.
%endif

%undef CONFIG_STRTOL_64BIT
%undef CONFIG_STRTOL_UNSIGNED

; __END__
