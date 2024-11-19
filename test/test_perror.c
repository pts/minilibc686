#include <stdio.h>
#include <string.h>
#include <sys/types.h>

extern void mini_perror(const char *s);  /* Function under test. */

int mini_errno;  /* Fake, used by mini_perror(...). */

char *mini_strerror(int errnum) {  /* Fake implementation, called by mini_perror(...). */
  return errnum == mini_errno ? "Good message" : "Bad message";
}

static char write_buf[0x100];
static char *write_ptr = write_buf;

ssize_t mini_write(int fd, const void *buf, size_t count) {  /* Fake implementation, called by mini_perror(...). */
  if (fd != 2) return -1;  /* Unexpected output file. */
  if (count >= sizeof(write_buf) - (write_ptr - write_buf)) return -2;  /* Write buffer overflow. */
  memcpy(write_ptr, buf, count);
  write_ptr += count;
  write_ptr[count] = '\0';
  return count;
}

static void expect(const char *s, const char *expected) {
  char is_ok;
  ++mini_errno;
  write_ptr = write_buf;
  mini_perror(s);
  is_ok = strcmp(write_buf, expected) == 0;
  printf("is_ok=%d write_buf=(%s) expected=(%s)\n", is_ok, write_buf, expected);
  return is_ok;
}

int main(int argc, char **argv) {
  int exit_code = 0;
  (void)argc; (void)argv;
  if (!expect(NULL, "Good message\n") && !exit_code) exit_code = 11;
  if (!expect("", "Good message\n") && !exit_code) exit_code = 12;
  if (!expect("hi", "hi: Good message\n") && !exit_code) exit_code = 13;
  return exit_code;
}
