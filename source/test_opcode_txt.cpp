#include <stdio.h>
#include "opcode_6502.h"
#include "opcodes.h"

int main(void)
{
  Copcodes *popcode_list;
  char path[] = "./opcodes.txt";

  popcode_list = NULL;
  popcode_list = new Copcodes();
  if (popcode_list->fill_structure((char*)path) == 0)
    popcode_list->print_list();
  delete popcode_list;
  return 0;
}
