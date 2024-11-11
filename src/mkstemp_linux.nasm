;
; based on .nasm source file generated by soptcc.pl from fyi/c_mkstemp_linux.c
; Compile to i386 ELF .o object: nasm -O999999999 -w+orphan-labels -f elf -o src/mkstemp_linux.o src/mkstemp_linux.nasm
;
; Code size: 0xab bytes.
;

bits 32
cpu 386

global mini_mkstemp
%ifdef CONFIG_SECTIONS_DEFINED
%elifidn __OUTPUT_FORMAT__, bin
section .text align=1
section .rodata align=1
section .data align=1
section .bss align=1
mini_prng_mix3_RP3 equ +0x12345678
%else
extern mini_prng_mix3_RP3
section .text align=1
section .rodata align=1
section .data align=1
section .bss align=1
%endif

%define EEXIST 17
%define EINVAL 22

%define O_CREAT 0100q
%define O_RDWR  2
%define O_EXCL  0200q
%define O_NOFOLLOW 0400000q

SYS_open equ 5
SYS_getpid equ 20
SYS_gettimeofday equ 78

section .text
mini_mkstemp:  ; int mini_mkstemp(char *template);
		push edi
		push esi
		push ebx
		mov esi, [esp+0x10]  ; Argument template.
		mov eax, esi
.2:		cmp byte [eax], 0x0
		je short .15
		inc eax
		jmp short .2
.15:		lea ebx, [eax-0x6]
		cmp esi, ebx
		ja short .4
		mov edi, ebx
.7:		cmp byte [edi], 'X'
		je short .5
.4:		;mov dword [mini_errno], EINVAL  ; TODO(pts): Set errno if used by the program.
		jmp near .err  ; Doesn't fit to a short jump.
.5:		inc edi
		cmp edi, eax
		jne short .7
.retry:		; We put a reasonably random number in EAX by mixing the return address, our address, ESP, gettimeofday() sec, gettimeofday() msec and getpid().
		mov eax, [esp+0xc]  ; Function return address.
		call mini_prng_mix3_RP3
%ifdef CONFIG_PIC
		call .here
.here:		pop edx
		add eax, edx  ; A bit larger than mini_mkstemp, but it will do.
%else
		add eax, mini_mkstemp
%endif
		call mini_prng_mix3_RP3
		add eax, esp
		call mini_prng_mix3_RP3
		push ebx  ; Save address of first 'X', to be replaced.
		push eax  ; Save.
		push eax  ; Make room for tv_usec output.
		push eax  ; Make room for tv_sec output.
		mov ebx, esp  ; Argument tv of gettimeofday.
		xor ecx, ecx  ; Argument tz of gettimeofday (NULL).
		push byte SYS_gettimeofday
		pop eax
		int 0x80  ; Linux i386 syscall.
		pop ecx  ; tv_sec.
		pop ebx  ; tv_usec.
		pop eax  ; Restore.
		add eax, ecx
		call mini_prng_mix3_RP3
		add eax, ebx
		call mini_prng_mix3_RP3
		push eax  ; Save.
		push byte SYS_getpid
		pop eax
		int 0x80  ; Linux i386 syscall. EAX := getpid().
		pop edx  ; Restore saved EAX.
		add eax, edx
		call mini_prng_mix3_RP3
		; Now we have our reasonably random number in EAX.
		pop edx  ; Restore address of the first 'X', to be replaced.
.8:		mov ecx, eax  ; ECX := random (EAX).
		and eax, byte 0x1f  ; 5 bits.
		cmp al, 9
		jna short .10
		add al, 'a'-10-'0'
.10		add al, '0'
		mov [edx], eax
		xchg ecx, eax  ; EAX := random; ECX := junk.
		shr eax, 5
		inc edx
		cmp edx, edi
		jne short .8
		push ebx  ; Save.
		mov edx, 600q
		mov ecx, O_CREAT|O_RDWR|O_EXCL|O_NOFOLLOW
		mov ebx, esi  ; Template with 'X's replaced by random characters.
		push byte SYS_open
		pop eax
		int 0x80  ; Linux i386 syscall.
		pop ebx  ; Restore.
		test eax, eax
		jns short .1
		cmp eax, byte -EEXIST
		je short .retry
.err:		or eax, byte -1
.1:		pop ebx
		pop esi
		pop edi
		ret

; __END__
