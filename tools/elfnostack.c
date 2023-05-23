/*
 * elfnostack.c: disables the .note.GNU-stack section in an ELF .o file
 * by pts@fazekas.hu at Wed May 24 00:01:12 CEST 2023
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

#define ET_REL		1		/* Relocatable file */

/* --- */

int main(int argc, char **argv) {
  char new_char[1] = {','};
  const char *p, *q;
  int fd;
  const char *filename;
  Elf32_Ehdr ehdr;
  Elf32_Shdr shdr;
  off_t off;
  static char shstrtab[0x1000];
  (void)argc; (void)argv;
  if (!argv[0] || !argv[1] || argv[2]) {
    fprintf(stderr, "Usage: %s <elfobj.o>\n", argv[0]);
    return 1;
  }
  filename = argv[1];
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
  if (ehdr.e_shentsize != 0x28) {
    fprintf(stderr, "fatal: unexpected ELF e_shnum: %s\n", filename);
    return 10;
  }
  if (ehdr.e_shnum == 0) {
    fprintf(stderr, "fatal: no ELF sections: %s\n", filename);
    return 11;
  }
  if (ehdr.e_shstrndx >= ehdr.e_shnum) {
    fprintf(stderr, "fatal: bad ELF e_shstrndx: %s\n", filename);
    return 12;
  }
  off = ehdr.e_shoff + ehdr.e_shstrndx * 0x28;
  if (lseek(fd, off, SEEK_SET) != off) {  /* This succeeds even if the file is shorter. */
    fprintf(stderr, "fatal: error seeking to ELF .shstrtab shdr: %s\n", filename);
    return 13;
  }
  if (read(fd, &shdr, sizeof(shdr)) != sizeof(shdr)) {
    fprintf(stderr, "fatal: error reading ELF .shstrtab shdr: %s\n", filename);
    return 14;
  }
  if (shdr.sh_offset < 0x34) {
    fprintf(stderr, "fatal: bad ELF .shstrtab sh_offset: %s\n", filename);
    return 15;
  }
  if (shdr.sh_size == 0) {
    fprintf(stderr, "fatal: zero ELF .shstrtab sh_size: %s\n", filename);
    return 16;
  }
  if (shdr.sh_size >= sizeof(shstrtab)) {
    fprintf(stderr, "fatal: ELF .shstrtab data too large: %s\n", filename);
    return 17;
  }
  off = shdr.sh_offset;
  if (lseek(fd, off, SEEK_SET) != off) {  /* This succeeds even if the file is shorter. */
    fprintf(stderr, "fatal: error seeking to ELF .shstrtab data: %s\n", filename);
    return 18;
  }
  if ((size_t)read(fd, shstrtab, shdr.sh_size) != (size_t)shdr.sh_size) {
    fprintf(stderr, "fatal: error reading ELF .shstrtab data: %s\n", filename);
    return 19;
  }
  q = shstrtab + shdr.sh_size;
  shstrtab[shdr.sh_size] = '\0';  /* Sentinel. */
  for (p = shstrtab; p < q && strcmp(p, ".note.GNU-stack") != 0; p += strlen(p) + 1) {}
  if (p < q) {  /* Found. */
    off += p - shstrtab;
    if (lseek(fd, off, SEEK_SET) != off) {  /* This succeeds even if the file is shorter. */
      fprintf(stderr, "fatal: error seeking to section name in ELF .shstrtab data: %s\n", filename);
      return 20;
    }
    if (write(fd, new_char, 1) != 1) {  /* Change the leading '.' to a '#'. */
      fprintf(stderr, "fatal: error changing section name in ELF .shstrtab data: %s\n", filename);
      return 21;
    }
  }
  /*close(fd);*/  /* No need, we exit anyway. */
  return 0;
}
