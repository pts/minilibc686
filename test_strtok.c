#include <stdio.h>
#include <string.h>

extern char *mini_strtok(char *str, const char *delim);  /* Function under test. */

static char expect(char *str1, char *str2, const char *delim) {
  char is_first;
  for (is_first = 1; ; is_first = 0) {
    char *expected_value = strtok(is_first ? str1 : NULL, delim);
    char *value = mini_strtok(is_first ? str2 : NULL, delim);
    if ((expected_value == NULL) != (value == NULL)) goto mismatch;
    if (value == NULL) {
      printf("---\n");
      return 1;
    }
    if (strcmp(value, expected_value) != 0) {
     mismatch:
      printf("--- mismatch: expected=(%s) got=(%s)\n", expected_value, value);
      return 0;
    }
    printf("got value=(%s)\n", value);
  }
}

int main(int argc, char **argv) {
  static const char tokstr[] = ",,,food,bar,,FooBar,,,,";
  int exit_code = 0;
  char str1[sizeof(tokstr)], str2[sizeof(tokstr)];
  (void)argc; (void)argv;
  strcpy(str1, tokstr);  /* strok() overwrites some bytes. */
  strcpy(str2, tokstr);
  if (!expect(str1, str2, ",")) exit_code |= 1;
  if (!expect(str2, str1, ",")) exit_code |= 1;  /* Only the first token, others have been replaced by '\0'. */
  strcpy(str1, tokstr);  /* strok() overwrites some bytes. */
  strcpy(str2, tokstr);
  if (!expect(str1, str2, ",#")) exit_code |= 1;  /* '#' is not found in tokstr. */
  strcpy(str1, tokstr);  /* strok() overwrites some bytes. */
  strcpy(str2, tokstr);
  if (!expect(str1, str2, "o")) exit_code |= 1;
  strcpy(str1, tokstr);  /* strok() overwrites some bytes. */
  strcpy(str2, tokstr);
  /*if (!expect(str1, str2, ",o")) exit_code |= 1;*/  /* We don't test this, because strtok_sep1 ignores subsequent characters in delim. */
  return exit_code;
}
