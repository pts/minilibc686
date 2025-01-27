/*
 * sstrip: strip parts of ELF executables not needed for execution
 * by pts@fazekas.hu at Wed May 24 02:20:35 CEST 2023
 *
 * Compile: pathbin/minicc --noenv --gcc=4.8 -o tools/sstrip tools/sstrip.c
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

#include <fcntl.h>
#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

#if defined(__i386) || defined(__i386__) || defined(__amd64__) || defined(__x86_64__) || defined(_M_X64) || defined(_M_AMD64) || defined(__386) || \
    defined(__X86_64__) || defined(_M_I386) || defined(_M_I86) || defined(_M_X64) || defined(_M_AMD64) || defined(_M_IX86) || defined(__386__) || \
    defined(__X86__) || defined(__I86__) || defined(_M_I86) || defined(_M_I8086) || defined(_M_I286)
#  define IS_X86 1
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

#define ET_EXEC		2		/* Executable file */

#define EI_OSABI	7		/* OS ABI identification */
#define ELFOSABI_SYSV		0	/* Alias.  */
#define ELFOSABI_GNU		3	/* Object uses GNU ELF extensions.  */
#define ELFOSABI_LINUX		ELFOSABI_GNU /* Compatibility alias.  */

#define PT_LOAD		1		/* Loadable program segment */

/* --- */

/* It doesn't work with smaller int sizes, some `int' and `unsigned' variables are too small. */
typedef char static_assert_sizeof_int[sizeof(int) >= 4 ? 1 : -1];

int main(int argc, char **argv) {
  char new_char[1];
  int fd;
  const char *filename;
  Elf32_Ehdr ehdr;
  off_t off;
  size_t want;
  static Elf32_Phdr phdrs[0x80];
  Elf32_Phdr *phdr, *phdr_end;
  const char *arg;
  char **argp;
  char c;
  char flag_l = 0, flag_a = 1, flag_s = 1, flag_h = 1, is_verbose = 0;
  const char flag_z = 0;
  char phdr_has_changed = 0, ehdr_has_changed = 1;
  char is_first_pt_load = 1;
  Elf32_Off end_off, last_off, pt_load_count;

  (void)argc; (void)argv;
  if (!argv[0] || !argv[1] || strcmp(argv[1], "--help") == 0) {
    fprintf(stderr, "Usage: %s [<flag>...] <elfprog>\nFlags:\n"
            "-v: verbose operation, write info to stderr\n"
            "-l: change the ELF OSABI to Linux\n"
            "-a: align the early PT_LOAD phdr to page size (enabled by default)\n"
            "-na: disable -a\n"
            "-h: fix ELF section header size (enabled by default)\n"
            "-nh: disable -h\n"
            "-s: strip beyond the last PT_LOAD (sstrip) (strip default, enabled by default)\n"
            "-ns: disable -s\n"
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
    } else if (arg[2] != '\0') {
      goto unknown_flag;
    } else if (c == 'v') {
      is_verbose = 1;
    } else if (c == 'l') {
      flag_l = 1;
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
    } else if (c == 'x' || c == 'X' || c == 'N' || c == 'R') {
      if (!argp[1]) {
        fprintf(stderr, "fatal: missing argument for flag: %s\n", arg);
        return 1;
      }
      ++argp;
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

  if (is_verbose) {  /* GNU strip(1) comaptibility. */
    fprintf(stderr, "info: %s: %s\n", flag_s ? (flag_l || flag_a ? "stripping and fixing" : "stripping") : (flag_l || flag_a ? "fixing" : "checking"), filename);
  }
  if ((fd = open(filename, O_RDWR)) < 0) {
    fprintf(stderr, "fatal: error opening for read-write: %s\n", filename);
    return 2;
  }
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
  if (flag_l && ehdr.e_ident[EI_OSABI] != ELFOSABI_LINUX) {
    if (!flag_a && !flag_s && !flag_z) {
      off = EI_OSABI;
      if (lseek(fd, off, SEEK_SET) != off) {  /* This succeeds even if the file is shorter. */
        fprintf(stderr, "fatal: error seeking to ELF e_ident EI_OSABI: %s\n", filename);
        return 9;
      }
      if (write(fd, new_char, 1) != 1) {
        fprintf(stderr, "fatal: error changing ELF e_ident EI_OSABI: %s\n", filename);
        return 10;
      }
      return 0;  /* EXIT_SUCCESS. */
    } else {
      ehdr.e_ident[EI_OSABI] = new_char[0] = ELFOSABI_LINUX;
      ehdr_has_changed = 1;
    }
  }
  if (!flag_a && !flag_s && !flag_z) return 0;  /* EXIT_SUCCESS. */
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
