;
; Mostly based on the output of soptcc.pl for c_stdio_file_simple_buffered.c
; Compile to i386 ELF .o object: nasm -O999999999 -w+orphan-labels -f elf -o stdio_file_simple_buffered.o stdio_file_simple_buffered.nasm
;
; Code size: 0x2c3 bytes.
;
; Uses: %ifdef CONFIG_PIC
;

bits 32
cpu 386

global mini_fopen
global mini_fflush
global mini_fclose
global mini_fread
global mini_fwrite
global mini_fseek
global mini_ftell
global mini_fgetc
global mini___M_flushall
%ifidn __OUTPUT_FORMAT__, bin
section .text align=1
section .rodata align=1
section .data align=1
section .bss align=1
mini_close equ $+0x12345678
mini_lseek equ $+0x12345679
mini_open equ $+0x1234567a
mini_read equ $+0x1234567b
mini_write equ $+0x1234567c
%else
section .text align=1
section .rodata align=4
section .data align=4
section .bss align=4
extern mini_close
extern mini_lseek
extern mini_open
extern mini_read
extern mini_write
%endif

section .text

mini_fopen:  ; FILE *mini_fopen(const char *pathname, const char *mode);
		push ebx
		push ecx
		cmp byte [global_files], 0x0
		je .6
		cmp byte [global_files+0x1014], 0x0
		je .7
.5:		xor ebx, ebx
		jmp short .1
.6:		mov ebx, global_files
		jmp short .2
.7:		mov ebx, global_files+0x1014
.2:		mov eax, [esp+0x10]
		mov dl, [eax]
		cmp dl, 0x77
		mov [esp+0x3], dl
		setne al
		movzx eax, al
		dec eax
		and eax, 0x241
		push dword 0x1b6
		push eax
		push dword [esp+0x14]
		call mini_open
		add esp, byte 0xc
		test eax, eax
		js .5
		mov dl, [esp+0x3]
		cmp dl, 0x77
		sete dl
		inc edx
		mov [ebx], dl
		mov [ebx+0x4], eax
		mov dword [ebx+0x10], 0x0
		lea eax, [ebx+0x14]
		mov [ebx+0xc], eax
		mov [ebx+0x8], eax
.1:		mov eax, ebx
		pop edx
		pop ebx
		ret

mini_fflush:  ; int mini_fflush(FILE *filep);
		push edi
		push esi
		push ebx
		mov ebx, [esp+0x10]
		or eax, byte -0x1
		cmp byte [ebx], 0x2
		jne .11
		lea edi, [ebx+0x14]
		mov esi, edi
.13:		mov eax, [ebx+0x8]
		cmp eax, esi
		je .20
		sub eax, esi
		push eax
		push esi
		push dword [ebx+0x4]
		call mini_write
		lea edx, [eax+0x1]
		add esp, byte 0xc
		cmp edx, byte 0x1
		jbe .17
		add esi, eax
		jmp short .13
.20:		xor eax, eax
		jmp short .14
.17:		or eax, byte -0x1
.14:		sub esi, edi
		add [ebx+0x10], esi
		mov [ebx+0xc], edi
		mov [ebx+0x8], edi
.11:		pop ebx
		pop esi
		pop edi
		ret

mini_fclose:  ; int mini_fclose(FILE *filep);
		push esi
		push ebx
		mov ebx, [esp+0xc]
		mov al, [ebx]
		or esi, byte -0x1
		test al, al
		je .21
		xor esi, esi
		dec al
		je .23
		push ebx
		call mini_fflush
		mov esi, eax
		pop edx
.23:		push dword [ebx+0x4]
		call mini_close
		mov byte [ebx], 0x0
		pop eax
.21:		mov eax, esi
		pop ebx
		pop esi
		ret

mini_fread:  ; size_t mini_fread(void *ptr, size_t size, size_t nmemb, FILE *filep);
		push edi
		push esi
		push ebx
		mov ebx, [esp+0x1c]
		mov edi, [esp+0x14]
		imul edi, [esp+0x18]
		cmp byte [ebx], 0x1
		jne .35
		test edi, edi
		je .35
		mov esi, [esp+0x10]
.31:		mov edx, [ebx+0x8]
		cmp edx, [ebx+0xc]
		je .41
		lea eax, [edx+0x1]
		mov [ebx+0x8], eax
		lea eax, [esi+0x1]
		mov cl, [edx]
		mov [esi], cl
		dec edi
		je .32
.34:		mov esi, eax
		jmp short .31
.41:		lea eax, [ebx+0x14]
		sub edx, eax
		add [ebx+0x10], edx
		mov [ebx+0xc], eax
		mov [ebx+0x8], eax
		push dword 0x1000
		push eax
		push dword [ebx+0x4]
		call mini_read
		lea edx, [eax+0x1]
		add esp, byte 0xc
		cmp edx, byte 0x1
		jbe .36
		add [ebx+0xc], eax
		mov eax, esi
		jmp short .34
.36:		mov eax, esi
.32:		sub eax, [esp+0x10]
		xor edx, edx
		div dword [esp+0x14]
		jmp short .29
.35:		xor eax, eax
.29:		pop ebx
		pop esi
		pop edi
		ret

mini_fwrite:  ; size_t mini_fwrite(const void *ptr, size_t size, size_t nmemb, FILE *filep);
		push ebp
		push edi
		push esi
		push ebx
		mov ebp, [esp+0x14]
		mov esi, [esp+0x20]
		mov edi, [esp+0x18]
		imul edi, [esp+0x1c]
		cmp byte [esi], 0x2
		jne .51
		test edi, edi
		je .51
		lea eax, [esi+0x14]
		mov ebx, ebp
		cmp [esi+0x8], eax
		jne .53
		cmp edi, 0xfff
		ja .44
.53:		lea ecx, [esi+0x1014]
.46:		mov edx, [esi+0x8]
		cmp edx, ecx
		je .44
		inc ebx
		lea eax, [edx+0x1]
		mov [esi+0x8], eax
		mov al, [ebx-0x1]
		mov [edx], al
		dec edi
		jne .46
		jmp short .47
.44:		push esi
		call mini_fflush
		pop edx
		test eax, eax
		jne .47
.49:		push edi
		push ebx
		push dword [esi+0x4]
		call mini_write
		lea edx, [eax+0x1]
		add esp, byte 0xc
		cmp edx, byte 0x1
		jbe .47
		add ebx, eax
		sub edi, eax
		add [esi+0x10], eax
		jmp short .49
.47:		mov eax, ebx
		sub eax, ebp
		xor edx, edx
		div dword [esp+0x18]
		jmp short .42
.51:		xor eax, eax
.42:		pop ebx
		pop esi
		pop edi
		pop ebp
		ret

mini_fseek:  ; int mini_fseek(FILE *filep, off_t offset, int whence);  /* Only 32-bit off_t. */
		push edi
		push esi
		push ebx
		mov ebx, [esp+0x10]
		mov esi, [esp+0x14]
		mov edi, [esp+0x18]
		mov al, [ebx]
		cmp al, 0x1
		jne .64
		lea edx, [ebx+0x14]
		cmp edi, byte 0x1
		jne .65
		mov eax, [ebx+0x8]
		sub eax, edx
		add eax, [ebx+0x10]
		mov [ebx+0x10], eax
		add esi, eax
		xor edi, edi
.65:		mov [ebx+0xc], edx
		mov [ebx+0x8], edx
		jmp short .66
.64:		cmp al, 0x2
		je .67
.69:		or eax, byte -0x1
		jmp short .63
.67:		push ebx
		call mini_fflush
		pop edx
		test eax, eax
		jne .69
.66:		push edi
		push esi
		push dword [ebx+0x4]
		call mini_lseek
		add esp, byte 0xc
		cmp eax, byte -0x1
		je .69
		mov [ebx+0x10], eax
		xor eax, eax
.63:		pop ebx
		pop esi
		pop edi
		ret

mini_ftell:  ; off_t mini_ftell(FILE *filep);  /* Only 32-bit off_t */
		mov edx, [esp+0x4]
		mov al, [edx]
		lea ecx, [eax-0x1]
		xor eax, eax
		cmp cl, 0x1
		ja .74
		lea eax, [edx+0x14]
		mov ecx, [edx+0x8]
		sub ecx, eax
		mov eax, [edx+0x10]
		add eax, ecx
.74:		ret

mini_fgetc:  ; int mini_fgetc(FILE *filep);
		push ecx
		mov eax, [esp+0x8]
		mov edx, [eax+0x8]
		cmp edx, [eax+0xc]
		je .78
		inc edx
		mov [eax+0x8], edx
		dec edx
		jmp short .79
.78:		mov edx, esp  ; EDX := &uc.
		push eax
		push byte 0x1
		push byte 0x1
		push edx  ; &uc.
		call mini_fread
		add esp, byte 0x10
		xchg eax, edx
		or eax, byte -0x1  ; EAX := -1 (== EOF).
		test edx, edx
		jz .77
		mov edx, esp
.79:		movzx eax, byte [edx]
.77:		pop ecx  ; Value overwritten by mini_fread above. That's fine, ECX is a scratch register.
		ret

mini___M_flushall:  ; void mini___M_flushall(void);
		push dword global_files
		call mini_fflush
		pop eax
		push dword global_files+0x1014
		call mini_fflush
		pop eax
		ret

section .bss
global_files: resb 2*0x1014  ; Contains 2 `struct _SFS_FILE's, reserved for allocation by mini_fopen(...).

%ifdef CONFIG_PIC
%error Not PIC because of mini_stdout.
times 1/0 nop
%endif

; __END__
