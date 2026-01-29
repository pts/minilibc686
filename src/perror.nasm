;
; written by pts@fazekas.hu at Tue Nov 19 18:31:56 CET 2024
; Compile to i386 ELF .o object: nasm -O999999999 -w+orphan-labels -f elf -o perror.o perror.nasm
;
; Code size: 0x57 bytes.
;
; Uses: %ifdef CONFIG_PIC
;

bits 32
cpu 386

global mini_perror
%ifdef CONFIG_SECTIONS_DEFINED
%elifidn __OUTPUT_FORMAT__, bin
section .text align=1
section .rodata align=1
section .data align=1
section .bss align=1
mini_strerror equ +0x12345678
mini_errno equ +0x12345679
mini_write equ +0x1234567a
%else
extern mini_strerror
extern mini_errno
extern mini_write
section .text align=1
section .rodata align=1
section .data align=1
section .bss align=1
%endif

section .text
mini_perror:  ; void mini_perror(const char *s);
		push edi  ; Save.
		push byte 10  ; '\n'
		mov eax, esp
		push strict dword ':'|(' '<<8)
		push byte 0  ; Sentinel for write_msgs_to_stderr.
		push eax  ; "\n".
		push dword [mini_errno]  ; Argument errnum of mini_strerror.
		call mini_strerror
		pop ecx  ; Clean up argument errnum of mini_strerror.
		push eax  ; Error message returned by mini_stderror.
		mov ecx, [esp+7*4]  ; Argument s.
		test ecx, ecx
		jz short .after_prefix
		cmp byte [ecx], 0
		je short .after_prefix
		lea edx, [esp+3*4]
		push edx  ; ": ".
		push ecx  ; prefix in argument s.
.after_prefix:	call write_msgs_to_stderr
		times 2 pop eax  ; Clean up message pointers (to '\n' and ': ') from the stack.
		pop edi  ; Restore.
		ret

; Simplifying the stack handling in this code so that this function writes
; only a single message would make it longer.
write_msgs_to_stderr:  ; Takes and pops NUL-terminated messages from the stack. Ruins EAX, ECX, EDX and EDI.
		pop edi  ; Return address.
.next_str:	pop eax
		test eax, eax
		jz .done
		xor ecx, ecx
.0:		inc ecx
		cmp byte [eax+ecx-1], 0
		jne short .0
		dec ecx
		push ecx  ; Argument count of mini_write.
		push eax  ; Argument buf of mini_write.
		push byte 2  ; STDERR_FILENO.
		call mini_write
		add esp, byte 3*4  ; Clean up arguments of mini_write from the stack.
		jmp short .next_str
.done:		push edi
		ret

%ifdef CONFIG_PIC  ; Already position-independent code.
%endif

; __END__
