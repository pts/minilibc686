;
; written by pts@fazekas.hu at Mon Jul  3 23:44:28 CEST 2023
; Compile to i386 ELF .o object: nasm -O999999999 -w+orphan-labels -f elf -o strerror_few_linux.o strerror_few_linux.nasm
;
; Code+data size: 0x314 bytes.
;
; Uses: %ifdef CONFIG_PIC
;

bits 32
cpu 386

global mini_strerror_few
%ifdef CONFIG_SECTIONS_DEFINED
%elifidn __OUTPUT_FORMAT__, bin
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

section .rodata
errmsgs_from_1:
		db 'Operation not permitted', 0		     ; EPERM == 1
		db 'No such file or directory', 0	     ; ENOENT
		db 'No such process', 0			     ; ESRCH
		db 'Interrupted system call', 0		     ; EINTR
		db 'Input/output error', 0		     ; EIO
		db 'No such device or address', 0	     ; ENXIO
		db 'Argument list too long', 0		     ; E2BIG
		db 'Exec format error', 0		     ; ENOEXEC
		db 'Bad file desecriptor', 0		     ; EBADF
		db 'No child processes', 0		     ; ECHILD
		db 'Resource temporarily unavailable', 0     ; EAGAIN
		db 'Cannot allocate memory', 0		     ; ENOMEM
		db 'Permission denied', 0		     ; EACCES
		db 'Bad address', 0			     ; EFAULT
		db 'Block device required', 0		     ; ENOTBLK
		db 'Device or resource busy', 0		     ; EBUSY
		db 'File exists', 0			     ; EEXIST
		db 'Invalid cross-device link', 0	     ; EXDEV
		db 'No such device', 0			     ; ENODEV
		db 'Not a directory', 0			     ; ENOTDIR
		db 'Is a directory', 0			     ; EISDIR
		db 'Invalid argument', 0		     ; EINVAL
		db 'Too many open files in system', 0	     ; ENFILE
		db 'Too many open files', 0		     ; EMFILE
		db 'Inappropriate ioctl for device', 0	     ; ENOTTY
		db 'Text file busy', 0			     ; ETXTBSY
		db 'File too large', 0			     ; EFBIG
		db 'No space left on device', 0		     ; ENOSPC
		db 'Illegal seek', 0			     ; ESPIPE
		db 'Read-only file system', 0		     ; EROFS
		db 'Too many links', 0			     ; EMLINK
		db 'Broken pipe', 0			     ; EPIPE
		db 'Numerical argument out of domain', 0     ; EDOM
		db 'Numerical result out of range', 0	     ; ERANGE
		db '?', 0				     ; EDEADLK ; 'Resource deadlock avoided'. This is not common enough.
		db 'File name too long', 0		     ; ENAMETOOLONG
		db 'No locks available', 0		     ; ENOLCK
		db 'Function not implemented', 0	     ; ENOSYS
		db 'Directory not empty', 0		     ; ENOTEMPTY
		db 'Too many symbolic links encountered', 0  ; ELOOP == 40
		; Anything above that is too unusual. We'll return unknown_error instead.
		db 0
unknown_error:	db '?', 0  ; uClibc 0.9.30.1 and libc 2.27 return e.g. 'Unknown error 321'. minilibc strerror(3) returns 'Unknown error', we just return '?'.

section .text
mini_strerror_few:  ; char *strerror_few(int errnum);
		mov ecx, [esp+4]  ; Argument s.
		mov eax, errmsgs_from_1
.next_msg:	dec ecx
		jz short .found
.skip_char:	inc eax
		cmp byte [eax-1], 0  ; A solution using `scasb' here is not shorter either.
		jne short .skip_char
		cmp byte [eax], 0
		jne short .next_msg
		inc eax  ; EAX := unknown_error.
.found:		ret

%ifdef CONFIG_PIC
%error Not PIC because it uses the global errmsgs_from_1 constant.
times 1/0 nop
%endif

; __END__
