#
# converted from start_stdio_medium_linux.nasm at Tue May 23 22:19:40 CEST 2023
# Compile to i386 ELF .o object: as --32 -march=i386 -o start_stdio_medium_linux_weak.o start_stdio_medium_linux.s
#
# Uses: %ifdef CONFIG_PIC
#

.global _start
.global mini__start
.global mini__exit
.global mini_syscall3_AL
.global mini_syscall3_RP1
.global mini_exit
.global mini_open
.global mini_close
.global mini_read
.global mini_write
.global mini_lseek
.global mini_ioctl
.weak mini___M_start_isatty_stdin  # Falback, will be converted to a weak symbol.
.weak mini___M_start_isatty_stdout  # Falback, will be converted to a weak symbol.
.weak mini___M_start_flush_stdout  # Falback, will be converted to a weak symbol.
.weak mini___M_start_flush_opened  # Falback, will be converted to a weak symbol.

.text
_start:
mini__start:  # Entry point (_start) of the Linux i386 executable.
		# Now the stack looks like (from top to bottom):
		#   dword [esp]: argc
		#   dword [esp+4]: argv[0] pointer
		#   esp+8...: argv[1..] pointers
		#   NULL that ends argv[]
		#   environment pointers
		#   NULL that ends envp[]
		#   ELF Auxiliary Table
		#   argv strings
		#   environment strings
		#   program name
		#   NULL		
		pop %eax  # argc.
		mov %esp, %edx  # argv.
		lea 0x4(%edx,%eax,4), %ecx  # envp.
		push %ecx  # Argument envp for main.
		push %edx  # Argument argv for main.
		push %eax  # Argument argc for main.
.if 1  # TODO(pts): Omit this with smart linking.
		call mini___M_start_isatty_stdin
.endif
.if 1  # TODO(pts): Omit this with smart linking.
		call mini___M_start_isatty_stdout
.endif
		call main  # Return value (exit code) in EAX (AL).
		push %eax  # Save exit code, for mini__exit.
		push %eax  # Fake return address, for mini__exit.
		# Fall through to mini_exit(...).
mini_exit:  # void mini_exit(int exit_code)#
.if 1  # TODO(pts): Omit this with smart linking.
		call mini___M_start_flush_stdout
.endif
.if 1  # TODO(pts): Omit this with smart linking.
		call mini___M_start_flush_opened
.endif
		# Fall through to mini__exit(...).
mini__exit:  # void mini__exit(int exit_code)#
_exit:
		mov $1, %al  # __NR_exit.
		# Fall through to progx_syscall3.
syscall3:
mini_syscall3_AL:  # Useful from assembly language.
# Calls syscall(number, arg1, arg2, arg3).
#
# It takes the syscall number from AL (8 bits only!), arg1 (optional) from
# [%esp+4], arg2 (optional) from [%esp+8], arg3 (optional) from [%esp+0xc]. It
# keeps these args on the stack.
#
# It can EAX, EDX and ECX as scratch.
#
# It returns result (or -1 as error) in EAX.
		movzbl %al, %eax  # number.
mini_syscall3_RP1:  # long mini_syscall3_RP1(long nr, long arg1, long arg2, long arg3) __attribute__((__regparm__(1)))#
		push %ebx  # Save it, it's not a scratch register.
		mov 0x8(%esp), %ebx  # arg1.
		mov 0xc(%esp), %ecx  # arg2.
		mov 0x10(%esp), %edx  # arg3.
		int $0x80  # Linux i386 syscall.
		# test %eax, %eax
		# jns .final_result
		cmp $-0x100, %eax  # Treat very large (e.g. <-0x100# with Linux 5.4.0, 0x85 seems to be the smallest) non-negative return values as success rather than errno. This is needed by time(2) when it returns a negative timestamp. uClibc has -0x1000 here.
		jna .final_result
		or $-1, %eax  # EAX := -1 (error).
.final_result:	pop %ebx
mini___M_start_isatty_stdin:  # Falback, will be converted to a weak symbol.
mini___M_start_isatty_stdout:  # Falback, will be converted to a weak symbol.
mini___M_start_flush_stdout:  # Falback, will be converted to a weak symbol.
mini___M_start_flush_opened:  # Falback, will be converted to a weak symbol.
		ret

# TODO(pts): Use smart linking to get rid of the unnecessary syscalls.
mini_read:	mov $3, %al  # __NR_read.
		jmp syscall3
mini_write:	mov $4, %al  # __NR_write.
		jmp syscall3
mini_open:	mov $5, %al  # __NR_open.
		jmp syscall3
mini_close:	mov $6, %al  # __NR_close.
		jmp syscall3
mini_lseek:	mov $19, %al  # __NR_lseek.
		jmp syscall3
mini_ioctl:	mov $54, %al  # __NR_ioctl.
		jmp syscall3
# TODO(pts): Automatically add creat(2), remove(2) etc.
#mini_time:	mov $13, %al  # __NR_time.
#		jmp syscall3
#mini_gettimeofday:  mov $78, %al  # __NR_gettimeofday.
#		jmp syscall3

.ifdef CONFIG_PIC  # Already position-independent code.
.endif

# __END__
