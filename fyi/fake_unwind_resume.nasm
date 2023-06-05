; https://refspecs.linuxbase.org/LSB_5.0.0/LSB-Core-generic/LSB-Core-generic/baselib--unwind-resume.html
bits 32
cpu 386
global _Unwind_Resume
global __gcc_personality_v0
_Unwind_Resume:  ; It's called, EGLIBC would call it from C++ code only.
__gcc_personality_v0:  ; Actual value doesn't matter, it's never called from EGLIBC.
		hlt
