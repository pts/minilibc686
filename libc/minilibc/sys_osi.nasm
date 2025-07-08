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

%ifndef CONFIG_WRITE_BINARY
  %ifndef __NEED_mini_write
    %define CONFIG_WRITE_BINARY  ; The default is the simpled -DCONFIG_WRITE_BINARY.
  %endif
%endif
%ifndef CONFIG_WRITE_BINARY
  %ifndef __NEED_mini_isatty
    %define NEED_mini_isatty  ; Needed.
  %endif
%endif
%ifdef __NEED_mini_isatty
  %define NEED_mini_isatty
%endif
%ifdef __NEED_mini_creat
  %define __NEED_mini___M_fopen_open
%endif
%ifdef __NEED_mini_unlink
  %define NEED_mini_unlink_or_remove
%endif
%ifdef __NEED_mini_remove
  %define NEED_mini_unlink_or_remove
%endif
%ifdef __NEED__start
  %define NEED_mini_exit
  %define NEED__start
%endif
%ifdef __NEED_mini_start
  %define NEED_mini_exit
  %define NEED__start
%endif
%ifdef __NEED_mini_exit
  %define NEED_mini_exit
%endif
%ifdef NEED_mini_exit
  %define NEED_mini__exit
%endif
%ifdef __NEED_mini__exit
  %define NEED_mini__exit
%endif
%ifdef NEED__start
  %define NEED_reverse_ptrs
  %define NEED_parse_first_arg
%endif
%ifdef __NEED_mini_write
  %define NEED_write_binary
%endif
%ifdef __NEED_mini_write_binary
  %define NEED_write_binary
%endif

bits 32
cpu 386

section .text align=1
section .rodata align=1
section .data align=1
section .bss align=4

%ifdef __NEED__INT21ADDR
  global _INT21ADDR
%endif
%ifdef __NEED___OS
  global __OS
%endif
%ifdef __NEED__STACKTOP
  global _STACKTOP
%endif
%ifdef __NEED__BreakFlagPtr
  global _BreakFlagPtr
%endif

section .text

section .bss
_INT21ADDR:	resb 6  ; void (__far *_INT21ADDR)(void);
__OS:		resb 1  ; char __OS;
		resb 1  ; Align to multiple of 4.
_STACKTOP:	resd 1  ; void *_STACKTOP;
_BreakFlagPtr:	resd 1  ; unsigned *_BreakFlagPtr;
;__EnvPtr:	resd 1  ; char **_EnvPtr;
%ifdef __NEED_mini_environ
  global mini_environ
  mini_environ:	resd 1  ; char **environ;
%endif
;_LpPgmName:	resd 1  ; char *_LpPgmName;
%ifndef CONFIG_WRITE_BINARY
  mini___M_isatty_bitset: resb 1  ; (is_stdout_tty ? 1 : 0) | (is_stderr_tty ? 2 : 0).
%endif
section .text

%ifdef __NEED__start
  global _start
%endif
%ifdef __NEED_mini_start
  global mini_start
%endif
%ifdef NEED__start
  _start:
  mini__start: ; __OSI__ program entry point.
		; Zero-initialize BSS. !! TODO(pts): The WCFD32 loader has done it.
  %if 0  ; Not needed, The OIX ABI guarantees NUL bytes in BSS.
		push edx
		push edi
		push eax
		mov ecx, _end		; end of BSS section (start of free)
		mov edi, _edata		; start of BSS section
		sub ecx, edi		; calc # of bytes in BSS section
		xor eax, eax		; zero the BSS section
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
  %ifndef CONFIG_WRITE_BINARY
		push byte 1  ; STDOUT_FILENO.
		call mini_isatty
		pop edx  ; Clean up argument of mini_isatty above from the stack.
		xchg edi, eax  ; EDI := (is_stdout_tty ? 1 : 0); EAX := junk.
		push byte 2  ; STDERR_FILENO.
		call mini_isatty
		pop edx  ; Clean up argument of mini_isatty above from the stack.
		lea eax, [edi+2*eax]  ; EAX := (is_stdout_tty ? 1 : 0) | (is_stderr_tty ? 2 : 0).
		mov [mini___M_isatty_bitset], al
  %endif
  extern main  ; extern int __cdecl main(int argc, char **argv);
		call main  ; Return value (exit code) in EAX (AL).
		push eax  ; Save exit code, for mini__exit.
		push eax  ; Fake return address, for mini__exit.
		; Fall through to mini_exit(...).
%endif  ; %ifdef __NEED_start
%ifdef __NEED_mini_exit
  global mini_exit
%endif
%ifdef NEED_mini_exit
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
%endif
%ifdef __NEED_mini__exit
  global mini__exit
%endif
%ifdef NEED_mini__exit
  mini__exit:  ; void mini__exit(int exit_code);
		mov eax, [esp+4]
		mov esp, [_STACKTOP]
		retf
%endif

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

%ifdef __NEED_mini_ftruncate_here  ; !! TODO(pts): Like in Win32, if the file is growing, add NUL bytes explicitly.
  global mini_ftruncate_here
  mini_ftruncate_here:  ; int __cdecl mini_ftruncate_here(int fd);
		push ebx
		xor ecx, ecx  ; Return value in case ECX == 0.
		mov ah, INT21H_FUNC_40H_WRITE_TO_OR_TRUNCATE_FILE
		mov ebx, [esp+8]  ; File descriptor.
		mov edx, [esp+0xc]  ; Data pointer.
		call far [_INT21ADDR]
		jc strict short write_binary.err
		xor eax, eax  ; Also sets CF := 0.
		pop ebx
		ret
%endif

%ifdef __NEED_mini_write
  %ifdef CONFIG_WRITE_BINARY
    global mini_write  ; Writes the specified bytes to the specified fd.
    mini_write:  ; ssize_t __cdecl mini_write(int fd, const void *buf, size_t count);
  %endif
%endif
%ifdef __NEED_mini_write_binary
  global mini_write_binary
  mini_write_binary:  ; ssize_t __cdecl mini_write_binary(int fd, const void *buf, size_t count);
%endif
%ifdef NEED_write_binary
  write_binary:  ; static ssize_t __cdecl write_binary(int fd, const void *buf, size_t count);
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
  .done:	pop ebx
		ret
%endif

%ifdef __NEED_mini_read
  global mini_read
  mini_read:  ; ssize_t __cdecl mini_read(int fd, void *buf, size_t count);
		push ebx
		xor eax, eax
		mov ah, INT21H_FUNC_3FH_READ_FROM_FILE
		jmp strict short write_binary.rw
%endif

%ifdef __NEED_mini_unlink
  global mini_unlink
%endif
%ifdef __NEED_mini_remove
  global mini_remove
%endif
%ifdef NEED_mini_unlink_or_remove
  mini_unlink:  ; int __cdecl mini_unlink(const char *pathname);
  mini_remove:  ; int __cdecl mini_remove(const char *pathname);
		push ebx  ; No need to save, but save code size by mergining it with write_binary.
		mov ah, INT21H_FUNC_41H_DELETE_NAMED_FILE
		mov edx, [esp+8]
		jmp strict short write_binary.do_call
%endif

%ifdef __NEED_mini_close
  global mini_close
  mini_close:  ; int __cdecl mini_close(int fd);
		push ebx
		mov ah, INT21H_FUNC_3EH_CLOSE_FILE
		mov ebx, [esp+8]
		jmp strict short write_binary.do_call
%endif

%ifdef __NEED_mini_lseek  ; !! TODO(pts): Like in Win32, if the file is growing, add NUL bytes explicitly.
  global mini_lseek
  mini_lseek:  ; off_t __cdecl mini_lseek(int fd, off_t offset, int whence);
		push ebx
		mov ah, INT21H_FUNC_42H_SEEK_IN_FILE
		mov al, [esp+0x10]  ; Argument whence.
		mov ebx, [esp+8]  ; Argument fd.
		mov ecx, [esp+0xc]  ; High word of offset.
		mov edx, ecx  ; Low word of offset.
		shr ecx, 16
		call far [_INT21ADDR]
		jc strict short write_binary.err
		shl edx, 16
		mov dx, ax
		xchg eax, edx  ; EAX := EDX; EDX := junk.
		pop ebx
		ret
%endif

O_RDONLY equ 0
O_WRONLY equ 1
O_RDWR equ 2
LINUX_O_CREAT equ 100q    ; Linux-specific value used by __MINILIBC686__ <fcntl.h>.
LINUX_O_TRUNC equ 1000q   ; Linux-specific value used by __MINILIBC686__ <fcntl.h>.

%ifdef __NEED_mini___M_fopen_open
  global mini___M_fopen_open  ; Minimalist open(2) (only a few flag combinations are allowed) which can serve mini_fopen(3).
  mini___M_fopen_open:  ; int __cdecl mini___M_fopen_open(const char *pathname, int flags, mode_t mode);  /* The mode argument is optional, it is only used when the file is created. */
  ;mini_open:  ; int __cdecl mini_open(const char *pathname, int flags, mode_t mode);  /* The mode argument is optional, it is only used when the file is created. */
		push ebx  ; No need to save, but save code size by mergining it with write_binary.
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
  .call:	call far [_INT21ADDR]
		jc strict short write_binary.err
		jmp .done		
  .mode_error:	push 0xc  ; Invalid access mode (open mode is invalid). https://stanislavs.org/helppc/dos_error_codes.html
		pop dword [mini_errno]
		or eax, -1
  .done:	pop ebx
		ret
%endif

%ifdef __NEED_mini_write
  %ifndef CONFIG_WRITE_BINARY
    global mini_write  ; Writes the specified bytes, maybe converting LF to CRLF to the specified fd.
    mini_write:  ; ssize_t __cdecl mini_write(int fd, const void *buf, size_t count);
		;cmp dword [eax+3*4], byte 0  ; count.
		;jz short write_binary
		mov eax, [esp+1*4]  ; Argument fd.
		dec eax
		cmp eax, 2
		jnc short write_binary  ; Jumps iff EAX (fd) is not 1 (stdout) or 2 (stderr).
		inc eax
		test [mini___M_isatty_bitset], al
		jz short write_binary  ; Jumps iff EAX (fd) is not a TTY. This with the `test' above works only if EAX == 1 or EAX == 2.
		; We will find all instances of LF, and split to multiple
		; writes, e.g. write("foo\nbar") will be split to
		; write_binary("foo"), write_binary("\r"),
		; write_binary("\nbar").
		mov edx, [esp+2*4]  ; Argument buf.
		mov ecx, [esp+3*4]  ; Argument count.
		push esi  ; Save.
		push edi  ; Save.
		mov edi, edx  ; EDI := buf. It will keep holding the original buf until .done.
		mov esi, edx  ; ESI := buf.
		add ecx, edx  ; ECX := buf+count. It will keep holding the original+count buf until .done unless saved+restored.
		dec esi  ; Cancel the effect of the `inc esi' following this.
    .next_byte:	inc esi
		cmp esi, ecx
		je short .write_block
		cmp [esi], byte 10  ; LF, '\n'.
		jne .next_byte
    .write_block:  ; Write the memory region EDX..ESI to fd EAX.
		cmp edx, esi
		je short .check_end  ; Skip writing 0 bytes.
		push eax  ; Save fd.
		push ecx  ; Save.
		push edx  ; Save.
		push esi
		sub [esp], edx  ; Argument count.
		push edx  ; Argument buf.
		push eax  ; Argument fd.
		call write_binary  ; Write bytes until the first LF.
		add esp, byte 3*4  ; Clean up arguments of write_binary above from the stack.
		pop edx  ; Restore.
		cmp eax, byte -1
		je short .skip_add
		add edx, eax
    .skip_add:	cmp eax, ecx
		pop ecx  ; Restore.
		pop eax  ; Restore EAX := fd.
		jne short .done  ; Jump iff the write_binary(...) above has returned short write or error.
    .check_end:	cmp esi, ecx
		je short .done  ; Jump iff everything has been written.
		push eax  ; Save fd.
		push ecx  ; Save.
		push edx  ; Save.
		push byte 13  ; CR, '\r'.
		mov edx, esp
		push byte 1  ; Argument count.
		push edx  ; Argument buf.
		push eax  ; Argument fd.
		call write_binary
		add esp, byte 4*4  ; Clean up arguments of write_binary above and the CR from the stack.
		pop edx  ; Restore.
		pop ecx  ; Restore.
		dec eax
		pop eax  ; Restore EAX := fd.
		jz short .next_byte  ; Jump iff the write_binary(...) above has returned 1. (i.e. no on short write, no error). Since .next_byte starts with `inc esi', it won't stop at the LF at byte [esi].
    .done:	sub edx, edi  ; EDX := total number of bytes written (ignoring the manually added CR bytes).
		jnz short .edx_ok
		dec edx  ; EDX := -1, indicating error.
    .edx_ok:    xchg eax, edx  ; EAX := total number of bytes written (ignoring the manually added CR bytes); EDX := junk.
		pop edi  ; Restore.
		pop esi  ; Restore.
		ret
  %endif
%endif

%ifdef __NEED_mini_creat
  global mini_creat
  mini_creat:  ; int __cdecl creat(const char *pathname, mode_t mode);
		push dword [esp+8]  ; Argument mode.
		push O_RDWR|LINUX_O_CREAT|LINUX_O_TRUNC  ; Argument flags.
		push dword [esp+8]  ; Argument pathname.
		call mini___M_fopen_open
		add esp, 0xc  ; Clear arguments of mini_open.
		ret
%endif

%ifdef __NEED_mini_malloc_simple_unaligned
  global mini_malloc_simple_unaligned
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
%endif

%ifdef __NEED_mini_time
  global mini_time
  mini_time:  ; time_t __cdecl mini_time(time_t *tloc);
		mov ecx, [esp+4]
		xor eax, eax
		inc eax  ; Fake timestamp value. !! TODO(pts): Extend the ABI to return real value.
		jecxz .after_set
		mov [ecx], eax
.after_set:	ret
%endif

%ifdef __NEED_mini_strderror
  global mini_strderror
  mini_strerror:  ; char * __cdecl mini_strerror(int errnum);
		mov eax, msg_fake_error  ; !! Use a DOS-like or Win32-like error cods table (also for errno.h), existing loaders are likely to return those: https://stanislavs.org/helppc/dos_error_codes.html
		ret
%endif

section .rodata
msg_fake_error:	db 'Error', 0
section .text

%ifdef __NEED_mini_isatty
  global mini_isatty
%endif
%ifdef NEED_mini_isatty
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
  .error:	neg eax
		mov [mini_errno], eax
		xor eax, eax
  .done:	pop ebx
		ret
%endif

%ifdef __NEED_mini_ftruncate  ; !! TODO(pts): Like in Win32, if the file is growing, add NUL bytes explicitly.
  global mini_ftruncate
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
  .done:	sbb eax, eax
		pop esi
		pop ecx
		pop ebx
		ret
%endif

%ifdef NEED_reverse_ptrs
  ; This is a helper function used by _start.
  ;
  ; Reverses the elements in a NULL-terminated array of (void*)s.
  ;global reverse_ptrs  ; In case it is useful for the program.
  reverse_ptrs:  ; void __watcall reverse_ptrs(void **p);
		push ecx
		push edx
		lea edx, [eax-4]
  .next1:	add edx, 4
		cmp dword [edx], 0
		jne short .next1
		cmp edx, eax
		je short .nothing
		sub edx, 4
		jmp short .cmp2
  .next2:	mov ecx, [eax]
		xchg ecx, [edx]
		mov [eax], ecx
		add eax, 4
		sub edx, 4
  .cmp2:	cmp eax, edx
		jb short .next2
  .nothing:	pop edx
		pop ecx
  .ret:		ret
%endif

%ifdef NEED_parse_first_arg
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
%endif

; __END__
