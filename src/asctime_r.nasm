;
; written by pts@fazekas.hu at Fri Jun 30 01:26:23 CEST 2023
; inspired by dietlibc-0.34/libugly/asctime_r.c
; Compile to i386 ELF .o object: nasm -O999999999 -w+orphan-labels -f elf -o asctime_r.o asctime_r.nasm
;
; Code+data size: 0xcf bytes.
;
; Limitation: No overflow checking, may segfault or print invalid digits if any of the struct tm fields is too large.
;
; Uses: %ifdef CONFIG_PIC
;

bits 32
cpu 386

global mini_asctime_r
%ifdef CONFIG_SECTIONS_DEFINED
%elifidn __OUTPUT_FORMAT__, bin
section .text align=1
section .rodata align=1
section .data align=1
section .bss align=1
%else
section .text align=1
section .rodata align=1  ; An alignment of 4 would be faster, but just barely.
section .data align=1
section .bss align=1
%endif

; struct tm {...}. Each field is a signed 32-bit integer.
TM_sec   equ 0*4  ; Seconds.	[0-60]  (1 leap second =60, mini_gmtime(...) never generates it)
TM_min   equ 1*4  ; Minutes.	[0-59]
TM_hour  equ 2*4  ; Hours.	[0-23]
TM_mday  equ 3*4  ; Day.	[1-31]
TM_mon   equ 4*4  ; Month.	[0-11]
TM_year  equ 5*4  ; Year - 1900.
TM_wday  equ 6*4  ; Day of week. [0-6, Sunday==0]
TM_yday  equ 7*4  ; Days in year. [0-365]
TM_isdst equ 8*4  ; DST.	[-1/0/1]

section .text
mini_asctime_r:  ; char *mini_asctime_r(const struct tm *tm, char *buf);
		push edi
		mov edx, [esp+2*4]  ; Argument tm.
		mov edi, [esp+3*4]  ; Argument buf.
		push edi
		xor ecx, ecx  ; Top 24 bits will remain 0.
		mov cl, 8
		mov eax, [edx+TM_wday]
		mov eax, [asctime_wdays+eax+eax*2]
		rol eax, cl
		mov al, ' '
		ror eax, cl
		stosd
		mov eax, [edx+TM_mon]
		mov eax, [asctime_months+eax+eax*2]
		rol eax, cl
		mov al, ' '
		ror eax, cl
		stosd
		mov eax, [edx+TM_mday]
		call num2str
		cmp byte [edi-2], '0'
		jne .digit_done
		mov byte [edi-2], ' '
.digit_done:	mov al, ' '
		stosb
		mov eax, [edx+TM_hour]
		call num2str
		mov al, ':'
		stosb
		mov eax, [edx+TM_min]
		call num2str
		mov al, ':'
		stosb
		mov eax, [edx+TM_sec]
		call num2str
		mov al, ' '
		stosb
		mov eax, [edx+TM_year]
		add ax, 1900
		mov cl, 100
		cdq
		div ecx
		call num2str  ; High 2 digits in EAX.
		xchg eax, edx  ; EAX := EDX (low 2 digits); EDX := junk.
		call num2str  ; Low 2 digits.
		mov al, 10  ; '\n'.
		stosb
		mov al, 0  ; '\0'.
		stosb
		pop eax  ; Argument buf.
		pop edi
		ret

num2str:  ; Writes 2 decimal digits from EAX to 2 bytes at EDI, advances EDI. Ruins ECX and EAX.
		push edx
		mov cl, 10
		cdq  ; Sign-exted EAX to EDX. Zero-extension would be more accurate, but the values are small.
		div ecx
		mov ah, dl  ; AL (1st byte) == orig_EAX / 10. AH (2nd byte) := orig_EAX % 10.
		add ax, '0'|'0'<<8
		stosw
		pop edx
		ret

section .rodata
; TODO(pts): Does removing the spaces make the code+data shorter?
asctime_wdays:	db 'SunMonTueWedThuFriSat'  ; Fall throuh.
asctime_months: db 'JanFebMarAprMayJunJulAugSepOctNovDec ' ; We need the final space to avoid loading past the end of .rodata.

%ifdef CONFIG_PIC  ; TODO(pts): Make it PIC by moving the asctime_days and asctime_months constants.
%error Not PIC because it uses global constants asctime_wdays and asctime_months.
times 1/0 nop
%endif

; __END__
