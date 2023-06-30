#include <time.h>
#include <sys/time.h>
#include <stdio.h>
#include <string.h>

extern char *mini_asctime(const struct tm *tm);  /* Function under test. */
extern char *mini_asctime_r(const struct tm *tm, char *buf);  /* Function under test. */

static char expect(const struct tm *tm) {
  char buf1[26], buf2[26];
  const char *expected = asctime_r(tm, buf1);
  const char *value = mini_asctime(tm);
  const char *value2 = mini_asctime_r(tm, buf2);
  char is_ok = (expected == buf1 && value2 == buf2 && strcmp(expected, value) == 0 && strcmp(expected, value2) == 0 && value[24] == '\n');
  ((char*)value)[24] = buf1[24] = buf2[24] = '@';  /* Change '\n' for easier printing. */
  printf("is_ok=%d year=(%d) expected=(%s) value=(%s) value2=(%s)\n", is_ok, tm->tm_year, expected, value, value2);
  return is_ok;
}

int main(int argc, char **argv) {
  static struct tm tm;
  int exit_code = 0;
  (void)argc; (void)argv;
  tm.tm_year = 123;
  tm.tm_mon = 5;
  tm.tm_mday = 42;
  tm.tm_hour = 9;
  tm.tm_min = 8;
  tm.tm_sec = 67;
  tm.tm_wday = 6;
  if (!expect(&tm)) exit_code = 1;
  tm.tm_year = 2023 - 1900;
  tm.tm_mon = 6 - 1;
  tm.tm_mday = 30;
  tm.tm_hour = 1;
  tm.tm_min = 26;
  tm.tm_sec = 23;
  tm.tm_wday = 5;
  if (!expect(&tm)) exit_code = 1;
  return exit_code;
}
