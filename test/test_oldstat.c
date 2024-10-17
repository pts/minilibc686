#include <sys/stat.h>

int main(int argc, char **argv) {
  struct __old_kernel_stat st;
  (void)argc;
  return sys_oldstat(argv[1], &st);  /* Works only with __MINILIBC686__, not other libcs. */
}