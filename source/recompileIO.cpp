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

void Crecompilateur::print_save(FILE *fp)
{
  fprintf(fp, "\tphp\n\tstx Xi\n");
}

void Crecompilateur::print_restore(FILE *fp)
{
  fprintf(fp, "\tldx Xi\n\tplp\n");
}

void Crecompilateur::AddPRGPatch(int iopaddr, Copcodes *popcode_list, Instruction6502 *pinstr, char *routineName, std::vector<t_PatchRoutine> &PatchRoutines)
{
  t_PatchRoutine PatchR;

  PatchR.opcode  = pinstr->opcode;
  PatchR.operand = pinstr->operand;
  snprintf(PatchR.RoutineName, LABELSZ, "%s", routineName);
  PatchRoutines.push_back(PatchR);
}

void Crecompilateur::routineSTAiop(FILE *fp, int iopaddr, Copcodes *popcode_list, Instruction6502 *pinstr, std::vector<t_PatchRoutine> &PatchRoutines)
{
   char routine[LABELSZ];

  snprintf(routine, LABELSZ, "rsta_%02X", iopaddr); // Print the label name);
  fprintf(fp, "\n%s:\n", routine); // Print the label name
  // Save status...
  print_save(fp);
  // Put the io port somewhere
  fprintf(fp, "\tldx #$%02X\n", 2 * PORT2INDEX(iopaddr));
  fprintf(fp, "\tjsr staioportroutine\n");
  print_restore(fp);
  fprintf(fp, "\trts\n");
  AddPRGPatch(iopaddr, popcode_list, pinstr, routine, PatchRoutines);
}

void Crecompilateur::routineSTAAbsXiop(FILE *fp, int iopaddr, Copcodes *popcode_list, Instruction6502 *pinstr, std::vector<t_PatchRoutine> &PatchRoutines)
{
  /*
    rsta_4002AbsX:
         sta Acc
	 txa
	 asl A
	 clc               X x 2
	 adc #$portindex;
	 tax               X == ioport routine address + X
	 lda Acc
         ldx #$portindex
	 ...
  */
  char routine[LABELSZ];

  snprintf(routine, LABELSZ, "rsta_%02XAbsX", iopaddr); // Print the label name);
  fprintf(fp, "\n%s:\n", routine); // Print the label name
  // Save status...
  print_save(fp);
  // Put the io port somewhere
  fprintf(fp, "\tsta Acc\n");
  fprintf(fp, "\ttxa\n");
  fprintf(fp, "\tasl A\n");
  fprintf(fp, "\tclc\n");
  fprintf(fp, "\tadc #$%02X\n", 2 * PORT2INDEX(iopaddr));
  fprintf(fp, "\ttax\n");
  fprintf(fp, "\tlda Acc\n");
  fprintf(fp, "\tjsr staioportroutine\n");
  print_restore(fp);
  fprintf(fp, "\trts\n");
  AddPRGPatch(iopaddr, popcode_list, pinstr, routine, PatchRoutines);
}

void Crecompilateur::routineSTAAbsYiop(FILE *fp, int iopaddr, Copcodes *popcode_list, Instruction6502 *pinstr, std::vector<t_PatchRoutine> &PatchRoutines)
{
  /*
    rsta_4002AbsY:
         sta Acc
	 sty Yi
	 tya
	 asl A
	 clc               Y x 2
	 adc #$portindex;
	 tax               X == ioport routine address + Y
	 lda Acc
	 ldy Yi
         ldx #$portindex
	 ...
  */
  char routine[LABELSZ];

  snprintf(routine, LABELSZ, "rsta_%02XAbsY", iopaddr); // Print the label name);
  fprintf(fp, "\n%s:\n", routine); // Print the label name
  // Save status...
  print_save(fp);
  // Put the io port somewhere
  fprintf(fp, "\tsta Acc\n");
  fprintf(fp, "\tsty Yi\n");
  fprintf(fp, "\ttya\n");
  fprintf(fp, "\tasl A\n");
  fprintf(fp, "\tclc\n");
  fprintf(fp, "\tadc #$%02X\n", 2 * PORT2INDEX(iopaddr));
  fprintf(fp, "\ttax\n");
  fprintf(fp, "\tlda Acc\n");
  fprintf(fp, "\tldy Yi\n");
  fprintf(fp, "\tjsr staioportroutine\n");
  print_restore(fp);
  fprintf(fp, "\trts\n");
  AddPRGPatch(iopaddr, popcode_list, pinstr, routine, PatchRoutines);
}

void Crecompilateur::routineLDAiop(FILE *fp, int iopaddr, Copcodes *popcode_list, Instruction6502 *pinstr, std::vector<t_PatchRoutine> &PatchRoutines)
{
  char routine[LABELSZ];

  snprintf(routine, LABELSZ, "rlda_%02X", iopaddr); // Print the label name);
  fprintf(fp, "\n%s:\n", routine);
  print_save(fp);
  // Put the io port somewhere
  fprintf(fp, "\tldx #$%02X\n", 2 * PORT2INDEX(iopaddr));
  fprintf(fp, "\tjsr ldaioportroutine\n");
  print_restore(fp);
  fprintf(fp, "\tora #$00		; test N Z flags without affecting A\n");
  fprintf(fp, "\trts\n");
  AddPRGPatch(iopaddr, popcode_list, pinstr, routine, PatchRoutines);
}

void Crecompilateur::routineLDXiop(FILE *fp, int iopaddr, Copcodes *popcode_list, Instruction6502 *pinstr, std::vector<t_PatchRoutine> &PatchRoutines)
{
  char routine[LABELSZ];

  snprintf(routine, LABELSZ, "rldx_%02X", iopaddr); // Print the label name);
  fprintf(fp, "\n%s:\n", routine);
  fprintf(fp, "\tsta Acc\n");
  fprintf(fp, "\tldx #$%02X\n", 2 * PORT2INDEX(iopaddr));
  fprintf(fp, "\tjsr ldaioportroutine\n");
  fprintf(fp, "\tsta Xi\n");
  fprintf(fp, "\tlda Acc\n");
  fprintf(fp, "\tldx Xi		; x like if it has been loaded by a ldx\n");  
  fprintf(fp, "\trts\n");
  AddPRGPatch(iopaddr, popcode_list, pinstr, routine, PatchRoutines);
}

void Crecompilateur::routineLDYiop(FILE *fp, int iopaddr, Copcodes *popcode_list, Instruction6502 *pinstr, std::vector<t_PatchRoutine> &PatchRoutines)
{
  char routine[LABELSZ];
 
  snprintf(routine, LABELSZ, "rldy_%02X", iopaddr); // Print the label name);
  fprintf(fp, "\n%s:\n", routine);
  print_save(fp);
  fprintf(fp, "\tsta Acc\n");
  fprintf(fp, "\tldx #$%02X\n", 2 * PORT2INDEX(iopaddr));
  fprintf(fp, "\tjsr ldaioportroutine\n");
  fprintf(fp, "\tsta Yi\n");
  fprintf(fp, "\tlda Acc\n");
  print_restore(fp);
  fprintf(fp, "\tldy Yi		; y like if it has been loaded by a ldy\n");
  fprintf(fp, "\trts\n");
  AddPRGPatch(iopaddr, popcode_list, pinstr, routine, PatchRoutines);
}

void Crecompilateur::routineSTXiop(FILE *fp, int iopaddr, Copcodes *popcode_list, Instruction6502 *pinstr, std::vector<t_PatchRoutine> &PatchRoutines)
{
  char routine[LABELSZ];
 
  snprintf(routine, LABELSZ, "rstx_%02X", iopaddr); // Print the label name
  fprintf(fp, "\n%s:\n", routine);
  // Save status...
  print_save(fp);
  fprintf(fp, "\tsta Acc\n");
  fprintf(fp, "\ttxa\n");
  fprintf(fp, "\tldx #$%02X\n", 2 * PORT2INDEX(iopaddr));
  fprintf(fp, "\tjsr staioportroutine\n");
  fprintf(fp, "\tlda Acc\n");
  print_restore(fp);
  fprintf(fp, "\trts\n");
  AddPRGPatch(iopaddr, popcode_list, pinstr, routine, PatchRoutines);
}

void Crecompilateur::routineSTYiop(FILE *fp, int iopaddr, Copcodes *popcode_list, Instruction6502 *pinstr, std::vector<t_PatchRoutine> &PatchRoutines)
{
  char routine[LABELSZ];
 
  snprintf(routine, LABELSZ, "rsty_%02X", iopaddr); // Print the label name
  fprintf(fp, "\n%s:\n", routine);
  // Save status...
  print_save(fp);
  fprintf(fp, "\tsta Acc\n");
  fprintf(fp, "\ttya\n");
  // Y is saved in the call
  fprintf(fp, "\tldx #$%02X\n", 2 * PORT2INDEX(iopaddr));
  fprintf(fp, "\tjsr staioportroutine\n");
  fprintf(fp, "\tlda Acc\n");
  print_restore(fp);
  fprintf(fp, "\trts\n");
  AddPRGPatch(iopaddr, popcode_list, pinstr, routine, PatchRoutines);
}

void Crecompilateur::ReplaceAbsAddressing(FILE *fp, t_pinstr pinstr,
					  Copcodes *popcode_list, bool &replaced)
{
  // Replacement by a routine call like: "jsr r_sta_2007"
  fprintf(fp, "\tjsr r");
  popcode_list->out_mnemonic(fp, pinstr->opcode);
  fprintf(fp, "_%02X\n", pinstr->operand);
  replaced = true;

  /*
  if (popcode_list->is_mnemonic(pinstr->opcode, "sta"))
    {
      fprintf(fp, "\tjsr rsta_%02X\n", pinstr->operand);
      replaced = true;
    }
  if (popcode_list->is_mnemonic(pinstr->opcode, "lda"))
    {
      fprintf(fp, "\tjsr rlda_%02X\n", pinstr->operand);
      assert(!replaced);
      replaced = true;
    }
  if (popcode_list->is_mnemonic(pinstr->opcode, "ldx"))
    {
      fprintf(fp, "\tjsr rldx_%02X\n", pinstr->operand);
      assert(!replaced);
      replaced = true;
    }
  if (popcode_list->is_mnemonic(pinstr->opcode, "stx"))
    {
      fprintf(fp, "\tjsr rstx_%02X\n", pinstr->operand);
      assert(!replaced);
      replaced = true;
    }
  if (popcode_list->is_mnemonic(pinstr->opcode, "ldy"))
    {
      fprintf(fp, "\tjsr rldy_%02X\n", pinstr->operand);
      assert(!replaced);
      replaced = true;
    }
  if (popcode_list->is_mnemonic(pinstr->opcode, "sty"))
    {
      fprintf(fp, "\tjsr rsty_%02X\n", pinstr->operand);
      assert(!replaced);
      replaced = true;
    }
  */
}

void Crecompilateur::ReplaceAbsXAddressing(FILE *fp, t_pinstr pinstr,
					  Copcodes *popcode_list, bool &replaced)
{
  // Replacement by a routine call like: "jsr r_sta_2007AbsX"
  fprintf(fp, "\tjsr r");
  popcode_list->out_mnemonic(fp, pinstr->opcode);
  fprintf(fp, "_%02XAbsX\n", pinstr->operand);
  replaced = true;
}

void Crecompilateur::ReplaceAbsYAddressing(FILE *fp, t_pinstr pinstr,
					  Copcodes *popcode_list, bool &replaced)
{
  // Replacement by a routine call like: "jsr r_sta_2007AbsY"
  fprintf(fp, "\tjsr r");
  popcode_list->out_mnemonic(fp, pinstr->opcode);
  fprintf(fp, "_%02XAbsY\n", pinstr->operand);
  replaced = true;
}

void Crecompilateur::outReplaceIOport(FILE *fp, t_pinstr pinstr,
				      Copcodes *popcode_list)
{
  char *pioname;
  bool replaced = false;

  fprintf(fp, "\t;---------------------\n");
  fprintf(fp, "\t;        ");
  popcode_list->out_instruction(fp, pinstr->opcode, pinstr->operand, NULL); // Output the original instruction as a comment
  if ((pioname = (char*)CnesIO::getioname(pinstr->operand)) != NULL)
    fprintf(fp, "  %s\n", pioname);
  else
    fprintf(fp, "\n");

  // TODO add absolute indexed addressing
  int   addressing = popcode_list->addressing(pinstr->opcode);
  if (addressing != Abs)
    {
      // Print it on stdio for debug purposes
      printf("Replacing a sensitive access to an io port\n");
      popcode_list->print_instruction(pinstr->addr, pinstr->operand << 8 | pinstr->opcode);
    }
  switch (addressing)
    {
    case Abs:
      ReplaceAbsAddressing(fp, pinstr, popcode_list, replaced);
      break;
    case AbsX:
      ReplaceAbsXAddressing(fp, pinstr, popcode_list, replaced);
      break;
    case AbsY:
      ReplaceAbsYAddressing(fp, pinstr, popcode_list, replaced);
      break;
    default:
      {
	printf("IO addressing not yet programmed (in recompileIO.cpp)\n");
	assert(addressing == Abs);
      }
    };
  if (!replaced)
    {
      snprintf(m_error_str, sizeof(m_error_str),
	       "%s line %d, unsuported opcode conversion ($%02X operand $%04X)", __FILE__, __LINE__, pinstr->opcode, pinstr->operand);
      throw int(1);
    }
  fprintf(fp, "\t;------------\n");
}

bool Crecompilateur::findinstr(const char *mnemonicstr, t_instrlist *plist, Copcodes *popcode_list, int &addressing, Instruction6502 **pinstr)
{
  t_instrlist::iterator II;
  int ret = false;

  for (II = plist->begin(), addressing = 0; II != plist->end(); II++)
    {
      if (popcode_list->is_mnemonic((*II)->opcode, mnemonicstr))
	{
	  *pinstr = (*II);
	  ret = true;
	  switch (popcode_list->addressing((*II)->opcode))
	    {
	    case Abs:
	      addressing |= 1;
	      break;
	    case AbsX:
	      addressing |= 2;
	      break;
	    case AbsY:
	      addressing |= 4;
	      break;
	    };
	}
    }
  return ret;
}

void Crecompilateur::writeiop_routines(FILE *fp, Cprogramlisting *plisting, Copcodes *popcode_list, std::vector<t_PatchRoutine> &PatchRoutines)
{
  t_instrlist *plist;
  bool start = true;
  int  iopaddr;
  int  addressing;
  Instruction6502 *pinstr;

  while (plisting->get_IO_accessed(start, &plist))
    {
      start = false;
      iopaddr = (*plist->begin())->operand; // Get the address from the first access
      if (iopaddr == JOYSTICK1)
	continue ;
      // The list of accesses contains all the instructions using the IO port
      // If found, wrtie it to the file
      if (findinstr("lda", plist, popcode_list, addressing, &pinstr))
	{
	  if (addressing & 1)
	    {
	      routineLDAiop(fp, iopaddr, popcode_list, pinstr, PatchRoutines);
	    }
	  assert(addressing == 1);
	}
      else if (findinstr("ldx", plist, popcode_list, addressing, &pinstr))
	{
  	  routineLDXiop(fp, iopaddr, popcode_list, pinstr, PatchRoutines);
	  assert(addressing == 1);
	}
      else if (findinstr("ldy", plist, popcode_list, addressing, &pinstr))
	{
	  routineLDYiop(fp, iopaddr, popcode_list, pinstr, PatchRoutines);
	  assert(addressing == 1);
	}
      else if (findinstr("sta", plist, popcode_list, addressing, &pinstr))
	{
	  if (addressing & 1)
	    routineSTAiop(fp, iopaddr, popcode_list, pinstr, PatchRoutines);
	  if (addressing & 2)
	    routineSTAAbsXiop(fp, iopaddr, popcode_list, pinstr, PatchRoutines);
	  if (addressing & 4)
	    routineSTAAbsYiop(fp, iopaddr, popcode_list, pinstr, PatchRoutines);
	}
      else if (findinstr("stx", plist, popcode_list, addressing, &pinstr))
	{
	  routineSTXiop(fp, iopaddr, popcode_list, pinstr, PatchRoutines);
	  assert(addressing == 1);
	}
      else if (findinstr("sty", plist, popcode_list, addressing, &pinstr))
	{
	  routineSTYiop(fp, iopaddr, popcode_list, pinstr, PatchRoutines);
	  assert(addressing == 1);
	}
      else
	{
	  printf("Unsuported io port access: \n");
	  assert(false);
	}
    }
}
