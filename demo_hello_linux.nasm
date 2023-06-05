;
; demo_hello_linux.nasm: Linux i386 32-bit ELF executable program
; by pts@fazekas.hu at Tue May 16 12:20:36 CEST 2023
;
; Compile to Linux i386 32-bit ELF executable:
;
;     nasm -O999999999 -w+orphan-labels -f bin -o demo_hello_linux.prog demo_hello_linux.nasm &&
;     chmod +x demo_hello_linux.prog
;
; Alternatively, you can compile with Yasm (tested with 1.2.0 and 1.3.0)
; instead of NASM. The output is bitwise identical.
;
; Run it on Linux i386 or Linux amd64 systems:
;
;     ./demo_hello_linux.prog
;
; To build a bit-by-bit identical executable program with GCC 7.5.0 from C
; source, run this:
;
;   ./minicc --noenv --gcc=gcc-7.5.0 demo_c_hello.c
;

;%define CONFIG_NO_RW_SECTIONS
;%define ALIGN_RODATA 4
%include "elf0.inc.nasm"

main:  ; int main(int argc, char **argv, char **envp);  /* envp is optional to declare and/or use. */
		cmp dword [esp+4], byte 4  ; argc == 4?
		jne short .after_envp
		mov eax, [esp+0xc]	; EAX := address of the envp[0] string.
		push dword [eax]	; The envp[0] string.
		push esp		; va_list ap.
		push strict dword format_ps
		push dword [mini_stdout]
		call mini_vfprintf
		add esp, byte 4*4	; Clean up arguments of mini_vfprintf(...) above from the stack.
.after_envp:
		xor eax, eax		; EAX := 0 == EXIT_SUCCESS.
		push eax		; Push 0 == EXIT_SUCCESS early, just to show that we clean up the stack properly.

		push strict dword addressee
		push esp		; va_list ap.
		mov edx, format
		add edx, [esp+0x10]	; EDX += argc. Skip printing of the first few bytes of the format.
		dec edx			; Base skip count: if argc == 0, don't skip anything.
		push edx
		push dword [mini_stdout]  ; Filehandle.
		call mini_vfprintf	; Print to buffer. Calls mini_putc (defined below) for each byte.
		add esp, byte 4*4	; Clean up arguments of mini_vfprintf(...) above from the stack.

		pop eax			; Return value (program exit code).
		ret

;section .data
;		db 'Hit'
;		dd buf
;section .bss
;buf:		resb 0x100

%include "src/vfprintf_plus.nasm"
;%include "src/strlen.nasm"
%include "src/fputc_unbuffered.nasm"
%include "src/write_linux.nasm"
%include "src/start_linux.nasm"
_start equ mini__start  ; ELF program entry point defined in start_linux.nasm.

section .rodata
format_ps:	db '%s', 0
format:		db 'Hello, %s!', 10, 0
addressee:	db 'World', 0

_end  ; __END__
