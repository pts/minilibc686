#include "stdio_medium.h"

extern void mini___M_start_flush_opened(void);
__extension__ void *mini___M_start_flush_opened_ptr = (void*)mini___M_start_flush_opened;  /* Force `extern' declaration, for mini_fopen(...). In .nasm source we won't need this hack. !! TODO(pts): Don't use 4 bytes of data here. */

extern FILE mini___M_global_files[], mini___M_global_files_end[];
extern char mini___M_global_file_bufs[];

FILE *mini_fopen(const char *pathname, const char *mode) {
  FILE *filep;
  char *buf = mini___M_global_file_bufs;
  int fd;
  const char is_write = (mode[0] == 'w' || mode[0] == 'a');
  mode_t fmode = is_write ? O_WRONLY | O_TRUNC | O_CREAT : O_RDONLY;
  if (mode[0] == 'a') fmode |= O_APPEND;
  for (filep = mini___M_global_files; filep != mini___M_global_files_end; ++filep, buf += BUF_SIZE) {
    if (filep->dire == FD_CLOSED) {
      fd = mini_open(pathname, fmode, 0666);
      if (fd < 0) return NULL;  /* open(2) has failed. */
      filep->dire = is_write ? FD_WRITE : FD_READ;
      filep->fd = fd;
      filep->buf_off = 0;
      filep->buf_start = buf;
      filep->buf_capacity_end = filep->buf_end = buf + BUF_SIZE;
      /* filep->buf_read_ptr = filep->buf_write_ptr = filep->buf_last = filep->buf_start;
       * if (IS_FD_ANY_READ(filep->dire)) filep->buf_write_ptr = filep->buf_end;  / * Sentinel. * /
       */
      mini___M_discard_buf(filep);
      return filep;
    }
  }
  return NULL;  /* No free slots in global_files. */
}
