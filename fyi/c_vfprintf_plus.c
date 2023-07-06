/* It supports format flags '-', '+', '0', and length modifiers. */
#include <stdarg.h>
#define BBPRINTF_INT int
#define CONFIG_BBPRINTF_LONG 0
#define PAD_RIGHT 1
#define PAD_ZERO 2
#define PAD_PLUS 4
typedef struct _FILE *FILE;
extern int mini_fputc(int c, FILE *filep);
int mini_vfprintf(FILE *filep, const char *format, va_list args) {
  register unsigned width, pad;
  register unsigned pc = 0;
  /* String buffer large enough for the longest %u and %x. */
  char print_buf[sizeof(BBPRINTF_INT) == 4 ? 11 : sizeof(BBPRINTF_INT) == 2 ? 6 : sizeof(BBPRINTF_INT) * 3 + 1];
  char c;
  unsigned BBPRINTF_INT u;
  unsigned b;
  unsigned char letbase, t;
  /*register*/ char *s;
  char neg;

  for (; *format != 0; ++format) {
    if (*format == '%') {
      ++format;
      width = pad = 0;
      if (*format == '\0') break;
      if (*format == '%') goto out;
      if (*format == '-') {
        ++format;
        pad = PAD_RIGHT;
      } else if (*format == '+') {
        ++format;
        pad = PAD_PLUS;
      }
      while (*format == '0') {
        ++format;
        pad |= PAD_ZERO;
      }
      for (; *format >= '0' && *format <= '9'; ++format) {
        width *= 10;
        width += *format - '0';
      }
      c = *format;
      s = print_buf;
      if (c == 's') {
        s = va_arg(args, char*);
        if (!s) s = (char*)"(null)";
       do_print_s:
        /* pc += prints(filep, s, width, pad); */
        c = ' ';  /* padchar. */
        if (width > 0) {
          register unsigned len = 0;
          register const char *ptr;
          for (ptr = s; *ptr; ++ptr) ++len;
          if (len >= width) width = 0;
          else width -= len;
          if (pad & PAD_ZERO) c = '0';
        }
        if (!(pad & PAD_RIGHT)) {
          for (; width > 0; --width) {
            mini_fputc(c, filep);
            ++pc;
          }
        }
        for (; *s ; ++s) {
          mini_fputc(*s, filep);
          ++pc;
        }
        for (; width > 0; --width) {
          mini_fputc(c, filep);
          ++pc;
        }
      } else if (c == 'c') {
        /* char are converted to int then pushed on the stack */
        s[0] = (char)va_arg(args, int);
        if (width == 0) {  /* Print '\0'. */
          mini_fputc(s[0], filep);
          ++pc;
        } else {
          s[1] = '\0';
          goto do_print_s;
        }
      } else {
#if CONFIG_BBPRINTF_LONG
        if (c == 'l') {  /* !! TODO(pts): Keep u as `long' if sizeof(int) >= 4. This is for saving space and time if sizeof(long) > 4. */
          u = va_arg(args, unsigned long);
          c = *++format;
        } else {
          u = va_arg(args, unsigned);
        }
#else
        u = va_arg(args, unsigned);
#endif
        if (!(c == 'd' || c == 'u' || c == 'o' || (c | 32) == 'x' )) goto done;  /* Assumes ASCII. */
        /* pc += printi(filep, va_arg(args, int), (c | 32) == 'x' ? 16 : 10, c == 'd', width, pad, c == 'X' ? 'A' : 'a'); */
        /* This code block modifies `width', and it's fine to modify `width' and `pad'. */
        b = ((c | 32) == 'x') ? 16 : c == 'o' ? 8 : 10;
        letbase = ((c == 'X') ? 'A' : 'a') - '0' - 10;
        neg = 0;
        if (c != 'd') {
        } else if ((BBPRINTF_INT)u < 0) {
          neg = '-';
          u = -(BBPRINTF_INT)u;  /* Casting to BBPRINTF_INT to avoid Borland C++ 5.2 warning: Negating unsigned value. */
        } else if (pad & PAD_PLUS) {
          neg = '+';
        }
        s = print_buf + sizeof(print_buf) - 1;
        *s = '\0';
        do {
          t = u % b;
          if (t >= 10) t += letbase;
          *--s = t + '0';
          u /= b;
        } while (u);
        if (neg) {
          if (width && (pad & PAD_ZERO)) {
            mini_fputc(neg, filep);
            ++pc;
            --width;
          } else {
            *--s = neg;
          }
        }
        goto do_print_s;
      }
    } else { out:
      mini_fputc(*format, filep);
      ++pc;
    }
  }
 done:
  va_end(args);
  return pc;
}
