#ifndef _FEATURES_H
#define _FEATURES_H

/* The `#include <features.h>' in the user program indicates that the user
 * wants all the feature-test macros ready. For __MINILIBC686__, the
 * system-specific macros are defined on the command line (e.g.
 * -D__MULTIOS__, -DCONFIG_MAIN_ARGS_AUTO, -DCONFIG_VFPRINTF_NO_PLUS), and
 * -the feature-test infrastructure macros are defined in `<_preincl.h>'.
 * -Thus we just have to do `#include <preincl.h>' here.
 */

/* It would be tempting to do `#define __MINILIBC686__ 1' here, but that
 * would be incorrect if pts-tcc is used with our directory as the C include
 * path (`-I...'), for example `.../tools/miniutcc -D__UCLIBC__
 * -I.../libc/include/minilibc' called by `minicc --utcc' in minilibc686.
 */
/*#define __MINILIBC686__ 1*/

#include <_preincl.h>

#endif  /* _FEATURES_H */
