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
