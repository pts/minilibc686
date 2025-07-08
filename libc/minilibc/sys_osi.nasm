; by pts@fazekas.hu at Sun Apr 28 02:07:17 CEST 2024
;
; See also https://github.com/pts/oix-wcfd32/tree/master/osi5
;
; The output of `minicc -bosi' has to be post-processed with elf2oix.pl.
;
; !! Make the number of files (-mfiles=...) in libci.a:stdio_medium_flobal_files.o configurable.
; !! minilibc printf is not smart enough to handle ndisasm (NASM listing is already supported)
; !! automatically convert \n to \r\n on TTY output in mini_write(...)
;

%ifnidn (__OUTPUT_FORMAT__), (elf)
  %error '`nasm -f elf` required.'
  times 1/0 nop
%endif

%ifndef UNDEFSYMS
  %error 'Expecting UNDEFSYMS from minicc.'
  times 1/0 nop
%endif
%macro _define_needs 0-*
  %rep %0
    %define __NEED_%1
    %rotate 1
  %endrep
%endmacro
_define_needs UNDEFSYMS

bits 32
cpu 386

section .text align=1
section .rodata align=1
section .data align=1
section .bss align=4

global _start
global mini__exit
global mini_exit
%ifdef __NEED_mini_environ
  global mini_environ
%endif
; !! TODO(pts): Move thee functions below to separate .o files.
global mini___M_fopen_open
global mini_open
global mini_close
global mini_read
global mini_write
global mini_lseek
global mini_isatty
global mini_remove
global mini_unlink
global mini_ftruncate_here
global mini_ftruncate
global mini_time
global mini_malloc_simple_unaligned
global mini_strerror

global _INT21ADDR
global __OS
global _STACKTOP
global _BreakFlagPtr

extern main  ; extern int __cdecl main(int argc, char **argv);

section .text

section .bss
_INT21ADDR:	resb 6  ; void (__far *_INT21ADDR)(void);
__OS:		resb 1  ; char __OS;
		resb 1  ; Alignment to multiple of 4.
_STACKTOP:	resd 1  ; void *_STACKTOP;
_BreakFlagPtr:	resd 1  ; unsigned *_BreakFlagPtr;
;__EnvPtr:	resd 1  ; char **_EnvPtr;
%ifdef __NEED_mini_environ
  mini_environ:	resd 1  ; char **environ;
%endif
;_LpPgmName:	resd 1  ; char *_LpPgmName;
section .text

%ifdef __NEED__start
global _start
_start:
global mini__start
mini__start: ; __OSI__ program entry point.
		; Zero-initialize BSS. !! TODO(pts): The WCFD32 loader has done it.
%if 0  ; !! What are the symbols _end and _edata for GNU ld(1)?
		push edx
		push edi
		push eax
		mov ecx, _end		; end of _BSS segment (start of free)
		mov edi, _edata		; start of _BSS segment
		sub ecx, edi		; calc # of bytes in _BSS segment
		xor eax, eax		; zero the _BSS segment
		mov dl, cl		; copy the lower bits of size
		shr ecx, 2		; get number of dwords
		rep stosd		; copy them
		mov cl, dl		; get lower bits
		and cl, 3		; get number of bytes left (modulo 4)
		rep stosb		; copy remaining few bytes
		pop eax
		pop edi
		pop edx
%endif
		; Initialize variables.
		mov [_STACKTOP], esp
		mov [_INT21ADDR+4], bx
		mov [_INT21ADDR+0], edx
		mov [__OS], ah		; save OS ID
		mov eax, [edi+12]	; get address of break flag
		mov [_BreakFlagPtr], eax  ; save it
		mov eax, [edi]		; get program name
		push 0			; NULL marks end of argv array.
		;mov [_LpPgmName], eax
		push eax		; Push argv[0].
		mov eax, [edi+4]	; Get command line.
		;mov [_LpCmdLine], eax	; Don't save it, parse_first_arg has overwritten it.
		xor ecx, ecx
		inc ecx			; ECX := 1 (current argc).
		; !! Exclude command line if not needed, see CONFIG_MAIN_* in sys_freebsd.nasm.
.argv_next:	mov edx, eax		; Save EAX (remaining command line).
		call parse_first_arg
		cmp eax, edx
		je .argv_end		; No more arguments in argv.
		inc ecx			; argc += 1.
		push edx		; Push argv[i].
		jmp .argv_next
.argv_end:	mov eax, esp
		call reverse_ptrs
%ifdef __NEED_mini_environ
		mov ebp, esp		; Save argv to EBP.
		; Initialize environ.
		; TODO(pts): Allocate pointers on the heap, not on the stack.
		mov esi, [edi+8]	; get environment pointer
		;mov _EnvPtr, esi	; save environment pointer
		push 0			; NULL marks end of env array
  .2:		push esi		; push ptr to next string
  .3:		lodsb			; get character
		cmp al, 0		; check for null char
		jne .3			; until end of string
		cmp byte [esi], byte 0  ; check for double null char
		jne .2			; until end of environment strings
		mov eax, esp
		call reverse_ptrs
		mov [mini_environ], esp	; set pointer to array of ptrs
		mov edx, ebp		; EDX := EBP (saved argv).
%else
		mov edx, esp		; EDX := ESP (argv).
%endif
		; Call main.
		xchg eax, ecx		; EAX := ECX (argc). ECX := junk.
		push esp		; Argument envp for __cdecl main.
		push edx		; Argument argv for __cdecl main.
		push eax		; Argument argc for __cdecl main.
%ifdef __NEED_mini___M_call_start_isatty_stdin
  global mini___M_call_start_isatty_stdin
  mini___M_call_start_isatty_stdin:
  global mini___M_U_stdin
  mini___M_U_stdin:
  extern mini___M_start_isatty_stdin
		call mini___M_start_isatty_stdin
%endif
%ifdef __NEED_mini___M_call_start_isatty_stdout
  global mini___M_call_start_isatty_stdout
  mini___M_call_start_isatty_stdout:
  %define DEFINED_mini___M_U_stdout
  global mini___M_U_stdout
  mini___M_U_stdout:
  extern mini___M_start_isatty_stdout
		call mini___M_start_isatty_stdout
%endif
		call main  ; Return value (exit code) in EAX (AL).
		push eax  ; Save exit code, for mini__exit.
		push eax  ; Fake return address, for mini__exit.
		; Fall through to mini_exit(...).
%endif  ; %ifdef __NEED_start
mini_exit:  ; void __cdecl mini_exit(int exit_code);
%ifdef __NEED_mini___M_call_start_flush_stdout
  global mini___M_call_start_flush_stdout
  mini___M_call_start_flush_stdout:
  %ifndef DEFINED_mini___M_U_stdout
    global mini___M_U_stdout
    mini___M_U_stdout:
  %endif
  extern mini___M_start_flush_stdout
		call mini___M_start_flush_stdout
%endif
%ifdef __NEED_mini___M_call_start_flush_opened
  global mini___M_call_start_flush_opened
  mini___M_call_start_flush_opened:
  global mini___M_U_opened
  mini___M_U_opened:
  extern mini___M_start_flush_opened
		call mini___M_start_flush_opened  ; Ruins EBX.
%endif
		; Fall through to mini__exit(...).
mini__exit:  ; void mini__exit(int exit_code);
		mov eax, [esp+4]
		mov esp, [_STACKTOP]
		retf

section .bss
global mini_errno
mini_errno:	resd 1  ; int mini_errno;
section .text

INT21H_FUNC_06H_DIRECT_CONSOLE_IO equ 0x6
INT21H_FUNC_08H_CONSOLE_INPUT_WITHOUT_ECHO equ 0x8
INT21H_FUNC_19H_GET_CURRENT_DRIVE equ 0x19
INT21H_FUNC_1AH_SET_DISK_TRANSFER_ADDRESS equ 0x1A
INT21H_FUNC_2AH_GET_DATE        equ 0x2A
INT21H_FUNC_2CH_GET_TIME        equ 0x2C
INT21H_FUNC_3BH_CHDIR           equ 0x3B
INT21H_FUNC_3CH_CREATE_FILE     equ 0x3C
INT21H_FUNC_3DH_OPEN_FILE       equ 0x3D
INT21H_FUNC_3EH_CLOSE_FILE      equ 0x3E
INT21H_FUNC_3FH_READ_FROM_FILE  equ 0x3F
INT21H_FUNC_40H_WRITE_TO_OR_TRUNCATE_FILE equ 0x40
INT21H_FUNC_41H_DELETE_NAMED_FILE equ 0x41
INT21H_FUNC_42H_SEEK_IN_FILE    equ 0x42
INT21H_FUNC_43H_GET_OR_CHANGE_ATTRIBUTES equ 0x43
INT21H_FUNC_44H_IOCTL_IN_FILE   equ 0x44
INT21H_FUNC_45H_DUPLICATE_FILE_HANDLE equ 0x45
INT21H_FUNC_47H_GET_CURRENT_DIR equ 0x47
INT21H_FUNC_48H_ALLOCATE_MEMORY equ 0x48
INT21H_FUNC_4CH_EXIT_PROCESS    equ 0x4C
INT21H_FUNC_4EH_FIND_FIRST_MATCHING_FILE equ 0x4E
INT21H_FUNC_4FH_FIND_NEXT_MATCHING_FILE equ 0x4F
INT21H_FUNC_56H_RENAME_FILE     equ 0x56
INT21H_FUNC_57H_GET_SET_FILE_HANDLE_MTIME equ 0x57
INT21H_FUNC_60H_GET_FULL_FILENAME equ 0x60

%if 0  ; TODO(pts): Put to separate .o file.
mini_ftruncate_here:  ; int __cdecl mini_ftruncate_here(int fd);
		push ebx
		xor ecx, ecx  ; Return value in case ECX == 0.
		mov ah, INT21H_FUNC_40H_WRITE_TO_OR_TRUNCATE_FILE
		mov ebx, [esp+8]  ; File descriptor.
		mov edx, [esp+0xc]  ; Data pointer.
		call far [_INT21ADDR]
		jc strict short mini_write.err
		xor eax, eax  ; Also sets CF := 0.
		pop ebx
		ret
%endif

mini_write:  ; ssize_t __cdecl mini_write(int fd, const void *buf, size_t count);
		push ebx
		xor eax, eax  ; Return value in case ECX == 0.
		mov ah, INT21H_FUNC_40H_WRITE_TO_OR_TRUNCATE_FILE
.rw:		mov ecx, [esp+0x10]  ; Number of bytes to write (or read).
		jecxz .done
		mov ebx, [esp+8]  ; File descriptor.
		mov edx, [esp+0xc]  ; Data pointer.
.do_call:	call far [_INT21ADDR]
		jnc .done
.err:		neg eax
		mov [mini_errno], eax
		or eax, -1
.done:		pop ebx
		ret

mini_read:  ; ssize_t __cdecl mini_read(int fd, void *buf, size_t count);
		push ebx
		xor eax, eax
		mov ah, INT21H_FUNC_3FH_READ_FROM_FILE
		jmp strict short mini_write.rw

mini_remove:  ; int __cdecl mini_remove(const char *pathname);
mini_unlink:  ; int __cdecl mini_unlink(const char *pathname);
		push ebx  ; No need to save, but save code size by mergining it with mini_write.
		mov ah, INT21H_FUNC_41H_DELETE_NAMED_FILE
		mov edx, [esp+8]
		jmp strict short mini_write.do_call

mini_close:  ; int __cdecl mini_close(int fd);
		push ebx
		mov ah, INT21H_FUNC_3EH_CLOSE_FILE
		mov ebx, [esp+8]
		jmp strict short mini_write.do_call

mini_lseek:  ; off_t __cdecl mini_lseek(int fd, off_t offset, int whence);
		push ebx
		mov ah, INT21H_FUNC_42H_SEEK_IN_FILE
		mov al, [esp+0x10]  ; Argument whence.
		mov ebx, [esp+8]  ; Argument fd.
		mov ecx, [esp+0xc]  ; High word of offset.
		mov edx, ecx  ; Low word of offset.
		shr ecx, 16
		call far [_INT21ADDR]
		jc strict short mini_write.err
		shl edx, 16
		mov dx, ax
		xchg eax, edx  ; EAX := EDX; EDX := junk.
		pop ebx
		ret

O_RDONLY equ 0
O_WRONLY equ 1
O_RDWR equ 2
LINUX_O_CREAT equ 100q    ; Linux-specific value used by __MINILIBC686__ <fcntl.h>.
LINUX_O_TRUNC equ 1000q   ; Linux-specific value used by __MINILIBC686__ <fcntl.h>.

mini___M_fopen_open:
mini_open:  ; int __cdecl mini_open(const char *pathname, int flags, mode_t mode);  /* The mode argument is optional, it is only used when the file is created. */
		push ebx  ; No need to save, but save code size by mergining it with mini_write.
		mov eax, [esp+0xc]
		mov edx, [esp+8]  ; Filename.
		cmp eax, O_WRONLY|LINUX_O_CREAT|LINUX_O_TRUNC  ; TODO(pts): Reopen it later in actual O_WRONLY mode. INT21H_FUNC_3CH_CREATE_FILE does O_RDWR.
		je .create
		cmp eax, O_RDWR|LINUX_O_CREAT|LINUX_O_TRUNC
		je .create
		test eax, 2  ; Only O_RDONLY, O_WRONLY and O_RDWR are valid.
		ja .mode_error
		mov ah, INT21H_FUNC_3DH_OPEN_FILE  ; Flags in AL.
		jmp .call
.create:	; FYI We ignore the `mode' (permissions) argument. TODO(pts): Extend the ABI to use it on Linux.
		mov ah, INT21H_FUNC_3CH_CREATE_FILE
		xor ecx, ecx  ; Create a regular file.
.call:		call far [_INT21ADDR]
		jc strict short mini_write.err
		jmp .done		
.mode_error:	push 0xc  ; Invalid access mode (open mode is invalid). https://stanislavs.org/helppc/dos_error_codes.html
		pop dword [mini_errno]
		or eax, -1
.done:		pop ebx
		ret

mini_creat:  ; int __cdecl creat(const char *pathname, mode_t mode);
		push dword [esp+8]  ; Argument mode.
		push O_RDWR|LINUX_O_CREAT|LINUX_O_TRUNC  ; Argument flags.
		push dword [esp+8]  ; Argument pathname.
		call mini_open
		add esp, 0xc  ; Clear arguments of mini_open.
		ret

mini_malloc_simple_unaligned:  ; void * __cdecl mini_malloc_simple_unaligned(size_t size);
		push ebx
		mov ebx, [esp+8]
		mov ah, INT21H_FUNC_48H_ALLOCATE_MEMORY
		call far [_INT21ADDR]
		jnc .done
		neg eax
		mov [mini_errno], eax
		xor eax, eax
.done:		pop ebx
		ret

mini_time:  ; time_t __cdecl mini_time(time_t *tloc);
		mov ecx, [esp+4]
		xor eax, eax
		inc eax  ; Fake timestamp value. !! TODO(pts): Extend the ABI to return real value.
		jecxz .after_set
		mov [ecx], eax
.after_set:	ret

mini_strerror:  ; char * __cdecl mini_strerror(int errnum);
		mov eax, msg_fake_error  ; !! Use a DOS-like or Win32-like error cods table (also for errno.h), existing loaders are likely to return those: https://stanislavs.org/helppc/dos_error_codes.html
		ret

section .rodata
msg_fake_error:	db 'Error', 0
section .text

mini_isatty:  ; int __cdecl isatty(int fd);
		push ebx
		mov ax, INT21H_FUNC_44H_IOCTL_IN_FILE<<8  ; AL=0 means get info.
		mov ebx, [esp+8]
		call far [_INT21ADDR]
		jc .error
		xor eax, eax
		shr dl, 8 ; 0x80 indicates character device, we assume it's a TTY.
		rcl al, 1
		jmp .done
.error:		neg eax
		mov [mini_errno], eax
		xor eax, eax
.done:		pop ebx
		ret

%if 0  ; TODO(pts): Put to separate .o file.
mini_ftruncate:  ; int __cdecl ftruncate(int fd, off_t size);
		push ebx
		push ecx
		push esi
		mov esi, edx  ; Save argument size.
		xchg ebx, eax  ; EBX := EAX (filehandle); EBX := junk.
		mov ax, 4201h  ; SEEK_CUR.
		xor ecx, ecx
		xor edx, edx
		call far [_INT21ADDR]
		jc .done
		xchg edx, eax  ; DX := AX (low word); AX := (high word).
		xchg ecx, eax  ; CX := AX (high word); AX := junk.
		push ecx
		push edx
		mov edx, esi
		mov ecx, esi
		shr ecx, 16
		mov ax, 4200h  ; SEEK_SET to ESI.
		call far [_INT21ADDR]
		jc .done
		mov ah, 40h
		xor ecx, ecx
		call far [_INT21ADDR]  ; Truncate.
		jc .done
		pop edx
		pop ecx
		mov ax, 4200h  ; SEEK_SET back.
		call far [_INT21ADDR]
.done:		sbb eax, eax
		pop esi
		pop ecx
		pop ebx
		ret
%endif

; This is a helper function used by _start.
;
; Reverses the elements in a NULL-terminated array of (void*)s.
global reverse_ptrs  ; In case it is useful for the program.
reverse_ptrs:  ; void __watcall reverse_ptrs(void **p);
		push ecx
		push edx
		lea edx, [eax-4]
.next1:		add edx, 4
		cmp dword [edx], 0
		jne short .next1
		cmp edx, eax
		je short .nothing
		sub edx, 4
		jmp short .cmp2
.next2:		mov ecx, [eax]
		xchg ecx, [edx]
		mov [eax], ecx
		add eax, 4
		sub edx, 4
.cmp2:		cmp eax, edx
		jb short .next2
.nothing:	pop edx
		pop ecx
.ret:
		ret

; This is a helper function used by _start.
;
; /* Parses the first argument of the Windows command-line (specified in EAX)
;  * in place. Returns (in EAX) the pointer to the rest of the command-line.
;  * The parsed argument will be available as NUL-terminated string at the
;  * same location as the input.
;  *
;  * Similar to CommandLineToArgvW(...) in SHELL32.DLL, but doesn't aim for
;  * 100% accuracy, especially that it doesn't support non-ASCII characters
;  * beyond ANSI well, and that other implementations are also buggy (in
;  * different ways).
;  *
;  * It treats only space and tab and a few others as whitespece. (The Wine
;  * version of CommandLineToArgvA.c treats only space and tab as whitespace).
;  *
;  * This is based on the incorrect and incomplete description in:
;  *  https://learn.microsoft.com/en-us/windows/win32/api/shellapi/nf-shellapi-commandlinetoargvw
;  *
;  * See https://nullprogram.com/blog/2022/02/18/ for a more detailed writeup
;  * and a better installation.
;  *
;  * https://github.com/futurist/CommandLineToArgvA/blob/master/CommandLineToArgvA.c
;  * has the 3*n rule, which Wine 1.6.2 doesn't seem to have. It also has special
;  * parsing rules for argv[0] (the program name).
;  *
;  * There is the CommandLineToArgvW function in SHELL32.DLL available since
;  * Windows NT 3.5 (not in Windows NT 3.1). For alternative implementations,
;  * see:
;  *
;  * * https://github.com/futurist/CommandLineToArgvA
;  *   (including a copy from Wine sources).
;  * * http://alter.org.ua/en/docs/win/args/
;  * * http://alter.org.ua/en/docs/win/args_port/
;  */
; static char * __watcall parse_first_arg(char *pw) {
;   const char *p;
;   const char *q;
;   char c;
;   char is_quote = 0;
;   for (p = pw; c = *p, c == ' ' || c == '\t' || c == '\n' || c == '\v'; ++p) {}
;   if (*p == '\0') { *pw = '\0'; return pw; }
;   for (;;) {
;     if ((c = *p) == '\0') goto after_arg;
;     ++p;
;     if (c == '\\') {
;       for (q = p; c = *q, c == '\\'; ++q) {}
;       if (c == '"') {
;         for (; p < q; p += 2) {
;           *pw++ = '\\';
;         }
;         if (p != q) {
;           is_quote ^= 1;
;         } else {
;           *pw++ = '"';
;           ++p;  /* Skip over the '"'. */
;         }
;       } else {
;         *pw++ = '\\';
;         for (; p != q; ++p) {
;           *pw++ = '\\';
;         }
;       }
;     } else if (c == '"') {
;       is_quote ^= 1;
;     } else if (!is_quote && (c == ' ' || c == '\t' || c == '\n' || c == '\v')) {
;       if (p - 1 != pw) --p;  /* Don't clobber the rest with '\0' below. */
;      after_arg:
;       *pw = '\0';
;       return (char*)p;
;     } else {
;       *pw++ = c;  /* Overwrite in-place. */
;     }
;   }
; }
parse_first_arg:  ; static char * __watcall parse_first_arg(char *pw);
		push ebx
		push ecx
		push edx
		push esi
		xor bh, bh  ; is_quote.
		mov edx, eax
.1:		mov bl, [edx]
		cmp bl, ' '
		je short .2  ; The inline assembler is not smart enough with forward references, we need these shorts.
		cmp bl, 0x9
		jb short .3
		cmp bl, 0xb
		ja short .3
.2:		inc edx
		jmp short .1
.3:		test bl, bl
		jne short .8
		mov [eax], bl
		jmp short .ret
.4:		cmp bl, '"'
		jne short .11
.5:		lea esi, [eax+0x1]
		cmp edx, ecx
		jae short .6
		mov byte [eax], 0x5c  ; "\\"
		mov eax, esi
		inc edx
		inc edx
		jmp short .5
.6:		je short .10
.7:		xor bh, 0x1
.8:		mov bl, [edx]
		test bl, bl
		je short .16
		inc edx
		cmp bl, 0x5c  ; "\\"
		jne short .13
		mov ecx, edx
.9:		mov bl, [ecx]
		cmp bl, 0x5c  ; "\\"
		jne short .4
		inc ecx
		jmp short .9
.10:		mov byte [eax], '"'
		mov eax, esi
		lea edx, [ecx+0x1]
		jmp short .8
.11:		mov byte [eax], 0x5c  ; "\\"
		inc eax
.12:		cmp edx, ecx
		je short .8
		mov byte [eax], 0x5c  ; "\\"
		inc eax
		inc edx
		jmp short .12
.13:		cmp bl, '"'
		je short .7
		test bh, bh
		jne short .15
		cmp bl, ' '
		je short .14
		cmp bl, 0x9
		jb short .15
		cmp bl, 0xb
		jna short .14
.15:		mov [eax], bl
		inc eax
		jmp short .8
.14:		dec edx
		cmp eax, edx
		jne .16
		inc edx
.16:		mov byte [eax], 0x0
		xchg eax, edx  ; EAX := EDX: EDX := junk.
.ret:		pop esi
		pop edx
		pop ecx
		pop ebx
		ret

; __END__
