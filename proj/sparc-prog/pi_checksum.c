#include "prints.c"
#define NUM_DIGITS 140

int main() {
  int r[NUM_DIGITS + 1];
  int i, k;
  int b, d;
  int c = 0;
  int res = 0;
  for (i = 0; i < NUM_DIGITS; i++) {
    r[i] = 2000;
  }

  for (k = NUM_DIGITS; k > 0; k -= 14) {
    d = 0;

    i = k;
    for (;;) {
      d += r[i] * 10000;
      b = 2 * i - 1;

      r[i] = d % b;
      d /= b;
      i--;
      if (i == 0) break;
      d *= i;
    }
    
    res += c + d/10000;
    c = d % 10000;
  }

  print_("res is ");
  print_decimal(res);
  print_("\n");
    
  return 0;
}
