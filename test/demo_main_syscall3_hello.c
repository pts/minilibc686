#define CONFIG_MACRO_SYSCALL 1  /* Use syscall3(...). */
#include <sys/syscall.h>
#include <unistd.h>

int main(int argc, char **argv) {
  static const char msg[] = "Hello, World!\n";
  (void)argc; (void)argv;
  syscall(__NR_write, 1, msg, sizeof(msg) - 1);
  return 0;
}
