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
  fprintf(fp, "\tstx Xi\n");
}

void Crecompilateur::print_restore(FILE *fp)
{
  fprintf(fp, "\tldx Xi\n");
}

/*
 * Takes a list of instruction accessing a port and stores the routine index if not present
 */
void Crecompilateur::AddPRGPatch(int iopaddr, Copcodes *popcode_list, t_pinstr pinstr, char *routineName, std::vector<t_PatchRoutine> &PatchRoutines)
{
  t_PatchRoutine PatchR;
  
  PatchR.opcode  = pinstr->opcode;
  PatchR.operand = pinstr->operand;
  PatchR.type = write;
  if (pinstr->opcode == 0x6C) // indirect jump
    {
      PatchR.type = indirectJump;
    }
  // FIXME it only covers lda ldx ldy but not all the possible opcodes
  else if (pinstr->opcode == 0xAD || pinstr->opcode == 0xBD || pinstr->opcode == 0xB9 || // lda
	   pinstr->opcode == 0xAE || pinstr->opcode == 0xBE || // ldx
	   pinstr->opcode == 0xAC || pinstr->opcode == 0xBC || // ldy
	   pinstr->opcode == 0x2C)
	   
    {
      PatchR.type = read;
    }
  snprintf(PatchR.RoutineName, LABELSZ, "%s", routineName);
  PatchRoutines.push_back(PatchR);
}

void Crecompilateur::routineSTAiop(FILE *fp, int iopaddr, Copcodes *popcode_list, t_pinstr pinstr, std::vector<t_PatchRoutine> &PatchRoutines)
{
  char routine[LABELSZ];

  snprintf(routine, LABELSZ, "rsta_%02X", iopaddr); // Print the label name);
  fprintf(fp, "\n%s:\n", routine); // Print the label name
  // Save status...
  print_save(fp);
  fprintf(fp, "\tsta Acc\n");
  // Put the io port somewhere
  fprintf(fp, "\tldx #$%02X\n", 2 * PORT2INDEX(iopaddr));
  fprintf(fp, "\tjsr staioportroutine\n");
  fprintf(fp, "\tlda Acc\n");
  print_restore(fp);
  fprintf(fp, "\trtl\n");
  AddPRGPatch(iopaddr, popcode_list, pinstr, routine, PatchRoutines);
}

void Crecompilateur::routineSTAAbsXiop(FILE *fp, int iopaddr, Copcodes *popcode_list, t_pinstr pinstr, std::vector<t_PatchRoutine> &PatchRoutines)
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
	 jsr staioportroutine
	 lda Acc
	 ldx Xi
	 rtl
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
  fprintf(fp, "\tlda Acc\n");
  print_restore(fp);
  fprintf(fp, "\trtl\n");
  AddPRGPatch(iopaddr, popcode_list, pinstr, routine, PatchRoutines);
}

void Crecompilateur::routineSTAAbsYiop(FILE *fp, int iopaddr, Copcodes *popcode_list, t_pinstr pinstr, std::vector<t_PatchRoutine> &PatchRoutines)
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
  fprintf(fp, "\trtl\n");
  AddPRGPatch(iopaddr, popcode_list, pinstr, routine, PatchRoutines);
}

void Crecompilateur::routineLDAiop(FILE *fp, int iopaddr, Copcodes *popcode_list, t_pinstr pinstr, std::vector<t_PatchRoutine> &PatchRoutines)
{
  char routine[LABELSZ];

  snprintf(routine, LABELSZ, "rlda_%02X", iopaddr); // Print the label name);
  fprintf(fp, "\n%s:\n", routine);
  print_save(fp);
  // Put the io port somewhere
  fprintf(fp, "\tldx #$%02X\n", 2 * PORT2INDEX(iopaddr));
  fprintf(fp, "\tjsr ldaioportroutine\n");
  print_restore(fp);
  // In RAM  
  //fprintf(fp, "\tora #$00		; test N Z flags without affecting A\n");
  fprintf(fp, "\trtl\n");
  AddPRGPatch(iopaddr, popcode_list, pinstr, routine, PatchRoutines);
}

void Crecompilateur::routineLDAAbsXiop(FILE *fp, int iopaddr, Copcodes *popcode_list, t_pinstr pinstr, std::vector<t_PatchRoutine> &PatchRoutines)
{
  char routine[LABELSZ];

  /*
    rlda_4000AbsX:
      stx Xi
      txa
      asl A
      clc
      adc #$portindex
      tax
      jsr ldaioportroutine
      ldx Xi
      ora #$00
      rtl
   */
  snprintf(routine, LABELSZ, "rlda_%02XAbsX", iopaddr); // Print the label name);
  fprintf(fp, "\n%s:\n", routine);
  print_save(fp);
  // Put the io port somewhere
  fprintf(fp, "\ttxa\n");
  fprintf(fp, "\tasl A\n");
  fprintf(fp, "\tclc\n");
  fprintf(fp, "\tadc #$%02X\n", 2 * PORT2INDEX(iopaddr));
  fprintf(fp, "\ttax\n");
  fprintf(fp, "\tjsr ldaioportroutine\n");
  print_restore(fp);
  fprintf(fp, "\tora #$00		; test N Z flags without affecting A\n");
  fprintf(fp, "\trtl\n");
  //
  AddPRGPatch(iopaddr, popcode_list, pinstr, routine, PatchRoutines);
}

void Crecompilateur::routineLDXiop(FILE *fp, int iopaddr, Copcodes *popcode_list, t_pinstr pinstr, std::vector<t_PatchRoutine> &PatchRoutines)
{
  char routine[LABELSZ];

  snprintf(routine, LABELSZ, "rldx_%02X", iopaddr); // Print the label name);
  fprintf(fp, "\n%s:\n", routine);
  fprintf(fp, "\tsta Acc\n");
  fprintf(fp, "\tldx #$%02X\n", 2 * PORT2INDEX(iopaddr));
  fprintf(fp, "\tjsr ldaioportroutine\n");
  fprintf(fp, "\tsta Xi\n");
  fprintf(fp, "\tlda Acc\n");
  // In RAM  
  //fprintf(fp, "\tldx Xi		; x like if it has been loaded by a ldx\n");  
  fprintf(fp, "\trtl\n");
  AddPRGPatch(iopaddr, popcode_list, pinstr, routine, PatchRoutines);
}

void Crecompilateur::routineLDYiop(FILE *fp, int iopaddr, Copcodes *popcode_list, t_pinstr pinstr, std::vector<t_PatchRoutine> &PatchRoutines)
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
  // In RAM  
  //fprintf(fp, "\tldy Yi		; y like if it has been loaded by a ldy\n");
  fprintf(fp, "\trtl\n");
  AddPRGPatch(iopaddr, popcode_list, pinstr, routine, PatchRoutines);
}

void Crecompilateur::routineBITiop(FILE *fp, int iopaddr, Copcodes *popcode_list, t_pinstr pinstr, std::vector<t_PatchRoutine> &PatchRoutines)
{
  char routine[LABELSZ];

  snprintf(routine, LABELSZ, "rbit_%02X", iopaddr); // Print the label name);
  fprintf(fp, "\n%s:\n", routine);
  print_save(fp);
  fprintf(fp, "\tsta Acc\n");
  // Put the io port somewhere
  fprintf(fp, "\tldx #$%02X\n", 2 * PORT2INDEX(iopaddr));
  fprintf(fp, "\tjsr ldaioportroutine\n");
  fprintf(fp, "\tsta Yi\n");  // Use Yi as a tmp register
  fprintf(fp, "\tlda Acc\n");
  print_restore(fp);
  // In RAM
  //fprintf(fp, "\tbit Yi\n");
  fprintf(fp, "\trtl\n");
  AddPRGPatch(iopaddr, popcode_list, pinstr, routine, PatchRoutines);
}

void Crecompilateur::routineSTXiop(FILE *fp, int iopaddr, Copcodes *popcode_list, t_pinstr pinstr, std::vector<t_PatchRoutine> &PatchRoutines)
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
  fprintf(fp, "\trtl\n");
  AddPRGPatch(iopaddr, popcode_list, pinstr, routine, PatchRoutines);
}

void Crecompilateur::routineSTYiop(FILE *fp, int iopaddr, Copcodes *popcode_list, t_pinstr pinstr, std::vector<t_PatchRoutine> &PatchRoutines)
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
  fprintf(fp, "\trtl\n");
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

bool Crecompilateur::isIn(t_pinstr pinstr, t_instrlist& instrList)
{
  std::list<t_pinstr>::iterator it;

  it = instrList.begin();
  while (it != instrList.end())
    {
      if ((*it)->opcode == pinstr->opcode &&
	  (*it)->operand == pinstr->operand)
	{
	  return true;
	}
      it++;
    }
  return false;
}

/*
 * Goes through the instruction list and looks for the given mnemonic
 */
bool Crecompilateur::findinstr(const char *mnemonicstr, t_instrlist *plist, Copcodes *popcode_list, int &addressing, t_instrlist& instrList)
{
  t_instrlist::iterator II;
  int ret = false;

  instrList.clear();
  for (II = plist->begin(), addressing = 0; II != plist->end(); II++)
    {
      if (popcode_list->is_mnemonic((*II)->opcode, mnemonicstr))
	{
	  if (!isIn((*II), instrList))
	    {
	      instrList.push_back((*II));
	    }
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

/*
 * Writes the IO port access routines
 *
 * Goes through the instruction accessing the ports and prints the emulation routines.
 */
void Crecompilateur::writeiop_routines(FILE *fp, Cprogramlisting *plisting, Copcodes *popcode_list, std::vector<t_PatchRoutine> &PatchRoutines)
{
  t_instrlist *plist;
  bool start = true;
  int  iopaddr;
  int  addressing;
  t_instrlist instrList;
  t_instrlist::iterator it;
  t_pinstr pinstr;

  // For each IO port, will give the complete list of instructions accessessing it.
  while (plisting->get_IO_accessed(start, &plist))
    {
      start = false;
      iopaddr = (*plist->begin())->operand; // Get the address from the first access
#ifdef DONOTPATCHJOYPADRW
      if (iopaddr == JOYSTICK1)
	continue ;
#endif
      // The list of accesses contains all the instructions using the IO port
      // If an instruction is found, write his emulation routine to the file
      if (findinstr("lda", plist, popcode_list, addressing, instrList))
	{
	    it = instrList.begin();
	    while (it != instrList.end())
	      {
		pinstr = *it;
		switch (popcode_list->addressing(pinstr->opcode))
		  {
		  case Abs:
		    routineLDAiop(fp, iopaddr, popcode_list, pinstr, PatchRoutines);
		    break;
		  case AbsX:
		    routineLDAAbsXiop(fp, iopaddr, popcode_list, pinstr, PatchRoutines);
		    break;
		  case AbsY:
		    printf("lda AbsY addressing mode not implemented\n");
		    assert(false);
		    break;
		  };
		it++;
	      }
	}
      if (findinstr("ldx", plist, popcode_list, addressing, instrList))
	{
	  it = instrList.begin();
	  while (it != instrList.end())
	    {
	      pinstr = *it;
	      switch (popcode_list->addressing(pinstr->opcode))
		{
		case Abs:
		  routineLDXiop(fp, iopaddr, popcode_list, pinstr, PatchRoutines);
		  break;
		case AbsY:
		  printf("ldx AbsY addressing mode non implemented\n");
		  assert(false);
		  break;
		};
	      it++;
	    }
	  assert(addressing == 1);
	}
      if (findinstr("ldy", plist, popcode_list, addressing, instrList))
	{
	  it = instrList.begin();
	  while (it != instrList.end())
	    {
	      pinstr = *it;
	      switch (popcode_list->addressing(pinstr->opcode))
		{
		case Abs:
		  routineLDYiop(fp, iopaddr, popcode_list, pinstr, PatchRoutines);
		  break;
		case AbsX:
		  printf("ldy AbsX addressing mode not implemented\n");
		  assert(false);
		  break;
		};
	      it++;
	    }
	  assert(addressing == 1);
	}
      if (findinstr("bit", plist, popcode_list, addressing, instrList))
	{
	  it = instrList.begin();
	  while (it != instrList.end())
	    {
	      pinstr = *it;
	      switch (popcode_list->addressing(pinstr->opcode))
		{
		case Abs:
		  routineBITiop(fp, iopaddr, popcode_list, pinstr, PatchRoutines);
		  break;
		};
	      it++;
	    }
	  assert(addressing == 1);
	}
      if (findinstr("sta", plist, popcode_list, addressing, instrList))
	{
	    it = instrList.begin();
	    while (it != instrList.end())
	      {
		pinstr = *it;
		switch (popcode_list->addressing(pinstr->opcode))
		  {
		  case Abs:
		    routineSTAiop(fp, iopaddr, popcode_list, pinstr, PatchRoutines);
		    break;
		  case AbsX:
		    routineSTAAbsXiop(fp, iopaddr, popcode_list, pinstr, PatchRoutines);
		    break;
		  case AbsY:
		    routineSTAAbsYiop(fp, iopaddr, popcode_list, pinstr, PatchRoutines);
		    break;
		  };
		it++;
	      }
	}
      if (findinstr("stx", plist, popcode_list, addressing, instrList))
	{
	  routineSTXiop(fp, iopaddr, popcode_list, *instrList.begin(), PatchRoutines);
	  assert(addressing == 1);
	}
      if (findinstr("sty", plist, popcode_list, addressing, instrList))
	{
	  routineSTYiop(fp, iopaddr, popcode_list, *instrList.begin(), PatchRoutines);
	  assert(addressing == 1);
	}
    }
}

