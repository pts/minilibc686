/* GNU ld(1) linker script for Linux i386 a.out QMAGIC (ld -m i386linux) (gcc -Wl,-m,i386linux) (-maout) executable output. */
OUTPUT_FORMAT("a.out-i386-linux", "a.out-i386-linux", "a.out-i386-linux")
OUTPUT_ARCH(i386)
PROVIDE (__stack = 0);
SECTIONS
{
  . = 0x1020;
  .text :
  {
    CREATE_OBJECT_SYMBOLS
    *(.text)
    *(.rodata .rodata.*)
    _etext = .;
    __etext = .;
  }
  . = ALIGN(0x1000);
  .data :
  {
    *(.data)
    CONSTRUCTORS
    _edata  =  .;
    __edata  =  .;
  }
  .bss :
  {
    __bss_start = .;
   *(.bss)
   *(COMMON)
   . = ALIGN(4);
   _end = . ;
   __end = . ;
  }
  /DISCARD/ : { *(.note.GNU-stack) *(.comment) }
}
