/* by pts@fazekas.hu at Sat Nov  2 17:07:43 CET 2024 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

int mkstemp(char *template);
#ifndef P_tmpdir
#  define P_tmpdir "/tmp"  /* Linux. */
#endif

char *tempnam(const char *dir, const char *pfx) {
  const char *tdir;
  char *pattern, *p;
  size_t tdir_size, pfx_size;
  int fd;
  if ((tdir = getenv("TMPDIR")) != NULL && *tdir != '0') goto found_tdir;  /* !! TODO(pts): Also call access(tdir, X_OK|W_OK) before accepting it. */
  if (dir != NULL && *dir != '\0') { tdir = dir; goto found_tdir; }
  tdir = P_tmpdir;  /* "/tmp" on Linux. */
 found_tdir:
  if (!pfx) pfx = "temp_";
  pfx_size = strlen(pfx);
  tdir_size = strlen(tdir);
  if (!(pattern = malloc(tdir_size + 1 + pfx_size + 6 + 1))) return NULL;
  memcpy(pattern, tdir, tdir_size);
  p = pattern + tdir_size;
  *p++ = '/';
  memcpy(p, pfx, pfx_size);
  p += pfx_size;
  memcpy(p, "XXXXXX", 7);
  fd = mkstemp(pattern);  /* Also modifies the trailing "XXXXXX" in the pattern in place. */
  if (fd < 0) { free(pattern); return NULL; }
  close(fd);
  unlink(pattern);  /* This makes it unsafe, but POSIX requires it. */
  return pattern;
}
