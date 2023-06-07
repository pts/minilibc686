#include <sys/syscall.h>
#include <unistd.h>

int main(int argc, char **argv) {
  (void)argc; (void)argv;
  /* This is a full, 6-argument syscall call, because CONFIG_MACRO_SYSCALL is not defined by default. */
  syscall(__NR_exit, 42);
  return 0;
}
