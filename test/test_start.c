extern void mini__start(void);
extern void mini_exit(int exit_code);  /* Function under test. */

int main(int argc, char **argv) {
  (void)argc; (void)argv;
  /* mini__start() is untested here, it needs other tests. */
  if (argc < 0) mini__start();  /* Link it, but don't actually call it, stack is not set up properly for this call now */
  mini_exit(0);  /* EXIT_SUCCESS. Doesn't return. */
  return 2;  /* Failure. */
}
