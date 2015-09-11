#include <stdio.h>
#include <string.h>
#include <assert.h>
#include "opcode_6502.h"
#include "opcodes.h"
#include "rom_file.h"
#include "cpu6502.h"
#include "nes.h"
#include "instruction6502.h"
#include "label.h"
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
