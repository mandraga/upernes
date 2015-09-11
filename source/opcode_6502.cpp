

#include <string.h>
#include "opcode_6502.h"

Cmnemonic_6502::Cmnemonic_6502():
  Flags(0),
  nb_ops(0),
  category(-1)
{
  strcpy(pstr_description, "");
  memset(mnemonic, 0, sizeof(mnemonic));
  memset(ops, 0, sizeof(ops));
}
  
Cmnemonic_6502::~Cmnemonic_6502()
{
}
