/*
 * elfofix.c: do various fixes on ELF relocatables (.o files)
 * by pts@fazekas.hu at Thu May 25 22:13:26 CEST 2023
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

#define ET_REL		1		/* Relocatable file */

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

#define SHT_SYMTAB	  2		/* Symbol table */
#define SHT_STRTAB	  3		/* String table */

/* Symbol table entry.  */

typedef struct {
  Elf32_Word	st_name;		/* Symbol name (string tbl index) */
  Elf32_Addr	st_value;		/* Symbol value */
  Elf32_Word	st_size;		/* Symbol size */
  unsigned char	st_info;		/* Symbol type and binding */
  unsigned char	st_other;		/* Symbol visibility */
  Elf32_Section	st_shndx;		/* Section index */
} Elf32_Sym;

#define STB_LOCAL	0		/* Local symbol */
#define STB_GLOBAL      1               /* Global symbol */
#define STB_WEAK        2               /* Weak symbol */
#define STT_SECTION	3		/* Symbol associated with a section */

#define STT_NOTYPE	0		/* Symbol type is unspecified */
#define STT_OBJECT	1		/* Symbol is a data object */
#define STT_FUNC	2		/* Symbol is a code object */

#define ELF32_ST_BIND(val)		(((unsigned char) (val)) >> 4)
#define ELF32_ST_TYPE(val)		((val) & 0xf)
#define ELF32_ST_INFO(bind, type)	(((bind) << 4) + ((type) & 0xf))

#define SHN_UNDEF	0		/* Undefined section */
#define SHN_ABS		0xfff1		/* Associated symbol is absolute */

/* --- */

int main(int argc, char **argv) {
  int fd;
  const char *filename;
  Elf32_Ehdr ehdr;
  Elf32_Shdr *shdrs = NULL, *shdrs_end, *shdr_strtab, *shdr_symtab, *shdr;
  Elf32_Sym *syms = NULL, *syms_end, *sym, *sym2;
  Elf32_Word want, strtab_size;
  unsigned char st_bind, st_type;
  char *strtab = NULL;
  off_t off;
  char syms_has_changed;
#if 0
  char syms_size_has_changed;
#endif
  char is_sym2_found;
  const char *sym_name;
  const char *arg;
  char **argp;
  char is_verbose = 0, flag_w = 0;
  static char str_extern_weak[] = "EXTERN.WEAK..";
  static char str_weak[] = "WEAK..";

  (void)argc; (void)argv;
  if (!argv[0] || !argv[1] || strcmp(argv[1], "--help") == 0) {
    fprintf(stderr, "Usage: %s [<flag>...] <elfobj.o>\nFlags:\n"
            "-v: verbose operation, write info to stderr\n"
            "-w: fix weak symbols for specially crafted .o file\n",
            argv[0]);
    return !argv[0] || !argv[1];  /* 0 (EXIT_SUCCESS) for--help. */
  }
  for (argp = argv + 1; (arg = *argp) != NULL; ++argp) {
    if (arg[0] != '-') break;
    if (arg[1] == '\0') break;
    if (arg[1] == '-' && arg[2] == '\0') {
      ++argp;
      break;
    } else if (arg[2] != '\0') {
      goto unknown_flag;
    } else if (arg[1] == 'v') {
      is_verbose = 1;
    } else if (arg[1] == 'w') {
      flag_w = 1;
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
  if (ehdr.e_type != ET_REL) {
    if (ehdr.e_type == ET_REL << 8) {
      fprintf(stderr, "fatal: bad ELF byte order: %s\n", filename);
      return 6;
    } else {
      fprintf(stderr, "fatal: not an ELF relocatable (.o file): %s\n", filename);
      return 7;
    }
  }
  if (ehdr.e_version != 1) {
    fprintf(stderr, "fatal: bad ELF e_version: %s\n", filename);
    return 8;
  }

  if (ehdr.e_shoff < 0x34) {
    fprintf(stderr, "fatal: bad ELF e_shoff: %s\n", filename);
    return 9;
  }
  if (ehdr.e_shentsize != sizeof(Elf32_Shdr)) {  /* 0x28. */
    fprintf(stderr, "fatal: unexpected ELF shdr size: %s\n", filename);
    return 10;
  }
  if (ehdr.e_shnum == 0) {
    fprintf(stderr, "fatal: no ELF sections: %s\n", filename);
    return 11;
  }
  if (ehdr.e_shstrndx == 0) {
    fprintf(stderr, "fatal: missing .shstrtab section: %s\n", filename);
    return 12;
  }
  if (ehdr.e_shstrndx >= ehdr.e_shnum) {
    fprintf(stderr, "fatal: bad ELF e_shstrndx: %s\n", filename);
    return 13;
  }
  if (!flag_w) return 0;  /* Don't do anything beyond some ELF ehdr field checks. */
  want = ehdr.e_shnum * sizeof(Elf32_Shdr);
  if (ehdr.e_shnum + 0U >= (Elf32_Word)-1 / sizeof(Elf32_Shdr) || (shdrs = malloc(want)) == NULL) {
    fprintf(stderr, "fatal: out of memory for shdr: %s\n", filename);
    return 14;
  }
  off = ehdr.e_shoff;
  if (lseek(fd, off, SEEK_SET) != off) {  /* This succeeds even if the file is shorter. */
    fprintf(stderr, "fatal: error seeking to ELF shdr: %s\n", filename);
    return 15;
  }
  if ((size_t)read(fd, shdrs, want) != (size_t)want) {
    fprintf(stderr, "fatal: error reading ELF shdr: %s\n", filename);
    return 16;
  }
  shdrs_end = shdrs + ehdr.e_shnum;

  shdr_symtab = NULL;
  for (shdr = shdrs; shdr != shdrs_end; ++shdr) {
    if (shdr->sh_type == SHT_SYMTAB) {
      if (shdr_symtab) {
        fprintf(stderr, "fatal: multiple .symtab sections: %s\n", filename);
        return 17;
      }
      shdr_symtab = shdr;
    }
  }
  if (!shdr_symtab) {
    fprintf(stderr, "fatal: missing .symtab section: %s\n", filename);
    return 18;
  }
  if (shdr_symtab->sh_link == 0) {
    fprintf(stderr, "fatal: missing linked .strtab section: %s\n", filename);
    return 19;
  }
  if (shdr_symtab->sh_link >= ehdr.e_shnum) {
    fprintf(stderr, "fatal: bad link to .strtab section: %s\n", filename);
    return 20;
  }
  if (shdr_symtab->sh_entsize != sizeof(Elf32_Sym)) {
    fprintf(stderr, "fatal: unexpected .symtab entry size: %s\n", filename);
    return 21;
  }
  if (shdr_symtab->sh_size % sizeof(Elf32_Sym) != 0) {
    fprintf(stderr, "fatal: unexpected .symtab size: %s\n", filename);
    return 22;
  }
  shdr_strtab = shdrs + shdr_symtab->sh_link;

  shdr = shdr_strtab;
  if (shdr->sh_offset < 0x34) {
    fprintf(stderr, "fatal: bad .strtab sh_offset: %s\n", filename);
    return 23;
  }
  if (shdr->sh_size == 0) {
    fprintf(stderr, "fatal: zero .strtab sh_size: %s\n", filename);
    return 24;
  }
  strtab_size = shdr->sh_size;
  if (strtab_size >= (Elf32_Word)-1 / sizeof(Elf32_Shdr) || (strtab = malloc(strtab_size + 1)) == NULL) {
    fprintf(stderr, "fatal: out of memory for .strtab: %s\n", filename);
    return 25;
  }
  off = shdr->sh_offset;
  if (lseek(fd, off, SEEK_SET) != off) {  /* This succeeds even if the file is shorter. */
    fprintf(stderr, "fatal: error seeking to .strtab: %s\n", filename);
    return 26;
  }
  if ((size_t)read(fd, strtab, strtab_size) != (size_t)strtab_size) {
    fprintf(stderr, "fatal: error reading ELF .strtab: %s\n", filename);
    return 27;
  }
  strtab[strtab_size] = '\0';  /* Sentinel. */

  want = shdr_symtab->sh_size;
  if ((syms = malloc(want)) == NULL) {
    fprintf(stderr, "fatal: out of memory for .symtab: %s\n", filename);
    return 28;
  }
  off = shdr_symtab->sh_offset;
  if (lseek(fd, off, SEEK_SET) != off) {  /* This succeeds even if the file is shorter. */
    fprintf(stderr, "fatal: error seeking to .symtab: %s\n", filename);
    return 29;
  }
  want = shdr_symtab->sh_size;
  if ((size_t)read(fd, syms, want) != (size_t)want) {
    fprintf(stderr, "fatal: error reading .symtab: %s\n", filename);
    return 30;
  }
  syms_end = (Elf32_Sym*)((char*)syms + want);

  syms_has_changed = 0;
#if 0
  syms_size_has_changed = 0;
#endif
  for (sym = syms; sym != syms_end; ++sym) {
    if (sym == syms && sym->st_name == 0) continue;
    if (sym->st_name > strtab_size) {
      fprintf(stderr, "fatal: bad symbol name index: %s\n", filename);
      return 31;
    }
    st_bind = ELF32_ST_BIND(sym->st_info);
    st_type = ELF32_ST_TYPE(sym->st_info);
    if (st_type != STT_NOTYPE && st_type != STT_OBJECT && st_type != STT_FUNC) continue;
#if 0
    fprintf(stderr, "info: name_idx=%d name=%s value=0x%x size=0x%x bind=%d type=%d vis=%d section=%d\n",
            sym->st_name, strtab + sym->st_name,
            sym->st_value, sym->st_size, st_bind, st_type, sym->st_other, sym->st_shndx);
#endif
    if ((st_bind == STB_GLOBAL || st_bind == STB_WEAK) && sym->st_shndx == SHN_UNDEF &&
        memcmp(strtab + sym->st_name, str_extern_weak, sizeof(str_extern_weak) - 1) == 0) {
      sym->st_name += sizeof(str_extern_weak) - 1;  /* Remove prefix. */
      if (is_verbose) fprintf(stderr, "info: marked symbol as extern weak: %s: %s\n", strtab + sym->st_name, filename);
      syms_has_changed = 1;
      st_bind = STB_WEAK;
      sym->st_info = ELF32_ST_INFO(st_bind, st_type);
    } else if (st_bind == STB_LOCAL && sym->st_shndx != SHN_UNDEF &&
               memcmp(strtab + sym->st_name, str_weak, sizeof(str_weak) - 1) == 0) {
      sym_name = strtab + sym->st_name + sizeof(str_weak) - 1;
      if (is_verbose) fprintf(stderr, "info: marked symbol as weak: %s: %s\n", sym_name, filename);
      is_sym2_found = 0;
      for (sym2 = syms; sym2 != syms_end; ++sym2) {
        if (sym2 == syms && sym2->st_name == 0) continue;
        if (sym2 == sym) continue;
        if (sym2->st_name > strtab_size) continue;
        st_bind = ELF32_ST_BIND(sym2->st_info);
        st_type = ELF32_ST_TYPE(sym2->st_info);
        if (st_type != STT_NOTYPE && st_type != STT_OBJECT && st_type != STT_FUNC) continue;
        if (strcmp(strtab + sym2->st_name, sym_name) != 0) continue;
        if (is_sym2_found) {
          fprintf(stderr, "fatal: multiple partners found for weak symbol: %s: %s\n", sym_name, filename);
          return 32;
        }
        is_sym2_found = 1;
        if (st_bind != STB_GLOBAL || sym2->st_shndx != SHN_UNDEF || sym2->st_value != 0) {
          fprintf(stderr, "fatal: partner for weak symbol must be extern: %s: %s\n", sym_name, filename);
          return 33;
        }
        sym2->st_info = ELF32_ST_INFO(STB_WEAK, st_type);
        sym2->st_shndx = sym->st_shndx;
        sym2->st_value = sym->st_value;
      }
      if (!is_sym2_found) {
        fprintf(stderr, "fatal: no extern partner found for weak symbol: %s: %s\n", sym_name, filename);
        return 34;
      }
      goto remove_sym;
    }
    continue;
   remove_sym:
#if 0  /* Moving a symbol like this doesn't work, because it breaks relocations referring to the symbol by index. */
    syms_size_has_changed = syms_has_changed = 1;
    if (sym != syms_end - 1) memcpy(sym, syms_end - 1, sizeof(sym[0]));
    --syms_end;
    --sym;  /* For continuing the loop. */
#else
    syms_has_changed = 1;
    memset(sym, '\0', sizeof(*sym));
    /* Magic values so that TinyCC ignores the symbol. */
    sym->st_shndx = SHN_ABS;
    sym->st_info = ELF32_ST_INFO(STB_LOCAL, STT_SECTION);
#endif
  }
  if (syms_has_changed) {
    off = shdr_symtab->sh_offset;
    if (lseek(fd, off, SEEK_SET) != off) {  /* This succeeds even if the file is shorter. */
      fprintf(stderr, "fatal: error seeking to .symtab: %s\n", filename);
      return 35;
    }
    want = shdr_symtab->sh_size;
    if ((size_t)write(fd, syms, want) != (size_t)want) {
      fprintf(stderr, "fatal: error writing .symtab: %s\n", filename);
      return 36;
    }
  }
#if 0
  if (syms_size_has_changed) {
    shdr_symtab->sh_size = (char*)syms_end - (char*)syms;
    off = ehdr.e_shoff + (char*)shdr_symtab - (char*)shdrs;
    if (lseek(fd, off, SEEK_SET) != off) {  /* This succeeds even if the file is shorter. */
      fprintf(stderr, "fatal: error seeking to ELF shdr .symtab: %s\n", filename);
      return 37;
    }
    want = sizeof(*shdr_symtab);
    if ((size_t)write(fd, shdr_symtab, want) != (size_t)want) {
      fprintf(stderr, "fatal: error writing ELF .shdr .symtab: %s\n", filename);
      return 38;
    }
  }
#endif

  /*free(syms);*/  /* No need, we exit anyway. */
  /*free(shdrs);*/  /* No need, we exit anyway. */
  /*free(strtab);*/  /* No need, we exit anyway. */
  /*close(fd);*/  /* No need, we exit anyway. */
  return 0;
}
