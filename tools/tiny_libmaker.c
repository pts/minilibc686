/* This source file contains some modifications
 * by pts@fazekas.hu at Wed May 17 13:02:35 CEST 2023
 *
 * Recommended compile: owcc -blinux -fno-stack-check -fsigned-char -march=i386 -W -Wall -Wextra -Werror -s -Os -o tools/tiny_libmaker tools/tiny_libmaker.c && sstrip tools/tiny_libmaker
 */

/*
 * This program is for making libtcc1.a without ar
 * tiny_libmaker - tiny elf lib maker
 * usage: tiny_libmaker [lib] files...
 * Copyright (c) 2007 Timppa
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this library; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110-1301, USA.
 */

#if (!defined(DO_INLINE_STDLIB) || DO_INLINE_STDLIB) && defined(__WATCOMC__) && defined(__LINUX__) && defined(_M_I386)
#undef  DO_INLINE_STDLIB
#define DO_INLINE_STDLIB 1  /* Make it work without #include()s. */
struct __iobuf {
  unsigned char        *_ptr;
  int                   _cnt;
  struct __stream_link *_link;
  unsigned              _flag;
  int                   _handle;
  unsigned              _bufsize;
  unsigned short        _ungotten;
};
extern struct __iobuf __iob[];
typedef struct _FILE FILE;
/*#define stdout ((FILE*)&__iob[1])*/
/* This works even if "$WATCOM"/h is on the #include path, rather than the
 * correct "$WATCOM"/lh. It works by not #include()ing any .h files.
 */
#define stderr ((FILE*)&__iob[2])  /* sizeof(__iobuf) matters. */
#else
#if (!defined(DO_INLINE_STDLIB) || DO_INLINE_STDLIB) && (defined(__TINYC__) || defined(__GNUC__)) && defined(__i386__) && defined(__linux__) && !defined(__MINILIBC686__)
#undef  DO_INLINE_STDLIB
#define DO_INLINE_STDLIB 1  /* Make it work without #include()s. */
typedef struct _FILE FILE;
extern FILE *stderr;
#else
#undef  DO_INLINE_STDLIB
#endif
#endif

#if DO_INLINE_STDLIB
#define NULL ((void*)0)
/**/
typedef unsigned int size_t;
typedef int ssize_t;
/* <stdint.h> */
#define __int8_t_defined
typedef signed char int8_t;
typedef short int int16_t;
typedef int int32_t;
typedef long long int int64_t;
typedef unsigned char           uint8_t;
typedef unsigned short int      uint16_t;
typedef unsigned int            uint32_t;
typedef unsigned long long int  uint64_t;
/* <string.h> */
void *memcpy(void *dest, const void *src, size_t n);
int strcmp(const char *s1, const char *s2);
size_t strlen(const char *s);
char *strcpy(char *dest, const char *src);
char *strchr(const char *s, int c);
void *memset(void *s, int c, size_t n);
/**/
#define SEEK_SET 0
#define SEEK_CUR 1
#define SEEK_END 2
/**/
void *malloc(size_t size);
void free(void *ptr);
void *realloc(void *ptr, size_t size);
/* <stdio.h> */
typedef long off_t;
int printf(const char *format, ...);
int sprintf(char *str, const char *format, ...);
int fprintf(FILE *stream, const char *format, ...);
FILE *fopen(const char *pathname, const char *mode);
int fseek(FILE *stream, long off, int whence);
long ftell(FILE *stream);
size_t fread(void *ptr, size_t size, size_t nmemb, FILE *stream);
size_t fwrite(const void *ptr, size_t size, size_t nmemb, FILE *stream);
int fflush(FILE *stream);
int ferror(FILE *stream);
int fclose(FILE *stream);
int remove(const char *pathname);
/**/
#else  /* Use standard .h files (by default). */
#  include <stdio.h>
#  include <stdlib.h>
#  include <string.h>
#  ifndef __int8_t_defined
#  ifndef _WIN32
#    include <inttypes.h>
#  else
    typedef signed char int8_t;
    typedef short int int16_t;
    typedef int int32_t;
    typedef long long int int64_t;
    typedef unsigned char           uint8_t;
    typedef unsigned short int      uint16_t;
    typedef unsigned int            uint32_t;
    typedef unsigned long long int  uint64_t;
   #endif
  #endif
#endif

/* --- <elf.h>, with only the needed features. */

/* This file defines standard ELF types, structures, and macros.
   Copyright (C) 1995-2012 Free Software Foundation, Inc.
   This file is part of the GNU C Library.

   The GNU C Library is free software; you can redistribute it and/or
   modify it under the terms of the GNU Lesser General Public
   License as published by the Free Software Foundation; either
   version 2.1 of the License, or (at your option) any later version.

   The GNU C Library is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
   Lesser General Public License for more details.

   You should have received a copy of the GNU Lesser General Public
   License along with the GNU C Library; if not, see
   <http://www.gnu.org/licenses/>.  */


/* Standard ELF types.  */

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

#define STB_GLOBAL      1               /* Global symbol */
#define STB_WEAK        2               /* Weak symbol */

#define STT_NOTYPE	0		/* Symbol type is unspecified */
#define STT_OBJECT	1		/* Symbol is a data object */
#define STT_FUNC	2		/* Symbol is a code object */

#define ELF32_ST_BIND(val)		(((unsigned char) (val)) >> 4)
#define ELF32_ST_TYPE(val)		((val) & 0xf)

/* --- End of <elf.h> */

#ifdef TCC_TARGET_X86_64
# define ELFCLASSW ELFCLASS64
# define ElfW(type) Elf##64##_##type
# define ELFW(type) ELF##64##_##type
#else
# define ELFCLASSW ELFCLASS32
# define ElfW(type) Elf##32##_##type
# define ELFW(type) ELF##32##_##type
#endif

#define ARMAG  "!<arch>\n"
#define ARFMAG "`\n"

typedef struct ArHdr {
    char ar_name[16];
    char ar_date[12];
    char ar_uid[6];
    char ar_gid[6];
    char ar_mode[8];
    char ar_size[10];
    char ar_fmag[2];
} ArHdr;

unsigned long le2belong(unsigned long ul) {
    return ((ul & 0xFF0000)>>8)+((ul & 0xFF000000)>>24) +
        ((ul & 0xFF)<<24)+((ul & 0xFF00)<<8);
}

ArHdr arhdr = {
    "/               ",
    "0           ",
    "0     ",
    "0     ",
    "0       ",
    "          ",
    ARFMAG
    };

ArHdr arhdro = {
    "                ",
    "0           ",
    "0     ",
    "0     ",
    "0       ",
    "          ",
    ARFMAG
    };

/* Returns 1 if s contains any of the chars of list, else 0 */
int contains_any(const char *s, const char *list) {
  const char *l;
  for (; *s; s++) {
      for (l = list; *l; l++) {
          if (*s == *l)
              return 1;
      }
  }
  return 0;
}

int usage(int ret) {
    fprintf(stderr, "usage: tiny_libmaker [rcsv] lib file...\n");
    fprintf(stderr, "Always creates a new lib. [abdioptxN] are explicitly rejected.\n");
    return ret;
}

int main(int argc, char **argv)
{
    FILE *fi, *fh = NULL, *fo = NULL;
    ElfW(Ehdr) *ehdr;
    ElfW(Shdr) *shdr;
    ElfW(Sym) *sym;
    int i, fsize, i_lib, i_obj, i_obj0;
    char *buf, *shstr, *symtab = NULL, *strtab = NULL;
    int symtabsize = 0;//, strtabsize = 0;
    char *anames = NULL;
    int *afpos = NULL;
    int istrlen, strpos = 0, fpos = 0, funccnt = 0, funcmax, hofs;
    char tfile[260], stmp[61];
    char *file, *name;
    int ret = 2;
    char *ops_conflict = "habdioptxN";  // unsupported but destructive if ignored.
    int verbose = 0;
    int got;
    unsigned fnsize;
    unsigned long_listing_size;  /* Number of bytes in the listing of long filenames. */
    char *p;
    char *long_listing = NULL;
    unsigned long_listing_idx;
    static char copybuf[0x1000];
    Elf32_Word sym_type, sym_bind;

    tfile[0] = '\0';
    i_lib = 0; i_obj = 0;  // will hold the index of the lib and first obj
    for (i = 1; i < argc; i++) {
        const char *a = argv[i];
        if (*a == '-' && strchr(a, '.'))
            return usage(1);  // -x.y is always invalid (same as gnu ar)
        if ((*a == '-') || (i == 1 && !strchr(a, '.'))) {  // options argument
            if (a[0] == '-' && a[1] == 'h' && a[2] == '\0') return usage(0);
            if (contains_any(a, ops_conflict))
                return usage(1);
            if (strchr(a, 'v'))
                verbose = 1;
        } else {  // lib or obj files: don't abort - keep validating all args.
            if (!i_lib)  // first file is the lib
                i_lib = i;
            else if (!i_obj)  // second file is the first obj
                i_obj = i;
        }
    }
    if (!i_obj)  // i_obj implies also i_lib. we require both.
        return usage(1);

    if ((fh = fopen(argv[i_lib], "ab")) == NULL) {
        fprintf(stderr, "Can't open file %s \n", argv[i_lib]);
        goto the_end;
    }
    fclose(fh);
    fh = NULL;

    sprintf(tfile, "%s.tmp", argv[i_lib]);
    if ((fo = fopen(tfile, "wb")) == NULL) {
        fprintf(stderr, "Can't create temporary file %s\n", tfile);
        goto the_end;
    }

    funcmax = 250;
    afpos = realloc(NULL, funcmax * sizeof *afpos); // 250 func
    memcpy(&arhdro.ar_mode, "644   ", 6);
    /* i_obj0 = first input object file. Build a list of long filenames. */
    i_obj0 = i_obj;

    long_listing_size = 0;
    for (i_obj = i_obj0; i_obj < argc; ++i_obj) {
        if (*argv[i_obj] == '-') continue;
        fnsize = strlen(argv[i_obj]);
        if (fnsize >= sizeof(arhdro.ar_name)) {
            long_listing_size += fnsize + 2;  /* +2 for the "/\n". */
        }
    }
    if (long_listing_size > 0) {
        if ((long_listing = malloc(long_listing_size)) == NULL) {
            fprintf(stderr, "Out of memory.\n");
            goto the_end;
        }
        for (i_obj = i_obj0, p = long_listing; i_obj < argc; ++i_obj) {
            if (*argv[i_obj] == '-') continue;
            fnsize = strlen(argv[i_obj]);
            if (fnsize >= sizeof(arhdro.ar_name)) {
                memcpy(p, argv[i_obj], fnsize);
                p += fnsize;
                *p++ = '/';
                *p++ = '\n';
            }
        }
        if (long_listing_size & 1) {  /* Align to even. */
            ++long_listing_size;
            *p++ = '\n';
        }
        if ((unsigned)(p - long_listing) != long_listing_size) {
            fprintf(stderr, "assert: Long listing size mismatch.\n");
            goto the_end;
        }
    }

    // i_obj = first input object file
    for (i_obj = i_obj0, long_listing_idx = 0; i_obj < argc;) {
        if (*argv[i_obj] == '-') {  // by now, all options start with '-'
            i_obj++;
            continue;
        }
        if (verbose)
            printf("a - %s\n", argv[i_obj]);

        if ((fi = fopen(argv[i_obj], "rb")) == NULL)
        {
            fprintf(stderr, "Can't open file %s\n", argv[i_obj]);
            goto the_end;
        }
        if (fseek(fi, 0, SEEK_END) != 0) {
          error_seeking_fi:
            fprintf(stderr, "Error seeking file: %s\n", argv[i_obj]);
            goto the_end;
        }
        fsize = ftell(fi);
        if (fseek(fi, 0, SEEK_SET) != 0) goto error_seeking_fi;
        if ((buf = malloc(fsize)) == NULL) {
            fprintf(stderr, "Out of memory.\n");
            goto the_end;
        }
        if (fread(buf, fsize, 1, fi) != 1) {
            fprintf(stderr, "Error reading file: %s\n", argv[i_obj]);
            goto the_end;
        }
        fclose(fi);

        // elf header
        ehdr = (ElfW(Ehdr) *)buf;
        if (memcmp(ehdr->e_ident, "\x7f""ELF", 4) != 0) {
          /*fprintf(stderr, "fatal: bad ELF signature: %s\n", argv[i_obj]);*/
          goto add_file;
        }
        if (ehdr->e_ident[4] != 1 || (ehdr->e_ident[5] != 1 && ehdr->e_ident[5] != 2) || ehdr->e_ident[6] != 1) {
          fprintf(stderr, "info: bad ELF e_ident, skipping: %s\n", argv[i_obj]);
          goto add_file;
        }
        if (ehdr->e_type != ET_REL) {
          if (ehdr->e_type == ET_REL << 8) {
            fprintf(stderr, "info: bad ELF byte order, skipping: %s\n", argv[i_obj]);
          } else {
            fprintf(stderr, "info: not an ELF relocatable (.o file), skipping: %s\n", argv[i_obj]);
          }
          goto add_file;
        }
        if (ehdr->e_version != 1) {
          fprintf(stderr, "info: bad ELF e_version, skipping: %s\n", argv[i_obj]);
          goto add_file;
        }

        shdr = (ElfW(Shdr) *) (buf + ehdr->e_shoff + ehdr->e_shstrndx * ehdr->e_shentsize);
        shstr = (char *)(buf + shdr->sh_offset);
        for (i = 0; i < ehdr->e_shnum; i++)
        {
            shdr = (ElfW(Shdr) *) (buf + ehdr->e_shoff + i * ehdr->e_shentsize);
            if (!shdr->sh_offset)
                continue;
            if (shdr->sh_type == SHT_SYMTAB)
            {
                symtab = (char *)(buf + shdr->sh_offset);
                symtabsize = shdr->sh_size;
            }
            if (shdr->sh_type == SHT_STRTAB)
            {
                if (!strcmp(shstr + shdr->sh_name, ".strtab"))
                {
                    strtab = (char *)(buf + shdr->sh_offset);
                    //strtabsize = shdr->sh_size;
                }
            }
        }

        if (symtab && symtabsize)
        {
            int nsym = symtabsize / sizeof(ElfW(Sym));
            //printf("symtab: info size shndx name\n");
            for (i = 1; i < nsym; i++)
            {
                sym = (ElfW(Sym) *) (symtab + i * sizeof(ElfW(Sym)));
                if (!sym->st_shndx) continue;
                sym_bind = ELF32_ST_BIND(sym->st_info);
                sym_type = ELF32_ST_TYPE(sym->st_info);
                if ((sym_bind == STB_GLOBAL || sym_bind == STB_WEAK) &&
                    (sym_type == STT_NOTYPE || sym_type == STT_OBJECT || sym_type == STT_FUNC)) {
                    //printf("symtab: %2Xh %4Xh %2Xh %s\n", sym->st_info, sym->st_size, sym->st_shndx, strtab + sym->st_name);
                    istrlen = strlen(strtab + sym->st_name)+1;
                    anames = realloc(anames, strpos+istrlen);
                    strcpy(anames + strpos, strtab + sym->st_name);
                    strpos += istrlen;
                    if (++funccnt >= funcmax) {
                        funcmax <<= 1;
                        afpos = realloc(afpos, funcmax * sizeof *afpos);
                    }
                    afpos[funccnt] = fpos;
                }
            }
        }

      add_file:
        file = argv[i_obj];
        for (name = strchr(file, 0);
             name > file && name[-1] != '/' && name[-1] != '\\';
             --name);
        istrlen = strlen(name);
        memset(arhdro.ar_name, ' ', sizeof(arhdro.ar_name));
        if (istrlen + 0U >= sizeof(arhdro.ar_name)) {
            i = sprintf(arhdro.ar_name, "/%u", long_listing_idx);
            arhdro.ar_name[i] = ' ';
            long_listing_idx += istrlen + 2;
        } else {
            memcpy(arhdro.ar_name, name, istrlen);
            arhdro.ar_name[istrlen] = '/';
        }
        sprintf(stmp, "%-10d", fsize);
        memcpy(&arhdro.ar_size, stmp, 10);
        fwrite(&arhdro, sizeof(arhdro), 1, fo);
        fwrite(buf, fsize, 1, fo);
        free(buf);
        if (fsize & 1) {  /* Align to even. */
            ++fsize;
            fwrite("\n", 1, 1, fo);
        }
        i_obj++;
        fpos += (fsize + sizeof(arhdro));
    }
    fclose(fo);
    hofs = 8 + sizeof(arhdr) + strpos + (funccnt+1) * sizeof(int);
    if (long_listing_size) hofs += 60 + long_listing_size;
    fpos = 0;
    if ((hofs & 1))  /* Align to even. */
        hofs++, fpos = 1;
    // write header
    if ((fh = fopen(argv[i_lib], "wb")) == NULL) {
        fprintf(stderr, "Can't open file %s \n", argv[i_lib]);
        goto the_end;
    }
    fwrite("!<arch>\n", 8, 1, fh);
    if (funccnt > 0) {  /* Size optimization, it would work without it. */
      sprintf(stmp, "%-10d", (int)((strpos + (funccnt+1) * sizeof(int) + 1) & ~1));
      memcpy(&arhdr.ar_size, stmp, 10);
      fwrite(&arhdr, sizeof(arhdr), 1, fh);
      afpos[0] = le2belong(funccnt);
      for (i=1; i<=funccnt; i++)
          afpos[i] = le2belong(afpos[i] + hofs);
      fwrite(afpos, (funccnt+1) * sizeof(int), 1, fh);
      fwrite(anames, strpos, 1, fh);
      if (fpos)
          fwrite("", 1, 1, fh);  /* Align to even. */
    }
    if (long_listing) {
        sprintf(stmp, "//                                              %-10d`\n", long_listing_size);  /* 60 bytes + '\0'. */
        fwrite(stmp, 60, 1, fh);
        fwrite(long_listing, long_listing_size, 1, fh);
        /*if (long_listing_size & 1) ...*/  /* Align to even. Not needed, it's already even. */
        free(long_listing);
        long_listing = NULL;
    }
    // write objects
    if ((fo = fopen(tfile, "rb")) == NULL) {
        fprintf(stderr, "Can't create temporary file %s\n", tfile);
        goto the_end;
    }
    fsize = 0;
    while ((got = fread(copybuf, 1, sizeof(copybuf), fo)) > 0) {
        if (fwrite(copybuf, 1, got, fh) != got + 0U) {
          error_writing:
            fprintf(stderr, "Error writing file: %s\n", argv[i_lib]);
            goto the_end;
        }
        fsize += got;
    }
    if (fseek(fo, 0, SEEK_END)) {
        fprintf(stderr, "Error seeking file: %s\n", tfile);
        goto the_end;
    }
    if (ftell(fo) != fsize) {
        fprintf(stderr, "Error reading file: %s\n", tfile);
        goto the_end;
    }
    if (fflush(fh)) goto error_writing;
    ret = 0;
the_end:
    free(long_listing);
    free(anames);
    free(afpos);
    if (fh)
        fclose(fh);
    if (fo) {
        fclose(fo);
        if (tfile[0] != '\0') remove(tfile);
    }
    return ret;
}
