#
# demo_obj2.s: demonstrates various object file format features
# by pts@fazekas.hu at Thu Jun  1 12:40:36 CEST 2023
#
# Compile to i386 ELF .o object: as --32 -march=i386 -o demo_obj2.o demo_obj2.s
#
# The GNU as(1) output .o (i386 ELF relocatable object) file should
# be equivalent to the OpenWatcom (wcc386) output OMF on demo_c_obj.c.
#
# Partially based on the .s output of GCC 7.5.0.
#

.global _get_exit_code
.global main_
.global _knock
.global _rodata_global
.global _data_global
.global _bss_global1
.global _bss_global2
.global _bss_global0
.extern _printf  # GCC doesn't emit .extern.
.extern _extern_answers
# Just ignore, wcc386 adds them if main(...) is present.
# TODO(pts): Add main (__cdecl) which calls main_ (__watcall).
.extern __argc
.extern _cstart_

.section .text
		#.type _get_addressee, @function  # GCC emits this.
		# GCC 7.5.0 has generated this static function with
		# __regparm__((2)) calling convention, for smaller code
		# size. Please note that the code below is from OpenWatcom
		# (__cdecl).
_get_addressee:	pushl %ebp
		movl %esp, %ebp
		cmpl $2, 8(%ebp)
		jge .1
		movl $str.3, %eax
		pop %ebx
		ret
.1:		mov 0xc(%ebp), %eax
		mov 4(%eax), %eax
		popl %ebp
		ret
		#.size _get_addressee, .-_get_addressee  # GCC emits this.
#
		#.type _get_exit_code, @function  # GCC emits this.
_get_exit_code:	pushl %ebp
		movl %esp, %ebp
		movl 8(%ebp), %eax
		cmpl $1, %eax
		jl .2
		cmpl $9, %eax
		jg .2
		mov $1, %eax
		pop %ebp
		ret
.2:		xor %eax, %eax
		pop %ebp
		ret
		#.size _get_exit_code, .-get_exit_code  # GCC emits this.
#
#.section .text.startup,"ax",@progbits  # GCC emits this for main.
#
# OpenWatcom has generated main_ with __watcall, even when __cdecl is the
# default (wcc386 -ecc).
		#.type main_, @function  # GCC emits this.
main_:		push %ebx
		push %ecx
		mov %eax, %ebx
		push %edx
		push %eax
		call _get_addressee
		add $8, %esp
		push %eax
		push $str.5
		call _printf
		add $8, %esp
		push %ebx
		call _get_exit_code
		add $4, %esp
		pop %ecx
		pop %ebx
		ret
		#.size main_, .-main_  # GCC emits this.

.section .rodata.str1.1, "aMS", @progbits, 1
str.3:		.string "World"
str.4:		.string "rld"  # GCC doesn't deduplicate this suffix match. !! TODO(pts): Does GNU ld(1) deduplicate strings in .rodata.str1.1? Probably yes.
str.5:		.string "Hello, %s!\n"

.section .rodata
		.align 4  # GCC emits this. It also affects the section alignment.
		#.type knock, @object  # GCC emits this.
		#.size knock, 7  # GCC emits this.
_knock:  	.string "Knock?"
		#.align 4  # GCC emits this.
		#.type _rodata_local, @object  # GCC emits this.
		#.size _rodata_local, 28  # GCC emits this.
_rodata_local:	.long 5, 6
		.long extern_answers+8
		.long _knock
		.long _bss_global2
		.long _bss_local3
		.long str.3
		#.align 4  # GCC emits this.
		#.type _rodata_global, @object  # GCC emits this.
		#.size _rodata_global, 40  # GCC emits this.
_rodata_global:	.long 7, 8
		.long extern_answers+8
		.long _knock
		.long _bss_global2
		.long _bss_local3
		.long _rodata_local+0x10
		.long _data_local+4
		.long _data_global+8
		.long str.3

.section .data
		.align 4  # GCC emits this. It also affects the section alignment.
		#.type _data_local, @object  # GCC emits this.
		#.size _data_local, 32  # GCC emits this.
_data_local:	.long 0xf, 0x10
		.long extern_answers+0x30
		.long _bss_global2+4
		.long _bss_local3+1
		.long _knock+2
		.long _rodata_local+0x14
		.long str.4
		#.align 4  # GCC emits this.
		#.type _data_global, @object  # GCC emits this.
		#.size _data_global, 36  # GCC emits this.
_data_global:	.long 0x11
		.long 0x12
		.long extern_answers+0x30
		.long _bss_global2+4
		.long _bss_local3+1
		.long _knock+2
		.long _rodata_local+0xc
		.long _data_local+8
		.long str.4

.section .bss
		.align 4  # This also affects the section alignment.	
		#.local _bss_local3  # GCC emits this instead of .bss.
		#.comm _bss_global1,12,4  # GCC emits this.
_bss_global1:	.fill 3*4, 1, 0
		#.comm _bss_global2,28,4  # GCC emits this.
_bss_global2:	.fill 7*4, 1, 0
		#.comm _bss_local3,2,1  # GCC emits this.
_bss_local3:	.fill 2, 1, 0
		#.comm _bss_global0,1,1  # GCC emits this.
_bss_global0:	.fill 1, 1, 0

#.section .note.GNU-stack, "",@progbits  # GCC emits this.

# GNU as (1) adds a .note section describing the architecture (NT_ARCH == i386).

# __END__
