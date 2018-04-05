#include <stdlib.h>
#include "prints.c"

int main(void) {
  int i;
  char *test;

  for (i = 0; i < 10; i++) {
    test = malloc(10000);
    
    print_("test is 0x");
    print_hex((unsigned long)test);
    print_("\n");
  }
}
