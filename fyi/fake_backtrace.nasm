bits 32
cpu 386
; For EGLIBC.
global backtrace
global __backtrace
backtrace:
__backtrace:
		xor eax, eax
		ret
