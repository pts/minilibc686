; Workaround for TCC linking to forcibly require the _start symbol.
bits 32
extern _start
%ifdef CONFIG__PIC  ; Double underscore, because we don't want build.sh to build it.
%endif
