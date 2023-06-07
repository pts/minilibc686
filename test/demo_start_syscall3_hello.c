#define CONFIG_MACRO_SYSCALL 1  /* Use syscall3(...). */
#include <sys/syscall.h>
#include <unistd.h>

void _start(void) {
  static const char msg[] = "Hello, World!\n";
  syscall(__NR_write, 1, msg, sizeof(msg) - 1);
  syscall(__NR_exit, 0);
}
