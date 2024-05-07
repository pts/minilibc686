;
; written by pts@fazekas.hu at Mon Jul  3 23:44:28 CEST 2023
; Compile to i386 ELF .o object: nasm -O999999999 -w+orphan-labels -f elf -o strerror_linux.o strerror_linux.nasm
;
; Uses: %ifdef CONFIG_PIC
; Uses: %ifdef CONFIG_STRERROR_SMALL  ; 0x21 bytes smaller, much slower.
;

bits 32
cpu 386

global mini_strerror
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
unknown_error:	db 'Unknown error', 0  ; uClibc 0.9.30.1 and libc 2.27 return e.g. 'Unknown error 321'. We just return 'Unknown error'.

%define ERRMSG_BATCH_SIZE_BASE 4
%assign ERRMSG_BATCH_SIZE 1<<ERRMSG_BATCH_SIZE_BASE

%assign ERRMSG_COUNT 0
%assign ERRMSG_CURRENT_BATCH_SIZE 0
%assign ERRMSG_CURRENT_BATCH_OFFSET 0
%assign ERRMSG_OFFSET 0
%assign ERRMSG_BATCH_COUNT 0
%define ERRMSG_BATCH_OFFSETS
%macro errmsg 2
  %%s:		db %1, 0
  %assign ERRMSG_OFFSET ERRMSG_OFFSET+($-%%s)
  %assign ERRMSG_COUNT ERRMSG_COUNT+1
  %assign ERRMSG_CURRENT_BATCH_SIZE ERRMSG_CURRENT_BATCH_SIZE+1
  %if ERRMSG_CURRENT_BATCH_SIZE==ERRMSG_BATCH_SIZE
    %assign ERRMSG_BATCH_COUNT ERRMSG_BATCH_COUNT+1
    %xdefine ERRMSG_BATCH_OFFSETS ERRMSG_BATCH_OFFSETS ERRMSG_CURRENT_BATCH_OFFSET,
    %assign ERRMSG_CURRENT_BATCH_SIZE 0
    %assign ERRMSG_CURRENT_BATCH_OFFSET ERRMSG_OFFSET
  %endif
%endmacro

; Error messages copied from glibc 2.27. diet libc error message strings are a bit different.
; 0xc59 bytes in 134 messages.
; Message pointers would be 0x218 bytes.
;
; TODO(pts): Provide a shorter implementation with the most common file I/O messages.
errmsgs:	errmsg '', 0  ; 'Success', 0  ; Match glibc with the empty strings.
		errmsg 'Operation not permitted', 1
		errmsg 'No such file or directory', 2
		errmsg 'No such process', 3
		errmsg 'Interrupted system call', 4
		errmsg 'Input/output error', 5
		errmsg 'No such device or address', 6
		errmsg 'Argument list too long', 7
		errmsg 'Exec format error', 8
		errmsg 'Bad file descriptor', 9
		errmsg 'No child processes', 10
		errmsg 'Resource temporarily unavailable', 11
		errmsg 'Cannot allocate memory', 12
		errmsg 'Permission denied', 13
		errmsg 'Bad address', 14
		errmsg 'Block device required', 15
		errmsg 'Device or resource busy', 16
		errmsg 'File exists', 17
		errmsg 'Invalid cross-device link', 18
		errmsg 'No such device', 19
		errmsg 'Not a directory', 20
		errmsg 'Is a directory', 21
		errmsg 'Invalid argument', 22
		errmsg 'Too many open files in system', 23
		errmsg 'Too many open files', 24
		errmsg 'Inappropriate ioctl for device', 25
		errmsg 'Text file busy', 26
		errmsg 'File too large', 27
		errmsg 'No space left on device', 28
		errmsg 'Illegal seek', 29
		errmsg 'Read-only file system', 30
		errmsg 'Too many links', 31
		errmsg 'Broken pipe', 32
		errmsg 'Numerical argument out of domain', 33
		errmsg 'Numerical result out of range', 34
		errmsg 'Resource deadlock avoided', 35
		errmsg 'File name too long', 36
		errmsg 'No locks available', 37
		errmsg 'Function not implemented', 38
		errmsg 'Directory not empty', 39
		errmsg 'Too many levels of symbolic links', 40
		errmsg 'Unknown error 41', 41
		;errmsg 'Operation would block', 41  ; No E... constant.
		errmsg 'No message of desired type', 42
		errmsg 'Identifier removed', 43
		errmsg 'Channel number out of range', 44
		errmsg 'Level 2 not synchronized', 45
		errmsg 'Level 3 halted', 46
		errmsg 'Level 3 reset', 47
		errmsg 'Link number out of range', 48
		errmsg 'Protocol driver not attached', 49
		errmsg 'No CSI structure available', 50
		errmsg 'Level 2 halted', 51
		errmsg 'Invalid exchange', 52
		errmsg 'Invalid request descriptor', 53
		errmsg 'Exchange full', 54
		errmsg 'No anode', 55
		errmsg 'Invalid request code', 56
		errmsg 'Invalid slot', 57
		errmsg 'Unknown error 58', 58
		;errmsg 'File locking deadlock error', 58  ; No E... constant.
		errmsg 'Bad font file format', 59
		errmsg 'Device not a stream', 60
		errmsg 'No data available', 61
		errmsg 'Timer expired', 62
		errmsg 'Out of streams resources', 63
		errmsg 'Machine is not on the network', 64
		errmsg 'Package not installed', 65
		errmsg 'Object is remote', 66
		errmsg 'Link has been severed', 67
		errmsg 'Advertise error', 68
		errmsg 'Srmount error', 69
		errmsg 'Communication error on send', 70
		errmsg 'Protocol error', 71
		errmsg 'Multihop attempted', 72
		errmsg 'RFS specific error', 73
		errmsg 'Bad message', 74
		errmsg 'Value too large for defined data type', 75
		errmsg 'Name not unique on network', 76
		errmsg 'File descriptor in bad state', 77
		errmsg 'Remote address changed', 78
		errmsg 'Can not access a needed shared library', 79
		errmsg 'Accessing a corrupted shared library', 80
		errmsg '.lib section in a.out corrupted', 81
		errmsg 'Attempting to link in too many shared libraries', 82
		errmsg 'Cannot exec a shared library directly', 83
		errmsg 'Invalid or incomplete multibyte or wide character', 84
		errmsg 'Interrupted system call should be restarted', 85
		errmsg 'Streams pipe error', 86
		errmsg 'Too many users', 87
		errmsg 'Socket operation on non-socket', 88
		errmsg 'Destination address required', 89
		errmsg 'Message too long', 90
		errmsg 'Protocol wrong type for socket', 91
		errmsg 'Protocol not available', 92
		errmsg 'Protocol not supported', 93
		errmsg 'Socket type not supported', 94
		errmsg 'Operation not supported', 95
		errmsg 'Protocol family not supported', 96
		errmsg 'Address family not supported by protocol', 97
		errmsg 'Address already in use', 98
		errmsg 'Cannot assign requested address', 99
		errmsg 'Network is down', 100
		errmsg 'Network is unreachable', 101
		errmsg 'Network dropped connection on reset', 102
		errmsg 'Software caused connection abort', 103
		errmsg 'Connection reset by peer', 104
		errmsg 'No buffer space available', 105
		errmsg 'Transport endpoint is already connected', 106
		errmsg 'Transport endpoint is not connected', 107
		errmsg 'Cannot send after transport endpoint shutdown', 108
		errmsg 'Too many references: cannot splice', 109
		errmsg 'Connection timed out', 110
		errmsg 'Connection refused', 111
		errmsg 'Host is down', 112
		errmsg 'No route to host', 113
		errmsg 'Operation already in progress', 114
		errmsg 'Operation now in progress', 115
		errmsg 'Stale file handle', 116
		errmsg 'Structure needs cleaning', 117
		errmsg 'Not a XENIX named type file', 118
		errmsg 'No XENIX semaphores available', 119
		errmsg 'Is a named type file', 120
		errmsg 'Remote I/O error', 121
		errmsg 'Disk quota exceeded', 122
		errmsg 'No medium found', 123
		errmsg 'Wrong medium type', 124
		errmsg 'Operation canceled', 125
		errmsg 'Required key not available', 126
		errmsg 'Key has expired', 127
		errmsg 'Key has been revoked', 128
		errmsg 'Key was rejected by service', 129
		errmsg 'Owner died', 130
		errmsg 'State not recoverable', 131
		errmsg 'Operation not possible due to RF-kill', 132
		errmsg 'Memory page has hardware error', 133

%ifdef CONFIG_STRERROR_SMALL
%else
  %if ERRMSG_CURRENT_BATCH_SIZE
    %assign ERRMSG_BATCH_COUNT ERRMSG_BATCH_COUNT+1
    %xdefine ERRMSG_BATCH_OFFSETS ERRMSG_BATCH_OFFSETS ERRMSG_CURRENT_BATCH_OFFSET,
  %endif
  errmsg_batches: dw ERRMSG_BATCH_OFFSETS
%endif

section .text
mini_strerror:  ; char *strerror(int errnum);
		mov edx, [esp+4]  ; Argument s.
		cmp edx, ERRMSG_COUNT
		jb .small
		mov eax, unknown_error
		ret
.small:		push edi
		; We don't store pointers to individual error messages, that
		; would be at least 2*134 == 0x10c bytes of data. Instead of
		; that, we store a 2-byte pointer for each ERRMSG_BATCH_SIZE
		; error messages, with a total storage of 0x12 bytes.
%ifdef CONFIG_STRERROR_SMALL
		mov edi, errmsgs
%else
		mov edi, edx
		shr edi, ERRMSG_BATCH_SIZE_BASE
		movzx edi, word [edi+edi+errmsg_batches]
		add edi, errmsgs
		and edx, byte ERRMSG_BATCH_SIZE-1
%endif
		or ecx, byte -1  ; Unlimited, for `repne scasb'.
		xor eax, eax  ; AL := 0 for the scasb.
.again:		sub edx, byte 1
		jc .done
		repne scasb
		jmp short .again
.done:		xchg edi, eax  ; EAX := EDI; EDI := junk.
		pop edi
		ret

%ifdef CONFIG_PIC
%error Not PIC because it uses the global errmsgs constant.
times 1/0 nop
%endif

; __END__
