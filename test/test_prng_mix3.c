#include <stdint.h>
#include <stdio.h>
#include <string.h>

extern mini_prng_mix3_RP3(uint32_t key) __attribute__((__regparm__(3)));  /* Function under test. */

/* mix3 is a period 2**32-1 PNRG ([13,17,5]), to fill the seeds.
 *
 * https://stackoverflow.com/a/54708697 , https://stackoverflow.com/a/70960914
 */
static uint32_t good_prng_mix3(uint32_t key) {
  if (!key) ++key;
  key ^= (key << 13);
  key ^= (key >> 17);
  key ^= (key << 5);
  return key;
}

static char expect(uint32_t key) {
  const uint32_t expected_value = good_prng_mix3(key);
  const uint32_t value = mini_prng_mix3_RP3(key);
  char is_ok = (value == expected_value);
  printf("is_ok=%d key=%lu expected_value=%lu value=%lu\n", is_ok, (unsigned long)key, (unsigned long)expected_value, (unsigned long)value);
  return is_ok;
}

int main(int argc, char **argv) {
  int exit_code = 0;
  (void)argc; (void)argv;
  if (!expect(0)) exit_code |= 1;
  if (!expect(1)) exit_code |= 1;
  if (!expect(-1U)) exit_code |= 1;
  if (!expect(1234567890U)) exit_code |= 1;
  if (!expect(3210987654U)) exit_code |= 1;
  return exit_code;
}
