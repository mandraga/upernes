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
#include <string.h>
#include <assert.h>
#include <vector>
#include "opcode_6502.h"
#include "opcodes.h"
#include "rom_file.h"
#include "cpu6502.h"
#include "nes.h"
#include "mapper.h"
#include "instruction6502.h"
#include "label.h"
#include "indirectJmp.h"
#include "recompilateur.h"

void Crecompilateur::outReplaceJumpIndirect(FILE *fp, t_pinstr pinstr,
					    Copcodes *popcode_list)
{
  fprintf(fp, "\t;---------------------\n");
  fprintf(fp, "\t;        ");
  popcode_list->out_instruction(fp, pinstr->opcode, pinstr->operand, NULL);
  fprintf(fp, "\n");
  fprintf(fp, "\tjmp IndJmp%04X\n", pinstr->operand);
  fprintf(fp, "\t;------------\n");
}
