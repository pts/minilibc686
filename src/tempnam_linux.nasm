;
; by pts@fazekas.hu at Mon Nov 11 04:19:13 CET 2024
; partially based on soptcc.pl output
; Compile to i386 ELF .o object: nasm -O999999999 -w+orphan-labels -f elf -o src/tempnam_linux.o src/tempnam_linux.nasm
;
; Code+data size: 0x111 bytes.
;

bits 32
cpu 386

global mini_tempnam
global mini_tempnam_noremove
%define RODATA .rodata
%ifdef CONFIG_SECTIONS_DEFINED
%elifidn __OUTPUT_FORMAT__, bin
section .text align=1
section RODATA align=1
section .data align=1
section .bss align=1
mini_close equ +0x12345678
mini_free equ +0x12345679
mini_getenv equ +0x1234567a
mini_malloc equ +0x1234567b
mini_mkstemp equ +0x1234567c
mini_unlink equ +0x1234567d
%else
extern mini_close
extern mini_free
extern mini_getenv
extern mini_malloc
extern mini_mkstemp
extern mini_unlink
%define RODATA .rodata.str1.1
section .text align=1
section RODATA align=1
section .data align=1
section .bss align=1
%endif

section .text
mini_tempnam_noremove:  ; char *mini_tempnam_noremove(const char *dir, const char *pfx);
		push edi
		push esi
		push ebx
		mov ebx, [esp+0x10]  ; dir.
		mov esi, [esp+0x14]  ; pfx.
		push dword str_tmpdir
		call mini_getenv
		pop edx  ; Clean up argument of mini_getenv.
		mov edi, eax
		call direxists_RP3
		test eax, eax
		jnz short .2
		mov eax, ebx  ; dir.
		mov edi, eax
		call direxists_RP3
		test eax, eax
		jnz short .2
		mov eax, str_tmp
		mov edi, eax
		call direxists_RP3
		test eax, eax
		jz short .24
.2:		test esi, esi
		jne short .4
		mov esi, str_temp
.4:		mov eax, 8
.5:		cmp byte [esi+eax-8], 0
		je short .26
		inc eax
		jmp short .5
.26:		mov edx, edi
		sub edx, eax
.7:		cmp byte [edx+eax], 0
		je short .27
		inc eax
		jmp short .7
.27:		push eax
		call mini_malloc
		pop edx
		test eax, eax
		jz short .1
		xchg ebx, eax  ; EBX := EAX; EAX := junk. Save EBX for the argument of mini_mkstemp(...).
		mov edx, ebx
		xchg edx, edi
.10:		mov al, [edx]
		test al, al
		je short .28
		inc edx
		stosb
		jmp short .10
.28:		mov al, '/'
		stosb
.12:		lodsb
		test al, al
		je short .29
		stosb
		jmp short .12
.29:		push byte 6
		pop ecx
		mov al, 'X'
		rep stosb
		mov byte [edi], 0  ; We don't need EDI after this.
		push ebx
		call mini_mkstemp
		pop edi
		test eax, eax
		jns short .15
		push ebx
		call mini_free
		pop edx
.24:		xor eax, eax
		jmp short .1
.15:		push eax
		call mini_close
		pop edx
		; TODO(pts): With smart.nasm, merge with mini_tempnam, enabling the following code here.
		;push ebx
		;call mini_unlink
		;pop edx
		xchg eax, ebx  ; EAX := EBX; EBX := junk.
.1:		pop ebx
		pop esi
		pop edi
		ret

mini_tempnam:  ; char *mini_tempnam(const char *dir, const char *pfx);
		push dword [esp+8]  ; pfx.
		push dword [esp+8]  ; dir.
		call mini_tempnam_noremove
		times 2 pop edx  ; Clean up arguments of mini_tempnam_noremove from the stack.
		test eax, eax
		jz short .ret
		push eax
		call mini_unlink
		pop eax  ; Both remove the argument and restore return value.
.ret:		ret

direxists_RP3:  ; int direxists_RP3(const char *dir) __attribute__((__regparm__(1)));
; struct stat buf;
; return stat(dir, &buf) == 0 && S_ISDIR(buf.st_mode);
		push ebx  ; Save.
		xchg ebx, eax  ; EBX := EAX (dir); EBX := junk.
		test ebx, ebx
		jnz short .not_null
.ret_0:		pop ebx  ; Restore.
		xor eax, eax
		ret
.not_null:	cmp byte [ebx], 0
		je short .ret_0
		sub esp, byte 64
		mov ecx, esp
		push byte 106  ; SYS_stat.
		pop eax
		int 0x80  ; Linux i386 syacall.
		mov cl, [ecx+9]  ; High byte of st_mode.
		add esp, byte 64
		test eax, eax
		jnz short .ret_0
		xor eax, eax
		and cl, 0xf0
		cmp cl, 0x40
		sete al
		pop ebx  ; Restore.
		ret

section RODATA
str_tmp:	db '/tmp', 0  ; P_tmpdir, Linux-specific.
str_temp:	db 'temp_', 0
str_tmpdir:	db 'TMPDIR', 0

%ifdef CONFIG_PIC
%error Not PIC because it uses global variables and constants.
times 1/0 nop
%endif

; __END__
