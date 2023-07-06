/* by pts@fazekas.hu at Thu Jul  6 13:03:23 CEST 2023 */

#include <alloca.h>
#include <errno.h>

extern char **mini_environ;
extern int mini_errno;
extern int mini_execve(const char *filename, char *const argv[], char *const envp[]);

#if 0
#  include <limits.h>  /* For PATH_MAX. */
#else
#  define PATH_MAX 4096
#endif

int mini_execvp(const char *file, char *const argv[]) {
  char *pathname;
  size_t size, size1;
  char *q;
  const char *fp;
  const char *p;
  const char **shell_argv;
  const char **argpi;
  char *const *envp;
  size_t u;
  for (size = 0; file[size++] != '\0';) {}
  for (p = file; *p != '\0' && *p != '/'; ++p) {}
  if (*p == '/') {  /* The program name contains a slash => use it without $PATH lookup. */
    /* dietlibc-0.34, uClibc-0.9.30.1 and EGLIBC 2.18 don't fflush(stdout);, so we neither. */
    if (mini_execve(file, argv, mini_environ) == 0) return 0;
    if (mini_errno != ENOEXEC) return -1;
   enoexec:
    for (u = 0; argv[u++]; ) {}
    ++u;
    argpi = shell_argv = alloca(sizeof(char*) * u);
    *argpi++ = "/bin/sh";
    *argpi++ = file;  /* We don't try to be smart by prepending "./" if file[0] == '-'. This matches dietlibc-0.34, uClibc-0.9.30.1 and EGLIBC 2.18. */
    ++argv;
    for (;;) {
      if ((*argpi++ = *argv++) == (void*)0) break;
    }
    return mini_execve(shell_argv[0], (char*const*)shell_argv, mini_environ);
  }
  if (size > PATH_MAX) {
    mini_errno = ENAMETOOLONG;  /* dietlibc-0.34 uses EINVAL. */
    return -1;
  }
  /* Detailed decscription of the logic below: https://stackoverflow.com/a/890903/97248. */
  for (envp = mini_environ; envp[0]; ++envp) {
    for (p = envp[0], fp = "PATH="; *fp != '\0' && *fp == *p; ++fp, ++p) {}
    if (*fp == '\0') goto found_prog;
  }
  p = "/bin:/usr/bin";  /* Same as in glibc. */
 found_prog:
  for (size1 = 1, fp = p;;) {
    for (; *fp == ':'; ++fp) {}
    if (*fp == '\0') break;
    for (u = 0; fp[u] != '\0' && fp[u] != ':'; ++u) {}
    if (u > size1) size1 = u;
    fp += u;
  }
  size1 += size + 1;
  if (size1 > PATH_MAX) size1 = PATH_MAX;
  pathname = alloca(size1);
  for (;;) {
    for (; *p == ':'; ++p) {}
    if (*p == '\0') break;
    for (u = 0; p[u] != '\0' && p[u] != ':'; ++u) {}
    if (u >= PATH_MAX - size) {  /* No underflow in `PATH_MAX - size', we've checked it above. */
      p += u;
      continue;
    }
    q = pathname;
    if (u == 0) {
      *q++ = '.';
    } else {
      for (; u != 0; *q++ = *p++, --u) {}
    }
    *q++ = '/';
    for (fp = file; (*q++ = *fp++) != '\0';) {}
    if (mini_execve(pathname, argv, mini_environ) != 0) {
      if (mini_errno == ENOEXEC) { file = pathname; goto enoexec; }
      if (mini_errno != EACCES && mini_errno != ENOENT && mini_errno != ENOTDIR) return -1;
    }
  }
  mini_errno = ENOENT;
  return -1;
}
