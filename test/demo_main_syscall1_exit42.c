#define CONFIG_MACRO_SYSCALL 1  /* Use syscall1(...). */
#include <sys/syscall.h>
#include <unistd.h>

int main(int argc, char **argv) {
  (void)argc; (void)argv;
  syscall(__NR_exit, 42);
  return 0;
}
