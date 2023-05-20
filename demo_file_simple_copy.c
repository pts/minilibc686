/*
 * demo_file_simply_copy.c: a demo program which copies file argv[1] to argv[2] using stdio functions.
 * by pts@fazekas.hu at Sat May 20 12:06:27 CEST 2023
 */

#include "stdio_file_simple.h"  /* This is the public API. */

#define NULL ((void*)0)

int main(int argc, char **argv) {
  FILE *fin, *fout;
  char buf[123];  /* Make it a small odd number for testing interactions of various buffer sizes. */
  int got, got2;
  char mode;
  off_t ofs, ofs_delta;
  (void)argc;
  /* We need exactly 2 arguments: argv[1] and argv[2]. */
  if (!argv[0] || !argv[1] || !argv[2]) return 1;
  if (argv[3] && (argv[3][0] == 'r' || argv[3][0] == 'c' || argv[3][0] == 'a' || argv[3][0] == 's') && argv[3][1] == '\0') {
    mode = argv[3][0];
  } else if (!argv[3]) {
    mode = 'r';  /* Default. */
  } else {
    return 2;
  }
  if ((fin = mini_fopen(argv[1], "rb")) == NULL) return 2;
  if ((fout = mini_fopen(argv[2], "wb")) == NULL) return 3;
  if (mode == 'c') {  /* Just to check that it works. */
    mini_fflush(fin);
    mini_fflush(fout);
  }
  ofs = got = 0;
  goto check_ofs;
  for (;;) {
    if (mode != 'c') {
      if ((got = mini_fread(buf, 1, sizeof(buf), fin)) == 0) break;
    } else {  /* mode == 'c'. */
      got = mini_fgetc(fin);
      if (got == EOF) break;
      buf[0] = got;
      got = 1;
    }
    if ((ssize_t)got < 0) return 4;  /* mini_fread(...) never neturns negative, such as EOF. */
    if ((got2 = mini_fwrite(buf, 1, got, fout)) == 0) return 5;
    if ((ssize_t)got < 0) return 6;  /* mini_fread(...) never neturns negative, such as EOF. */
    if (got2 != got) return 7;  /* mini_fwrite(...) must go as far as possible. */
    ofs += got;
   check_ofs:
    if (mini_ftell(fin) != ofs) return 8;
    if (mini_ftell(fout) != ofs) return 9;
    ofs_delta = (ofs % 13) + (ofs % 17);
    if (mode == 's' && ofs_delta < got) {
      if (mini_fseek(fin, -ofs_delta, SEEK_CUR) != 0) return 12;
      if (mini_fseek(fout, -ofs_delta, SEEK_CUR) != 0) return 13;
      ofs -= ofs_delta;
      if (mini_ftell(fin) != ofs) return 14;
      if (mini_ftell(fout) != ofs) return 15;
    }
  }
  if (mini_ftell(fin) != ofs) return 10;
  if (mini_ftell(fin) != ofs) return 11;
  if (mode != 'a') {  /* Let autoflush at exit(3) time take care of writing unflushed data to fout. */
    if (mini_fclose(fout)) return 4;
    if (mini_fclose(fin)) return 4;
  }
  return 0;
}
