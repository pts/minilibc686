extern void mini_exit(int exit_code);  /* Function under test. */

int main(int argc, char **argv) {
  (void)argc; (void)argv;
  mini_exit(0);  /* EXIT_SUCCESS. Doesn't return. */
  return 2;  /* Failure. */
}
