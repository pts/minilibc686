/*
 * sstrip: strip parts of ELF executables not needed for execution
 * by pts@fazekas.hu at Wed May 24 02:20:35 CEST 2023
 *
 * Compile: pathbin/minicc --noenv --gcc=4.8 -o tools/sstrip tools/sstrip.c
 *
 * Compile: gcc -s -O2 -ansi -pedantic -W -Wall -Wextra -Werror -Wno-overlength-strings -DENABLE_ELFDATAMOVE -DENABLE_PEPATCH -o sstrip tools/sstrip.c
 *
 * The command-line flags tend to be compatible with GNU strip(1) and
 * [ELF Kickers](https://www.muppetlabs.com/~breadbox/software/elfkickers.html)
 * [sstrip](https://github.com/BR903/ELFkickers/blob/master/sstrip/sstrip.c)(1).
 *
 * This tool has similar functionality as elfxfix (exectly same except for
 * the new -z flag and the dropped -p and -r flags), but the command-line
 * flags are changed to match GNU strip(1) and
 * [ELFkickers](https://www.muppetlabs.com/~breadbox/software/elfkickers.html)
 * [sstrip](https://github.com/BR903/ELFkickers/blob/master/sstrip/sstrip.c)(1),
 * so this tool can be used as a drop-in replacement if only the implemented
 * flags are used.
 *
 * This program is written in standard C (C89 and later, also C++98 and
 * later). It works on any little-endian system with sizeof(int) >= 32 and
 * correct struct alignment for <elf.h>. It has been tested with GCC (both C
 * and C++), Clang (both C and C++), TinyCC (C) and OpenWatcom (C)
 * compilers.
 */

#ifndef _ALL_LIBC_INCLUDED
#  define _XOPEN_SOURCE 500  /* ftruncate(...). */
#  include <fcntl.h>
#  include <stdio.h>
#  include <stdint.h>
#  include <stdlib.h>
#  include <string.h>
#  include <unistd.h>
#  ifdef _LIBC_NO_FILEP
#    include <stdarg.h>
#  endif
#endif

#ifndef _LIBC_HAS_OPEN_FAILED
#  define _LIBC_HAS_OPEN_FAILED(fd_result) ((fd_result) < 0)
#endif

#if (defined(__i386) || defined(__i386__) || defined(__amd64__) || defined(__x86_64__) || defined(_M_X64) || defined(_M_AMD64) || defined(__386) || \
     defined(__X86_64__) || defined(_M_I386) || defined(_M_I86) || defined(_M_X64) || defined(_M_AMD64) || defined(_M_IX86) || defined(__386__) || \
     defined(__X86__) || defined(__I86__) || defined(_M_I86) || defined(_M_I8086) || defined(_M_I286)) && !defined(IS_X86)
#  define IS_X86 1
#endif
#if IS_X86 && !defined(IS_CPU_UNALIGNED)  /* No unaligned access support: ARM, IA64 (defined(_M_IA64)). */
#  define IS_CPU_UNALIGNED 1  /* Supports unaligned memory access for non-SIMD instructions. */
#endif

#ifdef _LIBC_NO_FILEP
#  define stdout ((void*)1)
#  define stderr ((void*)2)
  /* Poor man's fprintf. It doesn't do buffering, and it supports only %%
   * and %s in the format string, and it replaces "\n" with "\r\n" in
   * fmt only.
   */
  static void fprintf(void *file, const char *fmt, ...) {
    va_list ap;
    int fd = (int)file;
    const char *fmt0, *s;
    va_start(ap, fmt);
    for (fmt0 = fmt; *fmt != '\0'; ++fmt) {
#  ifdef _LIBC_CRLF
      if (*fmt == '\n') {
        if (fmt0 != fmt) (void)!write(fd, fmt0, fmt - fmt0);
        (void)!write(fd, "\r", 1);
        fmt0 = fmt;
        continue;
      }
#  endif
      if (*fmt != '%') continue;
      if (fmt0 != fmt) (void)!write(fd, fmt0, fmt - fmt0);
      fmt0 = fmt++;
      if (*fmt == '%') { ++fmt0; continue; }
      if (*fmt != 's') break;  /* We only support %s. */
      fmt0 += 2;
      s = va_arg(ap, const char*);
      if (*s != '\0') (void)!write(fd, s, strlen(s));
    }
    if (fmt0 != fmt) (void)!write(fd, fmt0, fmt - fmt0);
    va_end(ap);
  }
#endif

/* --- ELF file format. */

/* Type for a 16-bit quantity.  */
typedef uint16_t Elf32_Half;
typedef uint16_t Elf64_Half;

/* Types for signed and unsigned 32-bit quantities.  */
typedef uint32_t Elf32_Word;
typedef	int32_t  Elf32_Sword;

/* Types for signed and unsigned 64-bit quantities.  */
typedef uint64_t Elf32_Xword;
typedef	int64_t  Elf32_Sxword;

/* Type of addresses.  */
typedef uint32_t Elf32_Addr;

/* Type of file offsets.  */
typedef uint32_t Elf32_Off;

/* Type for section indices, which are 16-bit quantities.  */
typedef uint16_t Elf32_Section;

/* The ELF file header.  This appears at the start of every ELF file.  */

#define EI_NIDENT (16)

/* The ELF file header.  This appears at the start of every ELF file.  */
typedef struct {
  unsigned char	e_ident[EI_NIDENT];	/* Magic number and other info */
  Elf32_Half	e_type;			/* Object file type */
  Elf32_Half	e_machine;		/* Architecture */
  Elf32_Word	e_version;		/* Object file version */
  Elf32_Addr	e_entry;		/* Entry point virtual address */
  Elf32_Off	e_phoff;		/* Program header table file offset */
  Elf32_Off	e_shoff;		/* Section header table file offset */
  Elf32_Word	e_flags;		/* Processor-specific flags */
  Elf32_Half	e_ehsize;		/* ELF header size in bytes */
  Elf32_Half	e_phentsize;		/* Program header table entry size */
  Elf32_Half	e_phnum;		/* Program header table entry count */
  Elf32_Half	e_shentsize;		/* Section header table entry size */
  Elf32_Half	e_shnum;		/* Section header table entry count */
  Elf32_Half	e_shstrndx;		/* Section header string table index */
} Elf32_Ehdr;
typedef char static_assert_sizeof_Elf32_Ehdr[sizeof(Elf32_Ehdr) == 0x34 ? 1 : -1];

#define ELFCLASS32	1		/* 32-bit objects */

/* Program segment header.  */
typedef struct {
  Elf32_Word	p_type;			/* Segment type */
  Elf32_Off	p_offset;		/* Segment file offset */
  Elf32_Addr	p_vaddr;		/* Segment virtual address */
  Elf32_Addr	p_paddr;		/* Segment physical address */
  Elf32_Word	p_filesz;		/* Segment size in file */
  Elf32_Word	p_memsz;		/* Segment size in memory */
  Elf32_Word	p_flags;		/* Segment flags */
  Elf32_Word	p_align;		/* Segment alignment */
} Elf32_Phdr;
typedef char static_assert_sizeof_Elf32_Phdr[sizeof(Elf32_Phdr) == 0x20 ? 1 : -1];

#define ET_EXEC		2		/* Executable file */

#define EI_BRAND	8		/* 8 bytes, typically all NUL. */

#define EI_OSABI	7		/* OS ABI identification */
#define ELFOSABI_SYSV		0	/* Alias.  */
#define ELFOSABI_GNU		3	/* Object uses GNU ELF extensions.  */
#define ELFOSABI_LINUX		ELFOSABI_GNU /* Compatibility alias.  */
#define ELFOSABI_IRIX		8	/* SGI Irix. */
#define ELFOSABI_FREEBSD	9	/* FreeBSD. */

#define PT_LOAD		1		/* Loadable program segment */

#ifdef ENABLE_ELFDATAMOVE  /* Can be defined on the command line. */
/* Section header.  */
typedef struct {
  Elf32_Word	sh_name;		/* Section name (string tbl index) */
  Elf32_Word	sh_type;		/* Section type */
  Elf32_Word	sh_flags;		/* Section flags */
  Elf32_Addr	sh_addr;		/* Section virtual addr at execution */
  Elf32_Off	sh_offset;		/* Section file offset */
  Elf32_Word	sh_size;		/* Section size in bytes */
  Elf32_Word	sh_link;		/* Link to another section */
  Elf32_Word	sh_info;		/* Additional section information */
  Elf32_Word	sh_addralign;		/* Section alignment */
  Elf32_Word	sh_entsize;		/* Entry size if section holds table */
} Elf32_Shdr;
typedef char static_assert_sizeof_Elf32_Shdr[sizeof(Elf32_Shdr) == 0x28 ? 1 : -1];

/* Legal values for sh_type (section type).  */
#define SHT_NULL	  0		/* Section header table entry unused */
#define SHT_PROGBITS	  1		/* Program data */
#define SHT_SYMTAB	  2		/* Symbol table */
#define SHT_STRTAB	  3		/* String table */
#define SHT_RELA	  4		/* Relocation entries with addends */
#define SHT_HASH	  5		/* Symbol hash table */
#define SHT_DYNAMIC	  6		/* Dynamic linking information */
#define SHT_NOTE	  7		/* Notes */
#define SHT_NOBITS	  8		/* Program space with no data (bss) */
#define SHT_REL		  9		/* Relocation entries, no addends */

/* Legal values for sh_flags (section flags).  */
#define SHF_WRITE	     (1 << 0)	/* Writable */
#define SHF_ALLOC	     (1 << 1)	/* Occupies memory during execution */
#define SHF_EXECINSTR	     (1 << 2)	/* Executable */
#define SHF_MERGE	     (1 << 4)	/* Might be merged */
#define SHF_STRINGS	     (1 << 5)	/* Contains nul-terminated strings */

/* Symbol table entry.  */
typedef struct {
  Elf32_Word	st_name;		/* Symbol name (string tbl index) */
  Elf32_Addr	st_value;		/* Symbol value */
  Elf32_Word	st_size;		/* Symbol size */
  unsigned char	st_info;		/* Symbol type and binding */
  unsigned char	st_other;		/* Symbol visibility */
  Elf32_Section	st_shndx;		/* Section index */
} Elf32_Sym;

typedef char static_assert_sizeof_Elf32_Sym[sizeof(Elf32_Sym) == 0x10 ? 1 : -1];

/* How to extract and insert information held in the st_info field.  */
#define ELF32_ST_TYPE(val)		((val) & 0xf)
#define ELF32_ST_BIND(val)		(((unsigned char) (val)) >> 4)

/* Legal values for ST_TYPE subfield of st_info (symbol type).  */
#define STT_NOTYPE	0		/* Symbol type is unspecified */
#define STT_OBJECT	1		/* Symbol is a data object */
#define STT_FUNC	2		/* Symbol is a code object */
#define STT_SECTION	3		/* Symbol associated with a section */
#define STT_FILE	4		/* Symbol's name is file name */
#define STT_COMMON	5		/* Symbol is a common data object */

/* Legal values for ST_BIND subfield of st_info (symbol binding).  */
#define STB_LOCAL	0		/* Local symbol */
#define STB_GLOBAL	1		/* Global symbol */
#define STB_WEAK	2		/* Weak symbol */

/* How to extract and insert information held in the st_other field.  */
#define ELF32_ST_VISIBILITY(o)	((o) & 0x03)

/* Symbol visibility specification encoded in the st_other field.  */
#define STV_DEFAULT	0		/* Default symbol visibility rules */
#define STV_HIDDEN	2		/* Sym unavailable in other modules */

/* Special section indices.  */
#define SHN_UNDEF	0		/* Undefined section */

/* Relocation table entry with addend (in section of type SHT_RELA).  */
typedef struct {
  Elf32_Addr	r_offset;		/* Address */
  Elf32_Word	r_info;			/* Relocation type and symbol index */
  Elf32_Sword	r_addend;		/* Addend */
} Elf32_Rela;
typedef char static_assert_sizeof_Elf32_Rela[sizeof(Elf32_Rela) == 0xc ? 1 : -1];

/* How to extract and insert information held in the r_info field.  */
#define ELF32_R_SYM(val)		((val) >> 8)
#define ELF32_R_TYPE(val)		((val) & 0xff)

/* i386 relocs.  */
#define R_386_NONE	   0		/* No reloc */
#define R_386_32	   1		/* Direct 32 bit  */
#define R_386_PC32	   2		/* PC relative 32 bit */
#endif  /* #ifdef ENABLE_ELFDATAMOVE */

#ifdef ENABLE_PEPATCH  /* Can be defined on the command line. */
typedef struct {  /* All integer fields little-endian. */
  char signature[2];  /* "MZ. */
  uint16_t lastsize;
  uint16_t nblocks;
  uint16_t nreloc;
  uint16_t hdrsize;
  uint16_t minalloc;
  uint16_t maxalloc;
  uint16_t ss;
  uint16_t sp;
  uint16_t checksum;
  uint16_t ip;
  uint16_t cs;
  uint16_t relocpos;  /* At file offset @0x18 == @24. */
  uint16_t noverlay;
  char unused[0x3c-0x1c];
  uint32_t pe_fofs;  /* At file offset @0x3c == @60. */
} MzHdr;
typedef char static_assert_sizeof_MzHdr[sizeof(MzHdr) == 0x40 ? 1 : -1];

typedef struct { /* Image data directory. */  /* All integer fields little-endian. */
  uint32_t VirtualAddress;
  uint32_t Size;
} PeIdd;

typedef struct {
  char Signature[4];  /* "PE\0\0". */
  uint16_t Machine;
  uint16_t NumberOfSections;
  uint32_t TimeDateStamp;
  uint32_t PointerToSymbolTable;
  uint32_t NumberOfSymbols;
  uint16_t SizeOfOptionalHeader;
  uint16_t Characteristics;
  uint16_t Magic;
  uint8_t  MajorLinkerVersion;
  uint8_t  MinorLinkerVersion;
  uint32_t SizeOfCode;
  uint32_t SizeOfInitializedData;
  uint32_t SizeOfUninitializedData;
  uint32_t AddressOfEntryPoint;
  uint32_t BaseOfCode;
  uint32_t BaseOfData;
  uint32_t ImageBase;
  uint32_t SectionAlignment;
  uint32_t FileAlignment;
  uint16_t MajorOperatingSystemVersion;
  uint16_t MinorOperatingSystemVersion;
  uint16_t MajorImageVersion;
  uint16_t MinorImageVersion;
  uint16_t MajorSubsystemVersion;
  uint16_t MinorSubsystemVersion;
  uint32_t Win32VersionValue;
  uint32_t SizeOfImage;
  uint32_t SizeOfHeaders;
  uint32_t CheckSum;
  uint16_t Subsystem;
  uint16_t DllCharacteristics;
  uint32_t SizeOfStackReserve;
  uint32_t SizeOfStackCommit;
  uint32_t SizeOfHeapReserve;
  uint32_t SizeOfHeapCommit;
  uint32_t LoaderFlags;
  uint32_t NumberOfRvaAndSizes;
#if 0  /* No need to get or set these. */
  /* PeIdd DataDirectory[IMAGE_NUMBEROF_DIRECTORY_ENTRIES]; */
  PeIdd IMAGE_DIRECTORY_ENTRY_EXPORT;  /* 0. Export. */
  PeIdd IMAGE_DIRECTORY_ENTRY_IMPORT;  /* 1. Import. */
  PeIdd IMAGE_DIRECTORY_ENTRY_RESOURCE;  /* 2. Resource. */
  PeIdd IMAGE_DIRECTORY_ENTRY_EXCEPTION;  /* 3. Exception. */
  PeIdd IMAGE_DIRECTORY_ENTRY_SECURITY;  /* 4. Security. Certificates. */
  PeIdd IMAGE_DIRECTORY_ENTRY_BASERELOC;  /* 5. Base relocation. */
  PeIdd IMAGE_DIRECTORY_ENTRY_DEBUG;  /* 6. Debug. */
  PeIdd IMAGE_DIRECTORY_ENTRY_ARCHITECTURE;  /* 7. Description. Architecture. */
  PeIdd IMAGE_DIRECTORY_ENTRY_GLOBALPTR;  /* 8. Global pointer. Special. */
  PeIdd IMAGE_DIRECTORY_ENTRY_TLS;  /* 9. Thread local storage. */
  PeIdd IMAGE_DIRECTORY_ENTRY_LOAD_CONFIG;  /* 10. Load configuration. */
  PeIdd IMAGE_DIRECTORY_ENTRY_BOUND_IMPORT;  /* 11. Bound import. */
  PeIdd IMAGE_DIRECTORY_ENTRY_IAT;  /* 12. Import address table. */
  PeIdd IMAGE_DIRECTORY_ENTRY_DELAY_IMPORT;  /* 13. Delay Import. */
  PeIdd IMAGE_DIRECTORY_ENTRY_COM_DESCRIPTOR;  /* 14. COM descriptor. CLR runtime. Nonzero for .NET .exe. */
  PeIdd IMAGE_DIRECTORY_ENTRY_RESERVED;  /* 15. Reserved. */
#endif
} PeHdr;
typedef char static_assert_sizeof_PeHdr[sizeof(PeHdr) == 0xf8 - 0x80 ? 1 : -1];
#endif  /* #ifdef ENABLE_PEPATCH */

/* --- */

/* It doesn't work with smaller int sizes, some `int' and `unsigned' variables are too small. */
typedef char static_assert_sizeof_int[sizeof(int) >= 4 ? 1 : -1];

#ifdef ENABLE_ELFDATAMOVE  /* Can be defined on the command line. */
#  define RWBUF_SIZE 0x8000U  /* Must be at least 4, for rela. */
#  if !IS_CPU_UNALIGNED
static uint32_t get_u32(const unsigned char *p) {
  return p[0] | p[1] << 8 | p[2] << 16 | p[3] << 24;
}
static void set_u32(unsigned char *p, uint32_t value) {
  *p++ = value; value >>= 8;
  *p++ = value; value >>= 8;
  *p++ = value; value >>= 8;
  *p = value;
}
static void add_u32(unsigned char *p, uint32_t delta) {
  set_u32(p, get_u32(p) + delta);
}
#  else
#    define add_u32(p, delta) (*(uint32_t*)(p) += (delta))
#  endif
#endif

int main(int argc, char **argv) {
  int fd;
  const char *filename;
  union {
    Elf32_Ehdr ehdr;
#ifdef ENABLE_PEPATCH  /* Can be defined on the command line. */
    MzHdr mzhdr;
    PeHdr pehdr;
#endif
  } u;
#define ehdr u.ehdr
  off_t off;
  size_t want;
  static Elf32_Phdr phdrs[0x80];
  Elf32_Phdr *phdr, *phdr_end;
  const char *arg;
  char **argp;
  char c;
  unsigned char osabi = (unsigned char)-1;
  char flag_a = 1, flag_s = 1, flag_h = 1, is_verbose = 0;
  const char flag_z = 0;
  char phdr_has_changed = 0, ehdr_has_changed = 0;
  char is_first_pt_load = 1;
  Elf32_Off end_off, last_off;
  Elf32_Word pt_load_count;
  const char *brand;
#ifdef ENABLE_ELFDATAMOVE  /* Can be defined on the command line. */
  Elf32_Phdr *ptload0, *ptload1;
  Elf32_Shdr *shdrs;  /* Allocated using malloc(...). */
  Elf32_Shdr *shdr, *shdr_end, *shdr_symtab;
  Elf32_Addr data_vstart0, data_vstart1, data_delta;
  Elf32_Sym *syms;  /* Allocated using malloc(...). */
  Elf32_Sym *sym, *sym_end;
  Elf32_Word sym_count;
  Elf32_Word max_rela_size;
  Elf32_Word rela_count;
  Elf32_Rela *relas;  /* Allocated using malloc(...). */
  Elf32_Rela *rela, *rela2, *rela_end;
  Elf32_Off rela_shdr_off, rela_offset;
  Elf32_Addr rela_shdr_vstart;
  Elf32_Addr rela_delta;
  unsigned char *rwbuf;
  char shdr_has_changed, sym_has_changed;
  char flag_md = 0;
#endif
#ifdef ENABLE_PEPATCH  /* Can be defined on the command line. */
  unsigned char pe_fofs_parity = (unsigned char)-1;
  char flag_pt0 = 0, flag_ph0 = 0, flag_ps = 0;
  const char *mz_message = NULL;
  char *cp;
#endif
  char is_fixing;

  (void)argc; (void)argv;
  if (!argv[0] || !argv[1] || strcmp(argv[1], "--help") == 0) {
    fprintf(stderr, "Usage: %s [<flag>...] <elfprog>\nFlags:\n"
            "-v: verbose operation, write info to stderr\n"
            "-l or -ll: change the ELF OSABI to Linux\n"
            "-ls: change the ELF OSABI to SYSV\n"
            "-lf: change the ELF OSABI to FreeBSD\n"
            "-li: change the ELF OSABI to IRIX\n"
            "-a: align the early PT_LOAD phdr to page size (enabled by default)\n"
            "-na: disable -a\n"
            "-h: fix ELF section header size (enabled by default)\n"
            "-nh: disable -h\n"
            "-s: strip beyond the last PT_LOAD (sstrip) (strip default, enabled by default)\n"
            "-ns: disable -s\n"
#ifdef ENABLE_ELFDATAMOVE  /* Can be defined on the command line. */
            "-md: move ELF .data forward to avoid overlap with .text\n"
#endif
#ifdef ENABLE_PEPATCH  /* Can be defined on the command line. */
            "-p0: make the PE .exe header offset even\n"
            "-p1: make the PE .exe header offset odd\n"
            "-pt0: set the PE .exe TimeDateStamp to 0\n"
            "-ph0: set the PE .exe SizeOfHeapReserve and SizeOfHeapCommit to 0\n"
            "-ps: fix the PE .exe SizeOfStackReserve and SizeOfStackCommit\n"
            "-m <msg>: set message between PE .exe file offsets 0x18...0x3c\n"
#endif
            "-z: discard trailing zero bytes (sstrip flag) (not implemented)\n",
            argv[0]);
    return !argv[0] || !argv[1];  /* 0 (EXIT_SUCCESS) for--help. */
  }
  for (argp = argv + 1; (arg = *argp) != NULL; ++argp) {
    if (arg[0] != '-') break;
    if ((c = arg[1]) == '\0') break;
    if (c == '-' && arg[2] == '\0') {
      ++argp;
      break;
    } else if (c == 'n') {
      if (arg[2] == '\0' || arg[3] != '\0') {
        goto unknown_flag;
      } else if (arg[2] == 'a') {
        flag_a = 0;
      } else if (arg[2] == 's') {
        flag_s = 0;
      } else if (arg[2] == 'h') {
        flag_h = 0;
      } else {
        goto unknown_flag;
      }
#ifdef ENABLE_PEPATCH  /* Can be defined on the command line. */
    } else if (c == 'p' && (arg[2] == 't' || arg[2] == 'h') && arg[3] == '0' && arg[4] == '\0') {
      flag_a = flag_s = flag_h = 0;
#ifdef ENABLE_ELFDATAMOVE  /* Can be defined on the command line. */
      flag_md = 0;
#endif
      if (arg[2] == 't') {
        flag_pt0 = 1;
      } else {
        flag_ph0 = 1;
      }
    } else if (c == 'p' && arg[2] != '\0' && arg[3] == '\0') {
      if (arg[2] - '0' + 0U < 2U) {
        pe_fofs_parity = arg[2] - '0';
        flag_a = flag_s = flag_h = 0;
#ifdef ENABLE_ELFDATAMOVE  /* Can be defined on the command line. */
        flag_md = 0;
#endif
      } else if (arg[2] == 's') {
        flag_ps = 1;
        flag_a = flag_s = flag_h = 0;
#ifdef ENABLE_ELFDATAMOVE  /* Can be defined on the command line. */
        flag_md = 0;
#endif
      } else {
        goto unknown_flag;
      }
    } else if (c == 'p' && arg[3] == '\0') {
      if (arg[2] - '0' + 0U < 2U) {
        pe_fofs_parity = arg[2] - '0';
        flag_a = flag_s = flag_h = 0;
#ifdef ENABLE_ELFDATAMOVE  /* Can be defined on the command line. */
        flag_md = 0;
#endif
      } else {
        goto unknown_flag;
      }
#endif
    } else if (c == 'l' && arg[2] != '\0' && arg[3] == '\0') {
      if (arg[2] == 'l') {
        osabi = ELFOSABI_LINUX;
      } else if (arg[2] == 'f') {
        osabi = ELFOSABI_FREEBSD;
      } else if (arg[2] == 'i') {
        /* This is fake IRIX. IRIX has never supported i386 ELF-32 (only
         * MIPS ELF-32). Also IRIX has never supported little-endian
         * systems (only big-endian MIPS). The last release of IRIX was on
         * 2006-08-16 (with mostly bugfixes and small improvements to IRIX
         * 6.5 released in 1998-05).
         *
         * We could make it even more fake by setting a nonzero e_flags
         * value (i386 ELF-32 has 0 in practice everywhere), such as
         * 0xef80ffff, which contains invalid (undefined) values in many
         * fields for MIPS. See More EF_MIPS_... flags on
         * https://llvm.org/doxygen/namespacellvm_1_1ELF.html
         */
        osabi = ELFOSABI_IRIX;
      } else if (arg[2] == 's') {
        osabi = ELFOSABI_SYSV;
      } else {
        goto unknown_flag;
      }
#ifdef ENABLE_ELFDATAMOVE  /* Can be defined on the command line. */
    } else if (c == 'm' && arg[2] == 'd' && arg[3] == '\0') {
      flag_md = 1;
#endif
    } else if (arg[2] != '\0') {
      goto unknown_flag;
    } else if (c == 'v') {
      is_verbose = 1;
    } else if (c == 'l') {
      osabi = ELFOSABI_LINUX;
    } else if (c == 'a') {
      flag_a = 1;
    } else if (c == 's') {
      flag_s = 1;
    } else if (c == 'h') {
      flag_h = 1;
    } else if (c == 'z') {
      /* Ignored for ELF Kickers strip(1) compatibility. */
      /* TODO(pts): Implement this instead of ignoring it. */
    } else if (c == 'g' || c == 'd' || c == 'S' || c == 'M') {
      /* Ignored for GNU strip(1) compatibility. */
    } else if (c == 'x' || c == 'X' || c == 'N' || c == 'R'
#ifdef ENABLE_PEPATCH  /* Can be defined on the command line. */
               || c == 'm'
#endif
              ) {
      if (!argp[1]) {
        fprintf(stderr, "fatal: missing argument for flag: %s\n", arg);
        return 1;
      }
      ++argp;
#ifdef ENABLE_PEPATCH  /* Can be defined on the command line. */
      if (c == 'm') {
        mz_message = *argp;
        flag_a = flag_s = flag_h = 0;
#ifdef ENABLE_ELFDATAMOVE  /* Can be defined on the command line. */
        flag_md = 0;
#endif
     }
#endif
    } else {
     unknown_flag:
      fprintf(stderr, "fatal: unknown command-line flag: %s\n", arg);
      return 1;
    }
  }
  if (*argp == NULL) {
    fprintf(stderr, "fatal: missing filename argument\n");
    return 1;
  }
  filename = *argp++;
  if (*argp != NULL) {
    fprintf(stderr, "fatal: too many commad-line arguments\n");
    return 1;
  }

  is_fixing = osabi != (unsigned char)-1 || flag_a || flag_z || flag_h
#ifdef ENABLE_ELFDATAMOVE  /* Can be defined on the command line. */
      || flag_md
#endif
#ifdef ENABLE_PEPATCH  /* Can be defined on the command line. */
      || pe_fofs_parity != (unsigned char)-1 || flag_pt0 || flag_ph0 || flag_ps || mz_message
#endif
      ;
  if (is_verbose) {  /* GNU strip(1) comaptibility. */
    fprintf(stderr, "info: %s: %s\n", flag_s ? (is_fixing ? "stripping and fixing" : "stripping") : (is_fixing ? "fixing" : "checking"), filename);
  }
  if (_LIBC_HAS_OPEN_FAILED(fd = open(filename, O_RDWR))) {
    fprintf(stderr, "fatal: error opening for read-write: %s\n", filename);
    return 2;
  }
#ifdef ENABLE_PEPATCH  /* Can be defined on the command line. */
  if (pe_fofs_parity != (unsigned char)-1 || mz_message) {
    if (read(fd, &u.mzhdr, sizeof(u.mzhdr)) != sizeof(u.mzhdr)) {
      fprintf(stderr, "fatal: error reading PE mzhdr: %s\n", filename);
      return 3;
    }
    if (memcmp(u.mzhdr.signature, "MZ", 2) != 0) {
      fprintf(stderr, "fatal: bad MZ signature: %s\n", filename);
      return 4;
    }
    /*close(fd);*/  /* No need, we are exiting anyway. */
    if (pe_fofs_parity != (unsigned char)-1 && (unsigned char)(u.mzhdr.pe_fofs & 1U) != pe_fofs_parity) {
      u.mzhdr.pe_fofs &= ~(uint32_t)1U;
      u.mzhdr.pe_fofs |= pe_fofs_parity;
      ehdr_has_changed = 1;
    }
    if (mz_message) {
      for (cp = (char*)&u.mzhdr.relocpos; *mz_message != '\0' && cp != (char*)&u.mzhdr.pe_fofs; ++cp, ++mz_message) {
        if (*cp != *mz_message) { ehdr_has_changed = 1; *cp = *mz_message; }
      }
      for (; cp != (char*)&u.mzhdr.pe_fofs; ++cp) {
        if (*cp != '\0') { ehdr_has_changed = 1; *cp = '\0'; }
      }
    }
    if (ehdr_has_changed) {
      off = 0;
      if (lseek(fd, off, SEEK_SET) != off) {  /* This succeeds even if the file is shorter. */
        fprintf(stderr, "fatal: error seeking to PE mzhdr: %s\n", filename);
        return 22;
      }
      if ((size_t)write(fd, &u.mzhdr, sizeof(u.mzhdr)) != sizeof(u.mzhdr)) {
        fprintf(stderr, "fatal: error changing PE mzhdr: %s\n", filename);
        return 23;
      }
    }
    if (flag_pt0 || flag_ph0 || flag_ps) {
      ehdr_has_changed = 0;
      off = u.mzhdr.pe_fofs & ~(uint32_t)1U;
      if (lseek(fd, off, SEEK_SET) != off) {  /* This succeeds even if the file is shorter. */
        fprintf(stderr, "fatal: error seeking to PE pehdr: %s\n", filename);
        return 22;
      }
      if (read(fd, &u.pehdr, sizeof(u.pehdr)) != sizeof(u.pehdr)) {
        fprintf(stderr, "fatal: error reading PE pehdr: %s\n", filename);
        return 3;
      }
      if (memcmp(u.pehdr.Signature, "PE\0", 4) != 0) {
        fprintf(stderr, "fatal: bad PE signature: %s\n", filename);
        return 4;
      }
      if (flag_pt0 && u.pehdr.TimeDateStamp != 0) {
        ehdr_has_changed = 1;
        u.pehdr.TimeDateStamp = 0;
      }
      if (flag_ph0 && (u.pehdr.SizeOfHeapReserve != 0 || u.pehdr.SizeOfHeapCommit != 0)) {
        ehdr_has_changed = 1;
        u.pehdr.SizeOfHeapReserve = 0;
        u.pehdr.SizeOfHeapCommit = 0;
      }
      if (flag_ps) {
        if (u.pehdr.SizeOfStackCommit < 0x1000) {
          ehdr_has_changed = 1;
          u.pehdr.SizeOfStackCommit = 0x1000;
        }
        if (u.pehdr.SizeOfStackCommit & 0xfff) {
          ehdr_has_changed = 1;
          u.pehdr.SizeOfStackCommit = (u.pehdr.SizeOfStackCommit + 0xfff) & ~0xfffU;  /* Incorrect on overflow. */
        }
        if (u.pehdr.SizeOfStackReserve < u.pehdr.SizeOfStackCommit) {
          ehdr_has_changed = 1;
          u.pehdr.SizeOfStackReserve = u.pehdr.SizeOfStackCommit;
        }
        if (u.pehdr.SizeOfStackReserve & 0xffff) {
          ehdr_has_changed = 1;
          u.pehdr.SizeOfStackReserve = (u.pehdr.SizeOfStackReserve + 0xffff) & ~0xffffU;  /* Incorrect on overflow. */
        }
      }
      if (ehdr_has_changed) {
        if (lseek(fd, off, SEEK_SET) != off) {  /* This succeeds even if the file is shorter. */
          fprintf(stderr, "fatal: error seeking to PE pehdr: %s\n", filename);
          return 22;
        }
        if ((size_t)write(fd, &u.pehdr, sizeof(u.pehdr)) != sizeof(u.pehdr)) {
          fprintf(stderr, "fatal: error changing PE pehdr: %s\n", filename);
          return 23;
        }
      }
    }
    return 0;
  }
#endif
  if (read(fd, &ehdr, sizeof(ehdr)) != sizeof(ehdr)) {
    fprintf(stderr, "fatal: error reading ELF ehdr: %s\n", filename);
    return 3;
  }
  if (memcmp(ehdr.e_ident, "\x7f""ELF", 4) != 0) {
    fprintf(stderr, "fatal: bad ELF signature: %s\n", filename);
    return 4;
  }
  if (ehdr.e_ident[4] != 1 || (ehdr.e_ident[5] != 1 && ehdr.e_ident[5] != 2) || ehdr.e_ident[6] != 1) {
    fprintf(stderr, "fatal: bad ELF e_ident: %s\n", filename);
    return 5;
  }
#if defined(__BIG_ENDIAN__) || (defined(__BYTE_ORDER__) && defined(__ORDER_LITTLE_ENDIAN__) && __BYTE_ORDER__ != __ORDER_LITTLE_ENDIAN__) || \
    defined(__ARMEB__) || defined(__THUMBEB__) || defined(__AARCH64EB__) || defined(_MIPSEB) || defined(__MIPSEB) || defined(__MIPSEB__) || \
    defined(__powerpc__) || defined(_M_PPC) || defined(__m68k__) || defined(_ARCH_PPC) || defined(__PPC__) || defined(__PPC) || defined(PPC) || \
    defined(__powerpc) || defined(powerpc) || (defined(__BIG_ENDIAN) && (!defined(__BYTE_ORDER) || __BYTE_ORDER == __BIG_ENDIAN +0)) || \
    defined(_BIG_ENDIAN)
#  error This program requires a little-endian system for ELF.  /* Otherwise we would have to do byte order conversion on header fields. */
#endif
#if defined(__LITTLE_ENDIAN__) || (defined(__BYTE_ORDER__) && defined(__ORDER_LITTLE_ENDIAN__) && __BYTE_ORDER__ == __ORDER_LITTLE_ENDIAN__) || \
    defined(__ARMEL__) || defined(__THUMBEL__) || defined(__AARCH64EL__) || defined(_MIPSEL) || defined (__MIPSEL) || defined(__MIPSEL__) || \
    defined(__ia64__) || defined(__LITTLE_ENDIAN) || defined(_LITTLE_ENDIAN) || defined(MSDOS) || defined(__MSDOS__) || IS_X86
  /* Known good little-endian system. */
#else
#  error This program requires a little-endian system. Endianness not detected by C macros.
#endif
  if (ehdr.e_type != ET_EXEC) {
    if (ehdr.e_type == ET_EXEC << 8) {
      fprintf(stderr, "fatal: bad ELF byte order: %s\n", filename);
      return 6;
    } else {
      fprintf(stderr, "fatal: not an ELF executable program: %s\n", filename);
      return 7;
    }
  }
  if (ehdr.e_version != 1) {
    fprintf(stderr, "fatal: bad ELF e_version: %s\n", filename);
    return 8;
  }
  brand = osabi == ELFOSABI_FREEBSD ? "FreeBSD" : "\0\0\0\0\0\0\0";
  if (osabi != (unsigned char)-1 && (ehdr.e_ident[EI_OSABI] != osabi || memcmp(&ehdr.e_ident[EI_BRAND], brand, 8) != 0)) {
    ehdr.e_ident[EI_OSABI] = osabi;
    memcpy(&ehdr.e_ident[EI_BRAND], brand, 8);  /* By copying "FreeBSD" here, it makes the program work on FreeBSD 3.0. Some later version of FreeBSD has dropped this requirement. */
    ehdr_has_changed = 1;
    if (!flag_s && !is_fixing) {
      off = EI_OSABI;
      if (lseek(fd, off, SEEK_SET) != off) {  /* This succeeds even if the file is shorter. */
        fprintf(stderr, "fatal: error seeking to ELF e_ident EI_OSABI: %s\n", filename);
        return 9;
      }
      if (write(fd, &ehdr.e_ident[EI_OSABI], 1 + 8) != 1 + 8) {  /* Also writes EI_BRAND. */
        fprintf(stderr, "fatal: error changing ELF e_ident EI_OSABI: %s\n", filename);
        return 10;
      }
      return 0;  /* EXIT_SUCCESS. */
    }
  }
  if (!flag_s && !is_fixing) return 0;  /* EXIT_SUCCESS. */
  if (ehdr.e_phoff < 0x34) {
    fprintf(stderr, "fatal: bad ELF e_phoff: %s\n", filename);
    return 11;
  }
  if (ehdr.e_phentsize != 0x20) {
    fprintf(stderr, "fatal: unexpected ELF e_phentsize: %s\n", filename);
    return 12;
  }
  if (ehdr.e_phnum == 0) {
    fprintf(stderr, "fatal: no ELF program header sections: %s\n", filename);
    return 13;
  }
  if (ehdr.e_phnum > sizeof(phdrs) / sizeof(phdrs[0])) {
    fprintf(stderr, "fatal: too many ELF program header sections: %s\n", filename);
    return 14;
  }
  off = ehdr.e_phoff;
  if (lseek(fd, off, SEEK_SET) != off) {  /* This succeeds even if the file is shorter. */
    fprintf(stderr, "fatal: error seeking to ELF phdr: %s\n", filename);
    return 15;
  }
  want = ehdr.e_phnum * sizeof(phdrs[0]);
  if ((size_t)read(fd, phdrs, want) != (size_t)want) {
    fprintf(stderr, "fatal: error reading ELF phdr: %s\n", filename);
    return 16;
  }
  if (flag_h) {
    if (ehdr.e_shentsize == 0) {
      ehdr.e_shentsize = 0x28;
      ehdr_has_changed = 1;
    }
  }
  phdr_end = phdrs + ehdr.e_phnum;
  last_off = ehdr.e_phoff + want;
  for (phdr = phdrs, pt_load_count = 0; phdr != phdr_end; ++phdr) {
    if (phdr->p_type == PT_LOAD) ++pt_load_count;
  }
  for (phdr = phdrs; phdr != phdr_end; ++phdr) {
    if (phdr->p_type == PT_LOAD) {
      if (pt_load_count == 1 && phdrs->p_align < 0x1000) {  /* Typical GNU ld(1) `ld -N' output: p_align == 4. */
        phdr_has_changed = 1;
        phdrs->p_align = 0x1000;
      }
      if (flag_a && phdr->p_paddr == 0 && phdr->p_vaddr != 0) {
        phdr->p_paddr = phdr->p_vaddr;
        phdr_has_changed = 1;
      }
#ifdef ENABLE_ELFDATAMOVE  /* Can be defined on the command line. */
      if (flag_a && flag_md && phdr->p_align < 0x1000) {
        phdr->p_align = 0x1000;
        phdr_has_changed = 1;
      }
#endif
      if (flag_a && is_first_pt_load && phdr->p_offset < phdr->p_align &&
          phdr->p_offset > 0 &&
          (phdr->p_offset & (phdr->p_align - 1)) == (phdr->p_vaddr & (phdr->p_align - 1))) {
        want = phdr->p_offset;
        phdr->p_memsz += want;
        phdr->p_filesz += want;
        phdr->p_vaddr -= want;
        phdr->p_paddr -= want;
        phdr->p_offset = 0;
        phdr_has_changed = 1;
      }
      if (flag_s && phdr->p_filesz > 0) {
        end_off = phdr->p_offset + phdr->p_filesz;
        if (end_off > last_off) last_off = end_off;
      }
      if (is_first_pt_load) {
        is_first_pt_load = 0;
      }
    }
  }
#ifdef ENABLE_ELFDATAMOVE  /* Can be defined on the command line. */
  if (flag_md) {
    data_delta = 0;
    if (pt_load_count > 2) {
      fprintf(stderr, "fatal: too many PT_LOADs in ELF phdr: %s\n", filename);
      return 30;
    } else if (pt_load_count == 2) {
      for (ptload0 = ptload1 = NULL, phdr = phdrs; phdr != phdr_end; ++phdr) {
        if (phdr->p_type == PT_LOAD) *(ptload0 ? &ptload1 : &ptload0) = phdr;
      }
      data_vstart0 = ptload1->p_vaddr;
      if (data_vstart0 < ptload0->p_vaddr + ptload0->p_memsz) {
        fprintf(stderr, "fatal: bad p_vaddr order in ELF phdr: %s\n", filename);
        return 31;
      }
      if ((data_vstart0 & ~0xfff) < ptload0->p_vaddr + ptload0->p_memsz) {
        /* data_delta is typically 0x1000 (== 4 KiB) for ELF-32 executables created by OpenWatcom v2 wlink: wlink form elf op obja=0x10 */
        data_delta = ((ptload0->p_vaddr + ptload0->p_memsz + 0xfff) & ~0xfff) - (data_vstart0 & ~0xfff);
        /* TODO(pts): Check for overflow in data_data and also when applying data_delta. */
        ptload1->p_paddr = ptload1->p_vaddr += data_delta;
        phdr_has_changed = 1;
      }
    }
    if (data_delta) {
      shdr_has_changed = sym_has_changed = 0; max_rela_size = 0;
      data_vstart1 = data_vstart0 + data_delta;
      if (ehdr.e_shentsize != sizeof(shdrs[0])) {
        fprintf(stderr, "fatal: bad ELF e_shentsize for -md: %s\n", filename);
        return 32;
      }
      if (!ehdr.e_shnum) {
        fprintf(stderr, "fatal: missing ELF sections for -md: %s\n", filename);
        return 33;
      }
      if (ehdr.e_shoff < ehdr.e_phoff + ehdr.e_phnum * sizeof(Elf32_Phdr)) {
        fprintf(stderr, "fatal: bad ELF e_shoff for -md: %s\n", filename);
        return 34;
      }
      off = ehdr.e_shoff;
      if (lseek(fd, off, SEEK_SET) != off) {  /* This succeeds even if the file is shorter. */
        fprintf(stderr, "fatal: error seeking to ELF shdr: %s\n", filename);
        return 35;
      }
      want = ehdr.e_shnum * sizeof(shdrs[0]);  /* TODO(pts): Check for overflow. */
      if (!(shdrs = (Elf32_Shdr*)malloc(want))) {  /* This will be leaked. */
        fprintf(stderr, "fatal: not enough memory for ELF shdr: %s\n", filename);
        return 36;
      }
      if ((size_t)read(fd, shdrs, want) != (size_t)want) {
        fprintf(stderr, "fatal: error reading ELF shdr: %s\n", filename);
        return 37;
      }
      shdr_end = shdrs + ehdr.e_shnum;
      shdr_symtab = NULL;
      for (shdr = shdrs, rela_count = 0; shdr != shdr_end; ++shdr) {
        if (shdr->sh_type == SHT_PROGBITS || shdr->sh_type == SHT_NOBITS) {
          if ((shdr->sh_flags & SHF_ALLOC) && shdr->sh_addr >= data_vstart0) {
            shdr->sh_addr += data_delta;
            shdr_has_changed = 1;
          }
        } else if (shdr->sh_type == SHT_REL) {
          fprintf(stderr, "fatal: unsupported ELF shdr sh_type SHT_REL: %s\n", filename);
          return 38;
        } else if (shdr->sh_type == SHT_RELA) {
          if (shdr->sh_entsize != sizeof(Elf32_Rela)) {
            fprintf(stderr, "fatal: bad ELF rela sh_entsize: %s\n", filename);
            return 39;
          }
          if (!shdr->sh_size) {
            fprintf(stderr, "fatal: zero ELF rela sh_size: %s\n", filename);
            return 40;
          }
          if (shdr->sh_size % sizeof(Elf32_Rela)) {
            fprintf(stderr, "fatal: bad ELF rela sh_size: %s\n", filename);
            return 41;
          }
          if (shdr->sh_offset < ehdr.e_phoff + ehdr.e_phnum * sizeof(Elf32_Phdr)) {
            fprintf(stderr, "fatal: bad ELF rela sh_offset: %s\n", filename);
            return 42;
          }
          if (shdr->sh_info >= ehdr.e_shnum || shdrs[shdr->sh_info].sh_type != SHT_PROGBITS || !(shdrs[shdr->sh_info].sh_flags & SHF_ALLOC)) {
            fprintf(stderr, "fatal: bad ELF rela sh_info: %s\n", filename);
            return 43;
          }
          if (shdr->sh_size > max_rela_size) max_rela_size = shdr->sh_size;
          ++rela_count;
        } else if (shdr->sh_type == SHT_SYMTAB) {
          if (shdr_symtab) {
            fprintf(stderr, "fatal: duplicate ELF symtab: %s\n", filename);
            return 44;
          }
          shdr_symtab = shdr;
          if (shdr_symtab->sh_entsize != sizeof(Elf32_Sym)) {
            fprintf(stderr, "fatal: bad ELF symtab sh_entsize: %s\n", filename);
            return 45;
          }
          if (!shdr_symtab->sh_size) {
            fprintf(stderr, "fatal: zero ELF symtab sh_size: %s\n", filename);
            return 46;
          }
          if (shdr_symtab->sh_size % sizeof(Elf32_Sym)) {
            fprintf(stderr, "fatal: bad ELF symtab sh_size: %s\n", filename);
            return 47;
          }
          if (shdr_symtab->sh_offset < ehdr.e_phoff + ehdr.e_phnum * sizeof(Elf32_Phdr)) {
            fprintf(stderr, "fatal: bad ELF symtab sh_offset: %s\n", filename);
            return 48;
          }
        }
      }
      if (!shdr_symtab) {
        fprintf(stderr, "fatal: missing ELF symtab: %s\n", filename);
        return 49;
      }
      if (!rela_count) {
        /* This may fail for very simple C programs without any global
         * variables. To work around it, add a global variable access to
         * your program (e.g. `char dummy, *dummy_p = &dummy;'). Some libcs
         * access _edata and _end in their _start functions, which creates
         * ELF section .rela.text, satisfying this condition.
         */
        fprintf(stderr, "fatal: missing ELF rela: %s\n", filename);
        return 50;
      }
      sym_count = shdr_symtab->sh_size / sizeof(syms[0]);
      off = shdr_symtab->sh_offset;
      if (lseek(fd, off, SEEK_SET) != off) {  /* This succeeds even if the file is shorter. */
        fprintf(stderr, "fatal: error seeking to ELF symtab: %s\n", filename);
        return 51;
      }
      want = shdr_symtab->sh_size;
      if (!(syms = (Elf32_Sym*)malloc(want))) {  /* This will be leaked. */
        fprintf(stderr, "fatal: not enough memory for ELF symtab: %s\n", filename);
        return 52;
      }
      if ((size_t)read(fd, syms, want) != (size_t)want) {
        fprintf(stderr, "fatal: error reading ELF symtab: %s\n", filename);
        return 53;
      }
      sym_end = syms + shdr_symtab->sh_size / sizeof(syms[0]);
      for (sym = syms; sym != sym_end; ++sym) {
        if (ELF32_ST_TYPE(sym->st_info) > STT_SECTION) {
          fprintf(stderr, "fatal: unsupported ELF symbol type: %s\n", filename);
          return 54;
        }
      }
      if (!(relas = (Elf32_Rela*)malloc(max_rela_size))) {  /* This will be leaked. */
        fprintf(stderr, "fatal: not enough memory for ELF rela: %s\n", filename);
        return 55;
      }
      if (!(rwbuf = (unsigned char*)malloc(RWBUF_SIZE))) {  /* This will be leaked. */
        fprintf(stderr, "fatal: not enough memory for rwbuf: %s\n", filename);
        return 56;
      }
      if (shdr_has_changed) {  /* !! Don't write any changes if reporting an error later. */
        off = ehdr.e_shoff;
        if (lseek(fd, off, SEEK_SET) != off) {  /* This succeeds even if the file is shorter. */
          fprintf(stderr, "fatal: error seeking to ELF shdr again: %s\n", filename);
          return 57;
        }
        want = ehdr.e_shnum * sizeof(shdrs[0]);
        if ((size_t)write(fd, shdrs, want) != (size_t)want) {
          fprintf(stderr, "fatal: error changing ELF shdr: %s\n", filename);
          return 58;
        }
      }
      for (shdr = shdrs; shdr != shdr_end; ++shdr) {
        if (shdr->sh_type != SHT_RELA) continue;
        off = shdr->sh_offset;
        if (lseek(fd, off, SEEK_SET) != off) {  /* This succeeds even if the file is shorter. */
          fprintf(stderr, "fatal: error seeking to ELF rela: %s\n", filename);
          return 59;
        }
        want = shdr->sh_size;
        if ((size_t)read(fd, relas, want) != (size_t)want) {
          fprintf(stderr, "fatal: error reading ELF rela: %s\n", filename);
          return 60;
        }
        rela_end = relas + shdr->sh_size / sizeof(relas[0]);
        rela_shdr_off = shdrs[shdr->sh_info].sh_offset;  /* File offset. */
        rela_shdr_vstart = shdrs[shdr->sh_info].sh_addr;  /* In-memory vstart. */
        for (rela = relas; rela != rela_end; ++rela) {
          if (ELF32_R_TYPE(rela->r_info) == R_386_NONE) continue;
          if (ELF32_R_SYM(rela->r_info) >= sym_count || syms[ELF32_R_SYM(rela->r_info)].st_shndx == SHN_UNDEF) {
            fprintf(stderr, "fatal: bad ELF rela sym: %s\n", filename);
            return 61;
          }
          if (ELF32_R_TYPE(rela->r_info) != R_386_32 && ELF32_R_TYPE(rela->r_info) != R_386_PC32) {
            fprintf(stderr, "fatal: bad ELF rela type: %s\n", filename);
            return 62;
          }
        }
        for (rela = relas; rela != rela_end;) {
          if (ELF32_R_TYPE(rela->r_info) == R_386_NONE) { ++rela; continue; }
          rela_delta = (syms[ELF32_R_SYM(rela->r_info)].st_value >= data_vstart0) ? data_delta : 0;
          if (ELF32_R_TYPE(rela->r_info) == R_386_PC32 && rela_shdr_vstart >= data_vstart1) rela_delta -= data_delta;  /* Typically R_386_PC32 relocations are not present. */
          if (rela_delta == 0) { ++rela; continue; }
          rela_offset = rela->r_offset;
          for (rela2 = rela + 1;  /* Scan for more relas with ->r_offset within RWBUF_SIZE. */
               rela2 != rela_end &&
                   ELF32_R_TYPE(rela2->r_info) != R_386_NONE &&
                   (syms[ELF32_R_SYM(rela->r_info)].st_value >= data_vstart0) != (ELF32_R_TYPE(rela->r_info) == R_386_PC32 && rela_shdr_vstart >= data_vstart1) &&
                   rela2->r_offset <= rela_offset + (RWBUF_SIZE - 4);
               ++rela2) {}
          off = (Elf32_Off)(rela_shdr_off + rela_offset);
          if (lseek(fd, off, SEEK_SET) != off) {  /* This succeeds even if the file is shorter. */
            fprintf(stderr, "fatal: error seeking to ELF rela target: %s\n", filename);
            return 63;
          }
          want = (rela2 - 1)->r_offset + 4 - rela_offset;
          if ((size_t)read(fd, rwbuf, want) != want) {
            fprintf(stderr, "fatal: error reading ELF rela target: %s\n", filename);
            return 64;
          }
          for (; rela != rela2; ++rela) {
            if (ELF32_R_TYPE(rela->r_info) == R_386_NONE) continue;
            rela_delta = (syms[ELF32_R_SYM(rela->r_info)].st_value >= data_vstart0) ? data_delta : 0;
            if (ELF32_R_TYPE(rela->r_info) == R_386_PC32 && rela_shdr_vstart >= data_vstart1) rela_delta -= data_delta;  /* Typically R_386_PC32 relocations are not present. */
            if (rela_delta == 0) continue;
            add_u32(rwbuf + (rela->r_offset - rela_offset), rela_delta);
          }
          if (lseek(fd, off, SEEK_SET) != off) {  /* This succeeds even if the file is shorter. */
            fprintf(stderr, "fatal: error seeking to ELF rela target again: %s\n", filename);
            return 65;
          }
          if ((size_t)write(fd, rwbuf, want) != want) {
            fprintf(stderr, "fatal: error changing ELF rela target: %s\n", filename);
            return 66;
          }
        }
      }
      for (sym = syms; sym != sym_end; ++sym) {
        if (sym->st_shndx == SHN_UNDEF) continue;
        if (sym->st_value >= data_vstart0) {
          sym->st_value += data_delta;
          sym_has_changed = 1;
        }
      }
      if (sym_has_changed) {
        off = shdr_symtab->sh_offset;
        if (lseek(fd, off, SEEK_SET) != off) {  /* This succeeds even if the file is shorter. */
          fprintf(stderr, "fatal: error seeking to ELF sym again: %s\n", filename);
          return 67;
        }
        want = shdr_symtab->sh_size;
        if ((size_t)write(fd, syms, want) != (size_t)want) {
          fprintf(stderr, "fatal: error changing ELF sym: %s\n", filename);
          return 68;
        }
      }
    }
  }
#endif

  if (phdr_has_changed) {
    off = ehdr.e_phoff;
    if (lseek(fd, off, SEEK_SET) != off) {  /* This succeeds even if the file is shorter. */
      fprintf(stderr, "fatal: error seeking to ELF phdr again: %s\n", filename);
      return 17;
    }
    want = ehdr.e_phnum * sizeof(phdrs[0]);
    if ((size_t)write(fd, phdrs, want) != (size_t)want) {
      fprintf(stderr, "fatal: error changing ELF phdr: %s\n", filename);
      return 18;
    }
  }
  if (flag_s) {
    if ((off = lseek(fd, 0, SEEK_END)) == (off_t)-1) {
      fprintf(stderr, "fatal: error seeking to end of ELF: %s\n", filename);
      return 19;
    }
    if ((off_t)last_off > off) {
      fprintf(stderr, "fatal: loaded ELF program too short: %s\n", filename);
      return 20;
    }
    if ((off_t)last_off < off && ftruncate(fd, last_off) != 0) {
      fprintf(stderr, "fatal: error truncating ELF program: %s\n", filename);
      return 21;
    }
    if ((ehdr.e_shoff != 0) || (ehdr.e_shnum != 0) || (ehdr.e_shstrndx != 0)) ehdr_has_changed = 1;
    ehdr.e_shoff = 0;
    ehdr.e_shnum = 0;
    ehdr.e_shstrndx = 0;
  }
  if (ehdr_has_changed) {
    off = 0;
    if (lseek(fd, off, SEEK_SET) != off) {  /* This succeeds even if the file is shorter. */
      fprintf(stderr, "fatal: error seeking to ELF ehdr: %s\n", filename);
      return 22;
    }
    if ((size_t)write(fd, &ehdr, sizeof(ehdr)) != sizeof(ehdr)) {
      fprintf(stderr, "fatal: error changing ELF ehdr: %s\n", filename);
      return 23;
    }
  }
  /*close(fd);*/  /* No need, we are exiting anyway. */
  return 0;
}
