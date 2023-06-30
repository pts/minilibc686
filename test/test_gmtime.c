#include <time.h>
#include <stdio.h>
#include <sys/time.h>
#include <string.h>

struct tm *gmtime(const time_t *timep);
extern struct tm *mini_gmtime_r(const time_t *timep, struct tm *tm);  /* Function under test. */
extern struct tm *mini_gmtime(const time_t *timep);

static char expect(time_t ts, char is_verbose) {
  const struct tm expected = *gmtime(&ts);
  const struct tm actual = *mini_gmtime(&ts);
  const char is_ok = (expected.tm_sec == actual.tm_sec && expected.tm_min == actual.tm_min && expected.tm_hour == actual.tm_hour &&
      expected.tm_mday == actual.tm_mday && expected.tm_mon == actual.tm_mon && expected.tm_year == actual.tm_year &&
      expected.tm_wday == actual.tm_wday && expected.tm_yday == actual.tm_yday && expected.tm_isdst == actual.tm_isdst);
  if (is_verbose || !is_ok) printf("is_ok=%d ts=(%d)\n", is_ok, (int)ts);
  if (!is_ok) {
    printf("  < %d:%d:%d %d-%d-%d %d+%d+%d\n", expected.tm_sec, expected.tm_min, expected.tm_hour, expected.tm_mday, expected.tm_mon, expected.tm_year, expected.tm_wday, expected.tm_yday, expected.tm_isdst);
    printf("  > %d:%d:%d %d-%d-%d %d+%d+%d\n", actual.tm_sec, actual.tm_min, actual.tm_hour, actual.tm_mday, actual.tm_mon, actual.tm_year, actual.tm_wday, actual.tm_yday, actual.tm_isdst);
  }
  return is_ok;
}

int main(int argc, char **argv) {
  time_t ts;
  int exit_code = 0;
  (void)argc; (void)argv;
  if (!expect(0, 1)) exit_code |= 1;
  if (!expect(15398 * 86400, 1)) exit_code |= 1;
  if (!expect(15399 * 86400, 1)) exit_code |= 1;
  if (!expect(15400 * 86400, 1)) exit_code |= 1;
  if (!expect(946684800 - 86400, 1)) exit_code |= 1;
  if (!expect(946684800, 1)) exit_code |= 1;
  if (!expect(951696000, 1)) exit_code |= 1;
  if (!expect(951696000 + 86400, 1)) exit_code |= 1;
  if (!expect(-0x80000000, 1)) exit_code |= 1;
  if (!expect(-0x70000000, 1)) exit_code |= 1;
  if (!expect(-0x60000000, 1)) exit_code |= 1;
  if (!expect(-0x50000000, 1)) exit_code |= 1;
  if (!expect(-0x40000000, 1)) exit_code |= 1;
  if (!expect(-0x30000000, 1)) exit_code |= 1;
  if (!expect(-0x20000000, 1)) exit_code |= 1;
  if (!expect(-0x10000000, 1)) exit_code |= 1;
  if (!expect(0x10000000, 1)) exit_code |= 1;
  if (!expect(0x20000000, 1)) exit_code |= 1;
  if (!expect(0x7fffffff, 1)) exit_code |= 1;
  for (ts = -10000 * 86400; ts < 10000 * 86400; ts += 86400) {
    if (!expect(ts, 0)) exit_code |= 2;
  }
  return exit_code;
}
