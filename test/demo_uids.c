#include <stdio.h>
#include <unistd.h>

int main(int argc, char **argv) {
  (void)argc; (void)argv;
  printf("UID=%d GID=%d EUID=%d EGID=%d PID=%d PPID=%d\n",
         getuid(), getgid(), geteuid(), getegid(), getpid(), getppid());
  return 0;
}
