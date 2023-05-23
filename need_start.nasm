; Workaround for TCC linking to forcibly require the _start symbol.
bits 32
extern _start
%ifdef CONFIG_PIC
%endif
