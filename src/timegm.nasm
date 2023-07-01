;
; written by pts@fazekas.hu at Sat Jul  1 14:05:26 CEST 2023
; Compile to i386 ELF .o object: nasm -O999999999 -w+orphan-labels -f elf -o timegm.o timegm.nasm
;
; Code size: 0x72 bytes.
;
; Uses: %ifdef CONFIG_PIC
;

bits 32
cpu 386

global mini_timegm
%ifdef CONFIG_SECTIONS_DEFINED
%elifidn __OUTPUT_FORMAT__, bin
section .text align=1
section .rodata align=1
section .data align=1
section .bss align=1
%else
section .text align=1
section .rodata align=1
section .data align=1
section .bss align=1
%endif

; struct tm {...}. Each field is a signed 32-bit integer.
TM_sec   equ 0*4  ; Seconds.    [0-60]  (1 leap second =60, mini_gmtime(...) never generates it)
TM_min   equ 1*4  ; Minutes.    [0-59]
TM_hour  equ 2*4  ; Hours.      [0-23]
TM_mday  equ 3*4  ; Day.        [1-31]
TM_mon   equ 4*4  ; Month.      [0-11]
TM_year  equ 5*4  ; Year - 1900.
TM_wday  equ 6*4  ; Day of week. [0-6, Sunday==0]
TM_yday  equ 7*4  ; Days in year. [0-365]
TM_isdst equ 8*4  ; DST.        [-1/0/1]

section .text
mini_timegm:  ; time_t mini_timegm(const struct tm *tm);
; We assume that time_t is int32_t.
;
; time_t mini_timegm(const struct tm *tm) {
;   int y = tm->tm_year - 100;
;   int yday = tm->tm_yday;
;   int month;
;   time_t y4, y100;
;   if (yday < 0) {
;     month = tm->tm_mon + 1;
;     if (month <= 2) {
;       --y;
;       month += 12;
;     }
;     yday = (153 * month + 3) / 5 + tm->tm_mday - 399;
;   } else {
;     --y;
;   }
;   y4 = y >> 2;
;   y100 = y4 / 25;
;   if (y4 % 25 < 0) --y100;  /* Fix quotient if y4 was negative. */
;   return (((365 * (time_t)y + y4 - y100 + (y100 >> 2) + (yday + 11323))
;       * 24 + tm->tm_hour) * 60 + tm->tm_min) * 60 + tm->tm_sec;
; }
		push esi
		push ebx
		mov ebx, [esp+0xc]  ; Argument tm.
		mov esi, [ebx+TM_year]
		sub esi, byte 100+1
		mov ecx, [ebx+TM_yday]
		test ecx, ecx
		jns .use_yday
		mov eax, [ebx+TM_mon]  ; We assume 0 <= tm_mon <= 11, thus the highest 24 bits of EAX are 0.
		cmp al, 1
		jle .not_jan_feb
		inc esi
		sub al, 12
.not_jan_feb:	add al, 13
		imul ax, ax, word 153
		add eax, byte 3
		cdq  ; EDX := 0. It's sign_extend(EAX), but EAX (== 153 * month <= 1989) is small enough.
		xor ecx, ecx
		mov cl, 5
		idiv ecx
		add eax, [ebx+TM_mday]
		lea ecx, [eax-399]  ; Same size as: `sub eax, 399' ++ `xchg ecx, eax'.
.use_yday:	; Now: ESI == yday.
		mov eax, esi
		sar eax, 2
		imul esi, esi, dword 365
		add esi, eax
		add esi, ecx  ; After this, we don't need ECX.
		cdq  ; EDX := 0. It's sign_extend(EAX), but EAX (== y4) is small enough.
		xor ecx, ecx
		mov cl, 25
		idiv ecx  ; EAX := quotient; EDX := remainder.
		test edx, edx
		jns .after_fix
		dec eax  ; Fix quotient if y4 was negative.
.after_fix:	sub esi, eax
		sar eax, 2
		add eax, esi
		add eax, 11323
		imul eax, eax, byte 24
		add eax, [ebx+TM_hour]
		imul eax, eax, byte 60
		add eax, [ebx+TM_min]
		imul eax, eax, byte 60
		add eax, [ebx+TM_sec]
		pop ebx
		pop esi
		ret

%ifdef CONFIG_PIC  ; Already position-independent code.
%endif

; __END__
