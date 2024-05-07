#include <errno.h>
#include <stdio.h>
#include <string.h>

extern char *mini_strerror(int errnum);  /* Function under test. */

static char expect(int errnum, const char *expected) {
  const char *errmsg = mini_strerror(errnum);
  char is_ok = (strcmp(errmsg, expected) == 0);
  printf("is_ok=%d errnum=%d expected=(%s) errmsg=(%s)\n", is_ok, errnum, expected, errmsg);
  return is_ok;
}

int main(int argc, char **argv) {
  int exit_code = 0;
  (void)argc; (void)argv;
  if (!expect(0, "")) exit_code |= 1;
  if (!expect(EPERM, "Operation not permitted")) exit_code |= 1;
  if (!expect(ENOENT, "No such file or directory")) exit_code |= 1;
  if (!expect(EHWPOISON, "Memory page has hardware error")) exit_code |= 1;
  if (!expect(4321, "Unknown error")) exit_code |= 1;
  return exit_code;
}
