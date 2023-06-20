;
; src/stdio_medium_vfsprintf.nasm: defines mini___M_vfsprintf(...), a shorter (mini_*s*printf(...) only) version of mini_vfprintf(...)
; written by pts@fazekas.hu at Tue Jun 20 10:18:28 CEST 2023
;
; Code+data size: 0x21c bytes; 0x21d bytes with CONFIG_PIC.
;
; To take advantage of the size savings of mini___M_vfsprintf(...) with
; respect to mini_vfprintf(...), use smart linking (`minicc -msmart' enabled
; by default).
;
; Uses: %ifdef CONFIG_PIC
;

%define __NEED_mini___M_vfsprintf  ; Make it define label mini___M_vfsprintf instead of mini_vfprintf.
%include "src/stdio_medium_vfprintf.nasm"

%ifdef CONFIG_PIC  ; Just a placeholder.
%endif

; __END__
