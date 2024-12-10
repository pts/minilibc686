;
; fyi/linux_start_and_syscalls.nasm; an example Linux implementation of _start and syscalls for `minicc -bany'
; by pts@fazekas.hu at Tue Dec 10 01:55:16 CET 2024
;
; Compile to ./a.out with: pathbin/minicc nasm -O999999999 -w+orphan-labels -f elf -o fyi/linux_start_and_syscalls.o fyi/linux_start_and_syscalls.nasm && pathbin/minicc -bany fyi/linux_start_and_syscalls.o test/test_c_hello.c
;
; Please note that mini_errno may still be OS-specific with `-bany'.
;

bits 32
cpu 386
extern main
extern mini___M_start_flush_stdout
;extern mini_errno  ; Not implemented.
;extern mini___M_start_flush_opened

global _start
_start:
		pop eax  ; argc.
		mov edx, esp  ; argv.
		;lea ecx, [edx+eax*4+4]  ; envp.
		;mov [mini_environ], ecx  ; mini_environ not implemented.
		push edx  ; argv arg of main.
		push eax  ; argc arg of main.
		call main  ; Ignore argc ard argv.
		push eax
		push eax
		; Fall through to mini_exit.
global mini_exit
		call mini___M_start_flush_stdout
		;call mini___M_start_flush_opened  ; We assume that there is nothing to flush.
mini_exit:  ; __attribute__((noreturn)) void mini_exit(int status);
		; !! Flush stdout.
		; Fall through to mini__exit.
global mini__exit
mini__exit:  ; __attribute__((noreturn)) void mini__exit(int exit_code);
		pop eax
		pop ebx  ; exit_code.
		xor eax, eax
		inc eax  ; EAX := Linux i386 SYS_exit (1).
		int 0x80  ; Linux i386 syscall.
		; Not reached.
global mini_isatty
mini_isatty:  ; int isatty(int fd);
		xor eax, eax  ; Fake false: no line buffering for output on this fd.
		cmp dword [esp+4], byte 1  ; STDOUT_FILENO.
		jne .not_stdout
		inc eax  ; Return fake true: stdout should be line-buffered.
.not_stdout:	ret
global mini_write
mini_write:  ; ssize_t write(int fd, const void *buf, size_t count);
		push ebx  ; Save.
		push byte 4  ; Linux i386 SYS_write.
		pop eax
		mov ebx, [esp+2*4]  ; Argument fd.
		mov ecx, [esp+3*4]  ; Argument buf.
		mov edx, [esp+4*4]  ; Argument count.
		int 0x80  ; Linux i386 syscall.
		pop ebx  ; Restore.
		test eax, eax
		; Sign check is good for most syscalls, but not time(2) or mmap2(2).
		; For mmap2(2), do: cmp eax, -0x100 ++ jna .ok
		jns .ok
		;neg eax
		;mov [mini_errno], eax  ; mini_errno not implemented.
		or eax, -1  ; EAX := -1 (ignore -errnum value).
.ok:		ret

;section .bss align=4
;mini_environ:	resd 1  ; char **mini_environ;
