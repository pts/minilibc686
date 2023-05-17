; This is useful for defining the entry point symbol as _start. Some
; compilers (such as tcc) require this name.
%define mini__start _start
%include "start_stdio_linux.nasm"
