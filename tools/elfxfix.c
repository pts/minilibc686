/*
 * elfxfix: do various fixes on ELF executables
 * by pts@fazekas.hu at Wed May 24 02:20:35 CEST 2023
 *
 * Compile: pathbin/minicc --noenv --gcc=4.8 -o tools/elfxfix.new tools/elfxfix.c
 */

#include <fcntl.h>
#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

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
#define ELFOSABI_FREEBSD	9

#define PT_LOAD		1		/* Loadable program segment */

/* --- */

#define CHR4(a, b, c, d) ((Elf32_Off)(a) | (Elf32_Off)(b) << 8 | (Elf32_Off)(c) << 16 | (Elf32_Off)(d) << 24)

#if 0
const unsigned bss_o_bss_size_idx = 0x20;
static Elf32_Off bss_o[] = {  /* ELF-32 .o file containing data of a specific specified size in section .bss. */
    CHR4(0x7f, 'E', 'L', 'F'), 0x10101, 0, 0, 0x30001, 1, 0, 0, 0x44, 0,
    0x34, 0x280000, 0x20003,
    CHR4(0, '.', 's', 'h'), CHR4('s', 't', 'r', 't'), CHR4('a', 'b', 0, '.'),
    CHR4('b', 's', 's', 0), 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0xb, 8, 3, 0, 0x34,
    0 /* EXTRA_BSS_SIZE */, 0, 0, 1, 0, 1, 3, 0, 0, 0x34, 0x10, 0, 0, 1, 0};
/* This doesn't work well with the `-r' flag, because the user of the `-r'
 * flag assumes that the extra size was added to the end of .bss. But common
 * symbols come even later, so to get really the end, add a common symbol
 * instead, which we do below.
 */
#elif 0
const unsigned bss_o_bss_size_idx = 0x13;
static Elf32_Off bss_o[] = {  /* ELF-32 .o file containing a common symbol named .linkpad of the specified size. */
    CHR4(0x7f, 'E', 'L', 'F'), 0x010101, 0, 0, 0x030001, 1, 0, 0, 0x7c, 0,
    0x34, 0x280000, 0x030004, 0, 0, 0, 0, 1,
    1 /* EXTRA_COMMON_ALIGNMENT */, 0 /* EXTRA_COMMON_SIZE */,
    0xfff20011, CHR4(0, '.', 'l', 'i'), CHR4('n', 'k', 'p', 'a'),
    CHR4('d', 0, 0, '.'), CHR4('s', 'y', 'm', 't'), CHR4('a', 'b', 0, '.'),
    CHR4('s', 't', 'r', 't'), CHR4('a', 'b', 0, '.'), CHR4('s', 'h', 's', 't'),
    CHR4('r', 't', 'a', 'b'), 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 2, 0, 0,
    0x34, 0x20, 2, 1, 4, 0x10, 9, 3, 0, 0, 0x54, 0xa, 0, 0, 1, 0, 0x11, 3, 0,
    0, 0x5e, 0x1b, 0, 0, 1, 0};
/* This still doesn't work 100% in EGLIBC and glibc, because its .o files
 * have .bss-like (nobits) section __libc_freeres_ptrs, which GNU ld(1) adds
 * after .bss. So to get really the end, we add our own .bss-like section
 * later in lexicographic ordering (~~~~) below.
 */
#else
const unsigned bss_o_bss_size_idx = 0x20;
static Elf32_Off bss_o[] = {  /* ELF-32 .o file containing data of a specific specified size in section ~~~~ (similar to .bss). */
    CHR4(0x7f, 'E', 'L', 'F'), 0x10101, 0, 0, 0x30001, 1, 0, 0, 0x44, 0,
    0x34, 0x280000, 0x20003,
    CHR4(0, '.', 's', 'h'), CHR4('s', 't', 'r', 't'), CHR4('a', 'b', 0, '~'),
    CHR4('~', '~', '~', 0), 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0xb, 8, 3, 0, 0x34,
    0 /* EXTRA_BSS_SIZE */, 0, 0, 1, 0, 1, 3, 0, 0, 0x34, 0x10, 0, 0, 1, 0};
#endif

int main(int argc, char **argv) {
  char new_char[1];
  int fd, fd2;
  const char *filename;
  Elf32_Ehdr ehdr;
  off_t off;
  size_t want;
  static Elf32_Phdr phdrs[0x80];
  static Elf32_Off bss_o_tmp[sizeof(bss_o) / sizeof(bss_o[0])];
  Elf32_Phdr *phdr, *phdr_end, *phdrl0, *phdr2;
  const char *arg;
  char **argp;
  unsigned char osabi = (unsigned char)-1;
  char flag_a = 0, flag_s = 0, flag_p = 0, flag_r = 0, is_verbose = 0;
  char phdr_has_changed = 0, ehdr_has_changed = 1;
  char is_first_pt_load = 1;
  char can_fix;
  const char *fix_o_fn = NULL;  /* Use NULL to pacify GCC. */
  Elf32_Off end_off, last_off, sz, sz2, pt_load_count;

  (void)argc; (void)argv;
  if (!argv[0] || !argv[1] || strcmp(argv[1], "--help") == 0) {
    fprintf(stderr, "Usage: %s [<flag>...] <elfprog>\nFlags:\n"
            "-v: verbose operation, write info to stderr\n"
            "-l or -ll: change the ELF OSABI to Linux\n"
            "-lf: change the ELF OSABI to FreeBSD\n"
            "-ls: change the ELF OSABI to SYSV\n"
            "-a: align the early PT_LOAD phdr to page size\n"
            "-s: strip beyond the last PT_LOAD (sstrip)\n"
            "-p <fix.o>: detect the GNU ld .data padding bug\n"
            "-r <fix.o>: make .bss smaller by fix.o\n",
            argv[0]);
    return !argv[0] || !argv[1];  /* 0 (EXIT_SUCCESS) for--help. */
  }
  for (argp = argv + 1; (arg = *argp) != NULL; ++argp) {
    if (arg[0] != '-') break;
    if (arg[1] == '\0') break;
    if (arg[1] == '-' && arg[2] == '\0') {
      ++argp;
      break;
    } else if (arg[1] == 'l' && arg[2] != '\0' && arg[3] == '\0') {
      if (arg[2] == 'l') {
        osabi = ELFOSABI_LINUX;
      } else if (arg[2] == 'f') {
        osabi = ELFOSABI_FREEBSD;
      } else if (arg[2] == 's') {
        osabi = ELFOSABI_SYSV;
      } else {
        goto unknown_flag;
      }
    } else if (arg[2] != '\0') {
      goto unknown_flag;
    } else if (arg[1] == 'v') {
      is_verbose = 1;
    } else if (arg[1] == 'l') {
      osabi = ELFOSABI_LINUX;
    } else if (arg[1] == 'a') {
      flag_a = 1;
    } else if (arg[1] == 's') {
      flag_s = 1;
    } else if (arg[1] == 'p' && argp[1]) {
      flag_p = 1;
      fix_o_fn = *++argp;
    } else if (arg[1] == 'r' && argp[1]) {
      flag_r = 1;
      fix_o_fn = *++argp;
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
  if (osabi != (unsigned char)-1 && ehdr.e_ident[EI_OSABI] != osabi) {
    ehdr.e_ident[EI_OSABI] = new_char[0] = osabi;
    ehdr_has_changed = 1;
    if (!flag_s && !flag_a && !flag_p) {
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
    }
  }
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
  phdr_end = phdrs + ehdr.e_phnum;
  last_off = ehdr.e_phoff + want;
  phdrl0 = NULL;
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
      if (flag_p && !is_first_pt_load &&
          phdrl0->p_vaddr == phdrl0->p_paddr &&
          phdr->p_vaddr == phdr->p_paddr &&
          phdrl0->p_filesz == phdrl0->p_memsz &&
          phdr->p_offset >= (sz = phdrl0->p_offset + phdrl0->p_memsz) + 4 &&
          (phdr->p_offset & 0xfff) == (phdr->p_vaddr & 0xfff) &&
          (phdr->p_offset & 0xfff) == 0) {
        /* GNU ld(1) 2.24, GNU ld(1) 2.30, GNU gold(1) 2.22 adds this unnecessary padding. */
        sz2 = (sz + (((phdr->p_memsz & 0xfff) + 3) & ~3)) & 0xfff;
        can_fix = sz2 != 0 && sz2 <= sz;
        if (is_verbose) fprintf(stderr, "info: found 0x%x useless bytes between .rodata and .data, we can%s fix it\n", phdr->p_offset - sz, can_fix ? "" : "'t");
        if (can_fix) {
          bss_o[bss_o_bss_size_idx] = sz - sz2 + 1;  /* -3 still works instead of +1, but -4 doesn't. */
          if ((fd2 = open(fix_o_fn, O_WRONLY | O_TRUNC | O_CREAT, 0666)) < 0) {
            fprintf(stderr, "fatal: error opening for write fix.o: %s\n", fix_o_fn);
            return 24;
          }
          if ((size_t)write(fd2, bss_o, sizeof(bss_o)) != sizeof(bss_o)) {
            fprintf(stderr, "fatal: error writing fix.o: %s\n", fix_o_fn);
            return 25;
          }
          close(fd2);
        }
      }
      if (flag_r && !is_first_pt_load &&
          phdr->p_memsz > phdr->p_filesz) {
        for (phdr2 = phdr + 1; phdr2 != phdr_end && phdr2->p_type != PT_LOAD; ++phdr2) {}
        if (phdr2 == phdr_end) {  /* No more PT_LOAD headers. */
          sz = phdr->p_memsz - phdr->p_filesz;
          if ((fd2 = open(fix_o_fn, O_RDONLY, 0666)) < 0) {
            fprintf(stderr, "fatal: error opening for read fix.o: %s\n", fix_o_fn);
            return 26;
          }
          if ((size_t)read(fd2, bss_o_tmp, sizeof(bss_o)) != sizeof(bss_o)) {
            fprintf(stderr, "fatal: error reading fix.o: %s\n", fix_o_fn);
            return 27;
          }
          close(fd2);
          sz2 = bss_o_tmp[bss_o_bss_size_idx];
          if (sz >= sz2) {
            phdr->p_memsz -= sz2;  /* Make .bss smaller. */
            phdr_has_changed = 1;
          }
        }
      }
      if (is_first_pt_load) {
        phdrl0 = phdr;
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
