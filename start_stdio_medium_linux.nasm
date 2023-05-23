;
; written by pts@fazekas.hu at Fri May 19 17:25:38 CEST 2023
; Compile to i386 ELF .o object: nasm -O999999999 -w+orphan-labels -f elf -o start_stdio_file_linux.o start_stdio_file_linux.nasm
;
; Uses: %ifdef CONFIG_PIC
;

bits 32
cpu 386

%ifdef mini__start
  global $mini__start  ; Without expanding the macro.
%endif
global mini__start
global mini__exit
global mini_syscall3_AL
global mini_syscall3_RP1
global mini_exit
global mini_open
global mini_close
global mini_read
global mini_write
global mini_lseek
global mini_ioctl
%ifdef CONFIG_SECTIONS_DEFINED
%elifidn __OUTPUT_FORMAT__, bin
section .text align=1
section .rodata align=4
section .data align=4
section .bss align=4
main equ +0x12345678
mini___M_flushall equ +0x12345679
mini___M_init_isatty equ +0x1234567a
%else
extern main
extern mini___M_flushall
common mini___M_stdout_for_flushall 4:4
common mini___M_init_isatty 1:1
section .text align=1
section .rodata align=1
section .data align=1
section .bss align=1
%endif

section .text
%ifdef mini__start
  $mini__start:  ; Without expanding the macro.
%endif
mini__start:  ; Entry point (_start) of the Linux i386 executable.
		; Now the stack looks like (from top to bottom):
		;   dword [esp]: argc
		;   dword [esp+4]: argv[0] pointer
		;   esp+8...: argv[1..] pointers
		;   NULL that ends argv[]
		;   environment pointers
		;   NULL that ends envp[]
		;   ELF Auxiliary Table
		;   argv strings
		;   environment strings
		;   program name
		;   NULL		
		pop eax  ; argc.
		mov edx, esp  ; argv.
		lea ecx, [edx+eax*4+4]  ; envp.
		push ecx  ; Argument envp for main.
		push edx  ; Argument argv for main.
		push eax  ; Argument argc for main.
		mov eax, mini___M_init_isatty
		cmp byte [eax], 0  ; First byte of machine code is nonzero => real code, otherwise 0 implemented as common symbol.
		je .after_isatty
		call eax  ; Call mini___M_init_isatty without arguments.
.after_isatty:	call main  ; Return value (exit code) in EAX (AL).
		push eax  ; Save exit code, for mini__exit.
		push eax  ; Fake return address, for mini__exit.
		; Fall through to mini_exit(...).
mini_exit:  ; void mini_exit(int exit_code);
		call mini___M_flushall  ; Flush all stdio streams.
		; Fall through to mini__exit(...).
mini__exit:  ; void mini__exit(int exit_code);
_exit:
		mov al, 1  ; __NR_exit.
		; Fall through to progx_syscall3.
syscall3:
mini_syscall3_AL:  ; Useful from assembly language.
; Calls syscall(number, arg1, arg2, arg3).
;
; It takes the syscall number from AL (8 bits only!), arg1 (optional) from
; [esp+4], arg2 (optional) from [esp+8], arg3 (optional) from [esp+0xc]. It
; keeps these args on the stack.
;
; It can EAX, EDX and ECX as scratch.
;
; It returns result (or -1 as error) in EAX.
		movzx eax, al  ; number.
mini_syscall3_RP1:  ; long mini_syscall3_RP1(long nr, long arg1, long arg2, long arg3) __attribute__((__regparm__(1)));
		push ebx  ; Save it, it's not a scratch register.
		mov ebx, [esp+8]  ; arg1.
		mov ecx, [esp+0xc]  ; arg2.
		mov edx, [esp+0x10]  ; arg3.
		int 0x80  ; Linux i386 syscall.
		; test eax, eax
		; jns .final_result
		cmp eax, -0x100  ; Treat very large (e.g. <-0x100; with Linux 5.4.0, 0x85 seems to be the smallest) non-negative return values as success rather than errno. This is needed by time(2) when it returns a negative timestamp. uClibc has -0x1000 here.
		jna .final_result
		or eax, byte -1  ; EAX := -1 (error).
.final_result:	pop ebx
		ret

; TODO(pts): Use smart linking to get rid of the unnecessary syscalls.
mini_read:	mov al, 3  ; __NR_read.
		jmp strict short syscall3
mini_write:	mov al, 4  ; __NR_write.
		jmp strict short syscall3
mini_open:	mov al, 5  ; __NR_open.
		jmp strict short syscall3
mini_close:	mov al, 6  ; __NR_close.
		jmp strict short syscall3
mini_lseek:	mov al, 19  ; __NR_lseek.
		jmp strict short syscall3
mini_ioctl:	mov al, 54  ; __NR_ioctl.
		jmp strict short syscall3
; TODO(pts): Automatically add creat(2), remove(2) etc.
;mini_time:	mov al, 13  ; __NR_time.
;		jmp strict short syscall3
;mini_gettimeofday:  mov al, 78  ; __NR_gettimeofday.
;		jmp strict short syscall3

%ifdef CONFIG_PIC  ; Already position-independent code.
%endif

; __END__
