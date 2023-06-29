/* manually optimized, based on dietlibc-0.34/lib/getopt.c */

#define NULL ((void*)0)

typedef unsigned size_t;
typedef int ssize_t;

extern ssize_t mini_write(int fd, const void *buf, size_t count);

int optind=1;
int opterr=1;
int optopt;
char *optarg;

static __inline char *my_strchr(const char *s, char c) {
  for (;; ++s) {
    if (*s == c) return (char*)s;
    if (*s == '\0') return NULL;
  }
}

int getopt(int argc, char * const argv[], const char *optstring) {
  static char error1[]="Unknown option `-x'.\n";
  static char error2[]="Missing argument for `-x'.\n";
  static int lastidx,lastofs;
  char *tmp, *error, c;
  if (optind==0) { optind=1; lastidx=0; }  /* whoever started setting optind to 0 should be shot */
again:
  if (optind>argc || !argv[optind] || *argv[optind]!='-' || argv[optind][1]==0)
    return -1;
  if (argv[optind][1]=='-' && argv[optind][2]==0) {
    ++optind;
    return -1;
  }
  if (lastidx!=optind) {
    lastidx=optind; lastofs=0;
  }
  optopt=argv[optind][lastofs+1];
  if ((tmp=my_strchr(optstring,optopt))) {
    if (*tmp==0) {  /* apparently, we looked for \0, i.e. end of argument */
      ++optind;
      goto again;
    }
    if (tmp[1]==':') {  /* argument expected */
      if (tmp[2]==':' || argv[optind][lastofs+2]) {  /* "-foo", return "oo" as optarg */
        if (!*(optarg=argv[optind]+lastofs+2)) optarg=0;
        goto found;
      }
      optarg=argv[optind+1];
      if (!optarg) {  /* missing argument */
        ++optind;
        c = ':';
        if (*optstring==':') { error = error2; goto report_error; }
        goto return_c;
      }
      ++optind;
    } else {
      ++lastofs;
      return optopt;
    }
   found:
    ++optind;
    return optopt;
  } else {  /* not found */
    ++optind;
    c = '?';
    error = error1;
   report_error:
    if (opterr) {
      for (tmp = error; *tmp != '\0'; ++tmp) {}
      tmp[-4] = optopt;
      (void)!mini_write(2, error, tmp - error);
    }
   return_c:
    return c;
  }
}
