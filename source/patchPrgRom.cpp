
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
#include <assert.h>
#include <vector>
#include "opcode_6502.h"
#include "opcodes.h"
#include "rom_file.h"
#include "cpu6502.h"
#include "nes.h"
#include "instruction6502.h"
#include "label.h"
#include "indirectJmp.h"
#include "recompilateur.h"
#include "indirectJmpAsmRoutines.h"

using namespace std;

// Instructions accessing IO ports
/*
adc
asl
dec
inc
sbc
and
eor
lsr
ora
rol
ror
lda
ldx
ldy
sta
stx
sty
bit
cmp
cpx
cpy
*/

/*
 * This method patches the rom binary with BRQ routines.
 * - PRG contains the orignal rom.
 * - The Routines vector is the replacement routine array used in emulation.
 * - pinstr is the pointer to the instruction
 *
 */
void Crecompilateur::patchBRK(t_pinstr pinstr, Copcodes *popcode_list, unsigned char *pPRG, unsigned int PRGSize, std::vector<t_PatchRoutine>& Routines)
{
  unsigned int i;

  printf("%02X replaced by %02X at %04X\n", pPRG[pinstr->addr], 0, pinstr->addr);
  pPRG[pinstr->addr] = 0x00; // BRK is 0
  // the next 2 bytes are a code to find the proper routine.
  for (i = 0; i < Routines.size(); i++)
    {
      if (Routines[i].opcode == pinstr->opcode && Routines[i].operand == pinstr->operand)
	{
	  printf("Pointing to routine %s\n", Routines[i].RoutineName);
	  pPRG[pinstr->addr + 1] = i & 0xFF;
	  pPRG[pinstr->addr + 2] = (i >> 8) & 0xFF;
	}
    }
}

/*
 * Writes the table of IO accesses and indirect jumps replacement.
 */
void Crecompilateur::writeRoutineVector(FILE *fp, Copcodes *popcode_list, std::vector<t_PatchRoutine>& Patches)
{
  unsigned int i;

  fprintf(fp, "BRKRoutinesTable:\n");
  for (i = 0; i < Patches.size(); i++)
    {
      fprintf(fp, "%s\n", Patches[i].RoutineName);
    }
  fprintf(fp, "\n");
}

/*
 * Patches a PRG Rom with BRK instructions and writes the routines in an asm file.
 */
int Crecompilateur::patchPrgRom(const char *outAsmName, const char *outPrgName, Cprogramlisting *plisting, Copcodes *popcode_list, CindirectJmpRuntimeLabels *pindjmp, Crom_file *prom)
{
  FILE                       *fp;
  Instruction6502            *pinstr;
  unsigned char              *pPRG;
  CindirectJmpAsmRoutines     IndJumpsRoutines;
  std::vector<t_PatchRoutine> PatchRoutines;
  int                         PRGSize;

  pPRG = NULL;
  try
    {
      PRGSize = prom->m_PRG_size;
      pPRG = new unsigned char[PRGSize];
      prom->GetPrgCopy(pPRG);
      
      create_label_list(plisting, popcode_list);
      // Write the IO and indirect jump routines file
      fp = fopen(outAsmName, "w");
      if (fp == NULL)
	{
	  snprintf(m_error_str, sizeof(m_error_str),
		   "opening file %s failed", outAsmName);
	  throw int(1);
	}
      writeheader(fp);
      writeiop_routines(fp, plisting, popcode_list, PatchRoutines);
      IndJumpsRoutines.writeIndJumproutines(fp, pindjmp, get_label_gen_info(), PatchRoutines);
      writeRoutineVector(fp, popcode_list, PatchRoutines);
      // Patch the rom buffer
      pinstr = plisting->get_next(true);
      while (pinstr != NULL)
	{
	  switch (pinstr->isvectorstart)
	    {
	    case resetstart:
	      // Label of the first instruction executed on start/reset
	      fprintf(fp, "\nDEFINE NESRESET %04X\n", pinstr->operand);
	      break;
	    case nmistart:
	      // Label of the non maskable interrupt routine
	      fprintf(fp, "\nDEFINE NESNMI %04X\n", pinstr->operand);
	      break;
	    case irqbrkstart:
      	      // Label of the IRQ/BRK interrupt routine
	      fprintf(fp, "\nDEFINE NESIRQBRK %04X\n", pinstr->operand);
	      break;
	    default:
	      break;
	    }
	  switch (isreplaced(pinstr, popcode_list))
	    {
	    case noreplace:
	      break;
	    case replaceIOPort:
	      // Patch the io port code with BRK Byte1 Byte2
	      patchBRK(pinstr, popcode_list, pPRG, PRGSize, PatchRoutines);
	      break;
	    case replaceBackupRam:
	      //outReplaceBackupRam(fp, pinstr, popcode_list);
	      break;
	    case replaceJumpIndirect:
	      // Patch the indirect jump code with BRK Byte1 Byte2
	      patchBRK(pinstr, popcode_list, pPRG, PRGSize, PatchRoutines);
	      break;
	    default:
	      break;
	    };
	  pinstr = plisting->get_next(false);
	}      
      fprintf(fp, "\n.ENDS\n");
      fclose(fp);
      // Write the patched PRG rom.
      fp = fopen(outPrgName, "w");
      if (fp == NULL)
	{
	  snprintf(m_error_str, sizeof(m_error_str),
		   "opening file %s failed", outPrgName);
	  throw int(1);
	}
      fwrite(pPRG, 1, PRGSize, fp);
      fclose(fp);
      delete[] pPRG;
    }
  catch (int e)
    {
      return 1;
    }
  return 0; 
}

