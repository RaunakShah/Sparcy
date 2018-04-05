#include <stdlib.h>
#include "prints.c"

static int find_stack_direction() {
  static char *addr = 0;
  char dummy;

  if (addr == 0) {
      addr = &dummy;
      return find_stack_direction();
  }
  else {
      return ((&dummy > addr) ? 1 : -1);
  }
}

int main(void) {
  if (find_stack_direction() > 0)
    print_("Stack grows towards higher addrs.\n");
  else
    print_("Stack grows towards lower addrs.\n");

  return 0;
}
