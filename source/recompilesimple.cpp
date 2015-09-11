
#include <stdio.h>
#include <assert.h>
#include "opcode_6502.h"
#include "opcodes.h"
#include "rom_file.h"
#include "cpu6502.h"
#include "nes.h"
#include "instruction6502.h"
#include "label.h"
#include "recompilateur.h"

void Crecompilateur::writeheader(FILE *fp)
{
  fprintf(fp, "\n.include \"cartridge.inc\"\n\n");
  fprintf(fp, "\n.include \"var.inc\"\n\n");
  fprintf(fp, ".BANK 0\n.ORG 0\n.SECTION \"Nesprg\"\n");  
}

void Crecompilateur::printlabel(FILE *fp, t_pinstr pinstr)
{
  t_label *labelptr;

  if (pinstr->is_label())
    {
      labelptr = findlabel(pinstr->addr);
      assert(labelptr != NULL);
      if (labelptr->is_jsr)
	fprintf(fp, "\nRoutinelabel%04d:\n", labelptr->countjsr);
      if (labelptr->is_indirectjmp)
	fprintf(fp, "indirectlabel%04d:\n", labelptr->countijmp);
      if (labelptr->is_staticjmp)
	fprintf(fp, "label%04d:\n", labelptr->countjmp);
    }
}

// Writes a label name for operand use depending on the instruction type
void Crecompilateur::strprintoperandlabel(t_pinstr pinstr, Copcodes *popcode_list, char *pstrout, int len)
{
  t_label *labelptr;

  labelptr = findlabel(pinstr->branchaddr);
  assert(labelptr != NULL);
  assert(pinstr->opcode != 0x6C);  // indirect jump in another function
  if (popcode_list->is_mnemonic(pinstr->opcode, "jsr"))
      snprintf(pstrout, len, "Routinelabel%04d", labelptr->countjsr);
  else
    snprintf(pstrout, len, "label%04d", labelptr->countjmp); // static jmp and branches
}

void Crecompilateur::outinstr(FILE *fp, t_pinstr pinstr, Copcodes *popcode_list)
{
  char labelstr[LABELSZ];
  char *plabelstr;

  // Label if any
  plabelstr = NULL;
  if (popcode_list->is_branch(pinstr->opcode) ||
      popcode_list->is_mnemonic(pinstr->opcode, "jmp") ||
      popcode_list->is_mnemonic(pinstr->opcode, "jsr"))
    {
      strprintoperandlabel(pinstr, popcode_list, labelstr, LABELSZ);
      plabelstr = labelstr;
    }
  fprintf(fp, "\t");
  popcode_list->out_instruction(fp, pinstr->opcode, pinstr->operand, plabelstr);
  fprintf(fp, "\n");
}

