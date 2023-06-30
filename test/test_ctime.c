#include <time.h>
#include <sys/time.h>
#include <stdio.h>
#include <string.h>

extern char *mini_ctime(const time_t *timep);  /* Function under test. */
extern char *mini_ctime_r(const time_t *timep, char *buf);  /* Function under test. */

static char expect(time_t ts) {
  char buf1[26], buf2[26];
  const char *expected = ctime_r(&ts, buf1);
  const char *value = mini_ctime(&ts);
  const char *value2 = mini_ctime_r(&ts, buf2);
  char is_ok = (expected == buf1 && value2 == buf2 && strcmp(expected, value) == 0 && strcmp(expected, value2) == 0 && value[24] == '\n');
  ((char*)value)[24] = buf1[24] = buf2[24] = '@';  /* Change '\n' for easier printing. */
  printf("is_ok=%d ts=(%d) expected=(%s) value=(%s) value2=(%s)\n", is_ok, (int)ts, expected, value, value2);
  return is_ok;
}

int main(int argc, char **argv) {
  time_t ts;
  int exit_code = 0;
  (void)argc; (void)argv;
  if (!expect(0)) exit_code |= 1;
  if (!expect(15398 * 86400)) exit_code |= 1;
  if (!expect(15399 * 86400)) exit_code |= 1;
  if (!expect(15400 * 86400)) exit_code |= 1;
  if (!expect(946684800 - 86400)) exit_code |= 1;
  if (!expect(946684800)) exit_code |= 1;
  if (!expect(951696000)) exit_code |= 1;
  if (!expect(951696000 + 86400)) exit_code |= 1;
  if (!expect(-0x80000000)) exit_code |= 1;
  if (!expect(-0x70000000)) exit_code |= 1;
  if (!expect(-0x60000000)) exit_code |= 1;
  if (!expect(-0x50000000)) exit_code |= 1;
  if (!expect(-0x40000000)) exit_code |= 1;
  if (!expect(-0x30000000)) exit_code |= 1;
  if (!expect(-0x20000000)) exit_code |= 1;
  if (!expect(-0x10000000)) exit_code |= 1;
  if (!expect(0x10000000)) exit_code |= 1;
  if (!expect(0x10000000)) exit_code |= 1;
  if (!expect(0x7fffffff)) exit_code |= 1;
  if (!expect(-10000 * 86400)) exit_code |= 1;
  if (!expect(9999 * 86400)) exit_code |= 1;
  return exit_code;
}
