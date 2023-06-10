/* by pts@fazekas.hu at Fri Jun  9 13:11:03 CEST 2023
 *
 * Compile: ./minicc --gcc=4.8 -o shbin/cc tools/shbin_cc.c
 *
 * This program is roughly equivalent to this shell script (with #!/bin/sh):
 *
 *     exec "${0%/""*}"/sh "%0".sh "$@"
 */

#include <limits.h>  /* For PATH_MAX. */
#include <string.h>
#include <stdlib.h>
#include <sys/stat.h>
#include <unistd.h>

const char *get_path(char *const envp[]) {
  for (; envp[0]; ++envp) {
    if (memcmp(envp[0], "PATH=", 5) == 0) return envp[0] + 5;
  }
  return NULL;
}

/* Based on https://stackoverflow.com/a/890903/97248.
 * Saves the full output pathname to the passed argument pathname. Returns 0
 * iff found.
 */
int find_cmd_on_path(const char *cmd, const char *path, char pathname[PATH_MAX]) {
  const size_t sizeof_pathname = PATH_MAX;
  const size_t size = strlen(cmd) + 1;
  const char *p;
  size_t u;
  struct stat64 st;
  unsigned char has_uids;
  unsigned short mode;
  uid_t uid;
  gid_t gid;
  if (size > sizeof_pathname) return -103;
  for (p = cmd; *p != '\0' && *p != '/'; ++p) {}
  if (*p == '/') {  /* The program name contains a slash => use it without $PATH lookup. */
    memcpy(pathname, cmd, size);
    return 0;
  }
  if (!path) path = "/bin:/usr/bin";  /* Same as in glibc. */
  has_uids = 0;
  uid = gid = 0;  /* Pacify GCC 4.8 warning about possible uninitialized use. */
  for (p = path;;) {
    for (; *p == ':'; ++p) {}
    if (*p == '\0') break;
    for (u = 0; p[u] != '\0' && p[u] != ':'; ++u) {}
    if (u + 1 + size > sizeof_pathname) return -102;
    memcpy(pathname, p, u);
    p += u;
    pathname[u] = '/';
    memcpy(pathname + u + 1, cmd,  size);  /* Including the trailing NUL. */
    /* This logic below matches the dash(1) shell. */
    if (stat64(pathname, &st) != 0) continue;  /* File not found. */
    if (!S_ISREG(st.st_mode)) continue;  /* Not a regular file. */
    mode = (st.st_mode & 0111);
    if (mode == 0) continue;  /* Shortcut: if none of the 3 bits are executable. */
    if (mode == 0111) return 0;  /* Shortcut: if all 3 bits are executable, then we've found it. */
    if (!has_uids) {
      uid = geteuid();
      gid = getegid();
      has_uids = 1;
    }
    /* Don't make root (UID == 0) execute just anything. */
    /* These checks are incorrect if the group list of the process is not empty. */
    if (st.st_uid == uid) {
      if (mode & 0100) return 0;
    } else if (st.st_gid == gid) {
      if (mode & 010) return 0;
    } else {
      if (mode & 1) return 0;
    }
  }
  return -104;
}


/* Resolves symlinks in `pathname' as many times as needed.
 * Updates `pathname'. Returns 0 iff OK.
 */
int resolve_symlinks(char pathname[PATH_MAX]) {
  const size_t sizeof_pathname = PATH_MAX;
  static char tmp_pathname[PATH_MAX];
  unsigned iter_remaining = 0x100;  /* Avoid infinite loop in resolving symlinks. */
  size_t got, u;
  while ((ssize_t)(got = readlink(pathname, tmp_pathname, sizeof(tmp_pathname))) > 0) {
    if (iter_remaining-- == 0) return -109;  /* Too many levels of symlinks. */
    if (got >= sizeof(tmp_pathname)) return -107;  /* Symlink value too long. */
    if (tmp_pathname[0] == '/') {
      u = 0;
    } else {
      for (u = strlen(pathname); u > 0 && pathname[u - 1] != '/'; --u) {}
    }
    if (u + got >= sizeof_pathname) return -108;
    memcpy(pathname + u, tmp_pathname, got);
    pathname[u + got] = '\0';
  }
  return 0;
}

int work(char **argv, char *const envp[]) {
  static char pathname[PATH_MAX], pathname2[PATH_MAX];
  static const char sh[] = "sh";
  static const char miniccsh[] = "minicc.sh";
  char *p, *q;
  size_t u;
  int got;
  if ((got = find_cmd_on_path(argv[0], get_path(envp), pathname)) != 0) return got;
  if ((got = resolve_symlinks(pathname)) != 0) return got;
  for (p = pathname, q = NULL; *p != '\0'; ++p) {
    if (*p == '/') q = p + 1;
  }
  if (!q) return -105;  /* (assert) No '/' in pathname. */
  for (; *p != '\0'; ++p) {}
  u = q - pathname;
  if (u + sizeof(miniccsh) > sizeof(pathname2)) return -105;
  memcpy(pathname2, pathname, u);
  memcpy(pathname2 + u, miniccsh, sizeof(miniccsh));
  u = q - pathname;
  if (u + sizeof(sh) > sizeof(pathname)) return -106;
  memcpy(pathname + u, sh, sizeof(sh));
  if ((got = resolve_symlinks(pathname2)) != 0) return got;
#if !(defined(__i386__) && defined(__linux__))
#  error The argv[-2] trick is guaranteed to work on Linux i386 only.
#endif
  argv[-3] = pathname;  /* .../.sh */  /* Overwrites the argc argument of main. Hence the separate function (work). */
  argv[-2] = pathname2;  /* .../minicc.sh". */  /* Overwrites the argv pointer argument of main. Hence the separate function (work). */
  argv[-1] = "--sh-script";  /* Overwrites the envp pointer argument of main. Hence the separate function (work). */
  argv[0]  = "cc";   /* TODO(pts): Also make it support --noenv and --boxed. */
  /*argv[1] = ...*/ /* $1 of the shell script, kept intact. */
  (void)!execve(pathname, argv - 3, envp);
  return -101;
}

int main(int argc, char **argv, char *const envp[]) {
  (void)argc;
  /* We need the `-' sign (or any other code after the call so that the C
   * compiler doesn't optimize away the stack from of main, which we need
   * for the argv[-3] trick above.
   */
  return -work(argv, envp);
}
