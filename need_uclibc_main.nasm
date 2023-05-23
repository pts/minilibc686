; Workaround for TCC linking to forcibly require the __uClibc_main symbol.
bits 32
extern __uClibc_main
%ifdef CONFIG_PIC
%endif
