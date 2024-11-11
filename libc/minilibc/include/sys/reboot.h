#ifndef _SYS_REBOOT_H
#define _SYS_REBOOT_H
#include <_preincl.h>

#define RB_AUTOBOOT	0x01234567  /* Perform a hard reset now.  */
#define RB_HALT_SYSTEM	0xcdef0123  /* Halt the system.  */
#define RB_ENABLE_CAD	0x89abcdef  /* Enable reboot using Ctrl-Alt-Delete keystroke.  */
#define RB_DISABLE_CAD	0           /* Disable reboot using Ctrl-Alt-Delete keystroke.  */
#define RB_POWER_OFF	0x4321fedc  /* Stop system and switch power off if possible.  */
#define RB_SW_SUSPEND	0xd000fce2  /* Suspend system using software suspend.  */
#define RB_KEXEC	0x45584543  /* Reboot system into new kernel.  */
#ifdef __MINILIBC686__
  /* Constants from <linux/reboot.h>. */
#  define LINUX_REBOOT_MAGIC1     0xfee1dead
#  define LINUX_REBOOT_MAGIC2     672274793
#  define LINUX_REBOOT_CMD_RESTART        0x01234567
#  define LINUX_REBOOT_CMD_HALT           0xCDEF0123
#  define LINUX_REBOOT_CMD_CAD_ON         0x89ABCDEF
#  define LINUX_REBOOT_CMD_CAD_OFF        0x00000000
#  define LINUX_REBOOT_CMD_POWER_OFF      0x4321FEDC
#  define LINUX_REBOOT_CMD_RESTART2       0xA1B2C3D4
#  define LINUX_REBOOT_CMD_SW_SUSPEND     0xD000FCE2
#  define LINUX_REBOOT_CMD_KEXEC          0x45584543
  __LIBC_FUNC(int, sys_reboot, (int magic, int magic2, int cmd, void *arg), __LIBC_NOATTR);
#  define reboot(howto) sys_reboot(LINUX_REBOOT_MAGIC1, LINUX_REBOOT_MAGIC2, howto, 0)
#else
  __LIBC_FUNC(int, reboot, (int howto), __LIBC_NOATTR);
#endif

#endif  /* _SYS_REBOOT_H */
