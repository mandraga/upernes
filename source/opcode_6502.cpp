//     This program is free software: you can redistribute it and/or modify
//     it under the terms of the GNU General Public License as published by
//     the Free Software Foundation, either version 3 of the License, or
//     (at your option) any later version.
//
//     This program is distributed in the hope that it will be useful,
//     but WITHOUT ANY WARRANTY; without even the implied warranty of
//     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//     GNU General Public License for more details.
//
//     You should have received a copy of the GNU General Public License
//     along with this program.  If not, see <http://www.gnu.org/licenses/>.
//
//     upernes Copyright 2015 Patrick Xavier Areny - "arenyp at yahoo.fr"

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
