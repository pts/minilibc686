/*
 * demo_file_simply_copy.c: a demo program which copies file argv[1] to argv[2] using stdio functions.
 * by pts@fazekas.hu at Sat May 20 12:06:27 CEST 2023
 */

#include "stdio_file_simple.h"  /* This is the public API. */

#define NULL ((void*)0)

int main(int argc, char **argv) {
  FILE *fin, *fout;
  char buf[0x100];
  int got, got2;
  off_t ofs;
  (void)argc;
  /* We need exactly 2 arguments: argv[1] and argv[2]. */
  if (!argv[0] || !argv[1] || !argv[2] || argv[3]) return 1;
  if ((fin = mini_fopen(argv[1], "rb")) == NULL) return 2;
  if ((fout = mini_fopen(argv[2], "wb")) == NULL) return 3;
  ofs = 0;
  goto check_ofs;
  while ((got = mini_fread(buf, 1, sizeof(buf), fin)) != 0) {
    if ((ssize_t)got < 0) return 4;  /* mini_fread(...) never neturns negative, such as EOF. */
    if ((got2 = mini_fwrite(buf, 1, got, fout)) == 0) return 5;
    if ((ssize_t)got < 0) return 6;  /* mini_fread(...) never neturns negative, such as EOF. */
    if (got2 != got) return 7;  /* mini_fwrite(...) must go as far as possible. */
    ofs += got;
   check_ofs:
    if (mini_ftell(fin) != ofs) return 8;
    if (mini_ftell(fin) != ofs) return 9;
  }
  if (mini_ftell(fin) != ofs) return 10;
  if (mini_ftell(fin) != ofs) return 11;
  if (mini_fclose(fout)) return 4;
  if (mini_fclose(fin)) return 4;
  /* !! TODO(pts): Also test mini_fseek(...). */
  /* !! TODO(pts): Also test mini_fgetc(...). */
  /* !! TODO(pts): Also test autoflush on ecit. */
  return 0;
}
