
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
#include "mapper.h"
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

#define RAMROUTINEBASEADDRESS   0x0E00
#define RAMROUTINESIZE          8
// This is 0x7000 in the org directive
#define EMULATIONROUTINEADDRESS 0xF000

/*
 * This method patches the rom binary with BRK routines.
 * - PRG contains the orignal rom.
 * - The Routines vector is the replacement routine array used in emulation.
 * - pinstr is the pointer to the instruction
 *
 */
void Crecompilateur::patchBRK(t_pinstr pinstr, Copcodes *popcode_list, unsigned char *pPRG, unsigned int PRGSize, std::vector<t_PatchRoutine>& Routines, Cmapper *pmapper)
{
  unsigned int i;
  unsigned int PRGAddress;
  unsigned int RamRoutineAddress;
  unsigned long instruction;
  bool          bRoutineFound;
  
  PRGAddress = pmapper->cpu2prg(pinstr->addr);
  instruction = pPRG[PRGAddress] + (pPRG[PRGAddress + 1] << 8) + (pPRG[PRGAddress + 2] << 16);
  popcode_list->print_instruction(pinstr->addr, instruction);
  printf("%02X replaced by %02X at %04X\n", pPRG[PRGAddress], 0x4C, pinstr->addr);
  pPRG[PRGAddress] = 0x20; // JSR
  // the next 2 bytes are a code to find the proper routine.
  assert(Routines.size() < 256);
  for (i = 0, bRoutineFound = false; i < Routines.size(); i++)
    {
      if (Routines[i].opcode == pinstr->opcode && Routines[i].operand == pinstr->operand)
	{
	  printf("Pointing to routine %s\n", Routines[i].RoutineName);
	  RamRoutineAddress = RAMROUTINEBASEADDRESS + i * RAMROUTINESIZE; // Address of the code in ram
	  pPRG[PRGAddress + 1] = RamRoutineAddress & 0xFF;
	  pPRG[PRGAddress + 2] = (RamRoutineAddress >> 8) & 0xFF;
	  bRoutineFound = true;
	}
    }
  if (!bRoutineFound)
    {
      printf("Patch routine not found!\n");
      assert(false);
    }
  //
  instruction = pPRG[PRGAddress] + (pPRG[PRGAddress + 1] << 8) + (pPRG[PRGAddress + 2] << 16);
  popcode_list->print_instruction(pinstr->addr, instruction);
  printf("\n");
}

/*
 * Write routines in ram. They are used to go from Bank 1 where the patched PRG rom is, to bank 0 where emulation code is.
 */
void Crecompilateur::writeRamRoutineBinary(const char *fileName, std::vector<t_PatchRoutine>& Patches)
{
  FILE          *fp;
  unsigned int   i;
  std::vector<unsigned char> RamBuffer;

  for (i = 0; i < Patches.size(); i++)
    {
      RamBuffer.push_back(0x08); // PHP
      //RamBuffer.push_back(0x78); // SEI
      RamBuffer.push_back(0x48); // PHA
      RamBuffer.push_back(0xA9); // LDA immediate
      RamBuffer.push_back(i & 0xFF); // Routine index
      RamBuffer.push_back(0x5C); // JML
      RamBuffer.push_back(EMULATIONROUTINEADDRESS & 0xFF); // routine address
      RamBuffer.push_back((EMULATIONROUTINEADDRESS >> 8) & 0xFF);
      RamBuffer.push_back(0x00); // $00 bank 0
    }
  // Write the binary file
  fp = fopen(fileName, "wb");
  if (fp == NULL)
    {
      snprintf(m_error_str, sizeof(m_error_str),
	       "opening file %s failed", fileName);
      throw 1;
      
    }
  for (i = 0; i < RamBuffer.size(); i++)
    {
      fwrite(&RamBuffer[i], 1, 1, fp);
    }
  fclose(fp);
}

/*
 * Sorts the routines byt write, read, and indirectjumps
 */
void Crecompilateur::sortRoutines(std::vector<t_PatchRoutine>& Patches, int& readIndex, int& indJmpIndex)
{
  std::vector<t_PatchRoutine> WrkPatches;
  unsigned int i;

  readIndex = 0;
  for (i = 0; i < Patches.size(); i++)
    {
      if (Patches[i].type == write)
	{
	  WrkPatches.push_back(Patches[i]);
	  readIndex++;
	}
    }
  indJmpIndex = readIndex;
  for (i = 0; i < Patches.size(); i++)
    {
      if (Patches[i].type == read)
	{
	  WrkPatches.push_back(Patches[i]);
	  indJmpIndex++;
	}
    }
  for (i = 0; i < Patches.size(); i++)
    {
      if (Patches[i].type == indirectJump)
	{
	  WrkPatches.push_back(Patches[i]);
	}
    }
  Patches.clear();
  Patches = WrkPatches;
}

/*
 * Writes the table of IO accesses and indirect jumps replacement.
 */
void Crecompilateur::writeRoutineVector(FILE *fp, Copcodes *popcode_list, std::vector<t_PatchRoutine>& Patches, int readIndex, int indJmpIndex)
{
  unsigned int i;
  unsigned int size;

  fprintf(fp, "BRKRoutinesTable:\n");
  for (i = 0; i < Patches.size(); i++)
    {
      if (i == (unsigned int)readIndex)
	{
	  fprintf(fp, "ReadRoutinesTable:\n");
	}
      if (i == (unsigned int)indJmpIndex)
	{
	  fprintf(fp, "IndJumpTable:\n");
	}
      fprintf(fp, ".DW %s\n", Patches[i].RoutineName);
    }
  // Number of io routines
  fprintf(fp, "\n.DEFINE NBIOROUTINES %d\n", (int)Patches.size());
  size = RAMROUTINESIZE * (int)Patches.size();
  fprintf(fp, ".DEFINE RAMBINSIZE   %d\n", size);
  fprintf(fp, ".DEFINE RAMBINWSIZE  %d\n", size / 2);
  fprintf(fp, ".DEFINE READROUTINESINDEX %d\n", readIndex);
  fprintf(fp, ".DEFINE INDJMPINDEX %d\n", indJmpIndex);
}

/*
 * Patches a PRG Rom with BRK or jsr instructions and writes the routines in an asm file.
 */
int Crecompilateur::patchPrgRom(const char *outName, Cprogramlisting *plisting, Copcodes *popcode_list, CindirectJmpRuntimeLabels *pindjmp, Crom_file *prom)
{
  const int                   cstrsz = 4096;
  FILE                       *fp;
  Instruction6502            *pinstr;
  unsigned char              *pPRG;
  CindirectJmpAsmRoutines     IndJumpsRoutines;
  std::vector<t_PatchRoutine> PatchRoutines;
  int                         PRGSize;
  Cmapper                     mapper;
  char                        filePath[cstrsz];
  int                         readIndex;
  int                         indJmpIndex;
    
  pPRG = NULL;
  try
    {
      mapper.init(prom);
      PRGSize = prom->m_PRG_size;
      pPRG = new unsigned char[PRGSize];
      prom->GetPrgCopy(pPRG);
      
      create_label_list(plisting, popcode_list);
      // Write the IO and indirect jump routines file
      snprintf(filePath, cstrsz, "%s.asm", outName);
      fp = fopen(filePath, "w");
      if (fp == NULL)
	{
	  snprintf(m_error_str, sizeof(m_error_str),
		   "opening file %s failed", filePath);
	  throw int(1);
	}
      writeheader(fp);
      writeiop_routines(fp, plisting, popcode_list, PatchRoutines);
      IndJumpsRoutines.writeIndJumproutines(fp, pindjmp, get_label_gen_info(), PatchRoutines);
      sortRoutines(PatchRoutines, readIndex, indJmpIndex);
      writeRoutineVector(fp, popcode_list, PatchRoutines, readIndex, indJmpIndex);
      // Patch the rom buffer
      pinstr = plisting->get_next(true);
      while (pinstr != NULL)
	{
	  switch (pinstr->isvectorstart)
	    {
	    case resetstart:
	      // Label of the first instruction executed on start/reset. Bank 1
	      fprintf(fp, "\n.DEFINE NESRESET   $01%04X", pinstr->addr);
	      break;
	    case nmistart:
	      // Label of the non maskable interrupt routine
	      fprintf(fp, "\n.DEFINE NESNMI     $01%04X", pinstr->addr);
	      break;
	    case irqbrkstart:
      	      // Label of the IRQ/BRK interrupt routine
	      fprintf(fp, "\n.DEFINE NESIRQBRK  $01%04X", pinstr->addr);
	      break;
	    case novector:
	    default:
	      break;
	    }
	  switch (isreplaced(pinstr, popcode_list))
	    {
	    case noreplace:
	      break;
	    case replaceIOPort:
	      // Patch the io port code with BRK Byte1 Byte2
	      patchBRK(pinstr, popcode_list, pPRG, PRGSize, PatchRoutines, &mapper);
	      break;
	    case replaceBackupRam:
	      //outReplaceBackupRam(fp, pinstr, popcode_list);
	      break;
	    case replaceJumpIndirect:
	      // Patch the indirect jump code with BRK Byte1 Byte2
	      patchBRK(pinstr, popcode_list, pPRG, PRGSize, PatchRoutines, &mapper);
	      break;
	    default:
	      break;
	    };
	  pinstr = plisting->get_next(false);
	}      
      fprintf(fp, "\n\n.ENDS\n");
      fclose(fp);
      // Write the patched PRG rom.
      snprintf(filePath, cstrsz, "%s.bin", outName);
      fp = fopen(filePath, "wb");
      if (fp == NULL)
	{
	  snprintf(m_error_str, sizeof(m_error_str),
		   "opening file %s failed", filePath);
	  throw int(1);
	}
      fwrite(pPRG, 1, PRGSize, fp);
      fclose(fp);
      delete[] pPRG;
      snprintf(filePath, cstrsz, "%sRam.bin", outName);
      writeRamRoutineBinary(filePath, PatchRoutines);
    }
  catch (int e)
    {
      return 1;
    }
  return 0; 
}

