
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
#define RAMROUTINESIZE          5
// This is 0x7000 in the org directive
#define EMULATIONROUTINEADDRESS 0xF000

#define SNDREGEMUBASE           0x0830
/*
 * This method patches the rom binary with jsr to ram routines.
 * - PRG contains the orignal rom.
 * - The Routines vector is the replacement routine array used in emulation.
 * - pinstr is the pointer to the instruction
 *
 */
void Crecompilateur::patchBRK(t_pinstr pinstr, Copcodes *popcode_list, unsigned char *pPRG, unsigned int PRGSize, std::vector<t_PatchRoutine>& Routines, Cmapper *pmapper)
{
  unsigned int  i;
  unsigned int  PRGAddress;
  unsigned int  RamRoutineAddress;
  unsigned long instruction;
  bool          bRoutineFound;
  unsigned int  lastRoutine;
  
  PRGAddress = pmapper->cpu2prg(pinstr->addr);
  instruction = pPRG[PRGAddress] + (pPRG[PRGAddress + 1] << 8) + (pPRG[PRGAddress + 2] << 16);
  popcode_list->print_instruction(pinstr->addr, instruction);
  // If it is a write only sound register, then only write to a byte in the ram, it will be updated later
  if ((pinstr->operand >= 0x4000 && pinstr->operand <= 0x4013) || pinstr->operand == 0x4015)
    {
      printf("%02X kept at %04X\n", pPRG[PRGAddress], pinstr->addr);
      // The data is directly written in $FE4000 without patching
      // unsigned int  SndRegEmuAddress;
      // SndRegEmuAddress = pinstr->operand - 0x4000 + SNDREGEMUBASE;
      // pPRG[PRGAddress + 1] = SndRegEmuAddress & 0xFF;
      // pPRG[PRGAddress + 2] = (SndRegEmuAddress >> 8) & 0xFF;
      printf("Using register %04X\n", pinstr->addr);
    }
  else if (pinstr->opcode == 0x6C) // JMP
    {
      printf("%02X replaced by %02X at %04X\n", pPRG[PRGAddress], 0x4C, pinstr->addr);
      pPRG[PRGAddress] = 0x4C; // JMP
      // the next 2 bytes are a code to find the proper routine.
      assert(Routines.size() < 256);
      for (i = 0, bRoutineFound = false; i < Routines.size(); i++)
	{
	  if (Routines[i].opcode == pinstr->opcode && Routines[i].operand == pinstr->operand)
	    {
	      printf("Pointing to routine %s\n", Routines[i].RoutineName);
	      // Special case for the sta 2006 routine @
	      if (Routines[i].opcode == 0x8D &&
		  Routines[i].operand == 0x2006)
		{
		  // Get the special routine at the end of the code
		  lastRoutine = Routines.size() - 1;
		  RamRoutineAddress = Routines[lastRoutine].ramOffset + Routines[lastRoutine].ramSize; // Address of the code in ram, after the last routine
		}
	      else
		{
		  RamRoutineAddress = Routines[i].ramOffset; // Address of the code in ram
		}
	      RamRoutineAddress += RAMROUTINEBASEADDRESS;
	      pPRG[PRGAddress + 1] = RamRoutineAddress & 0xFF;
	      pPRG[PRGAddress + 2] = (RamRoutineAddress >> 8) & 0xFF;
	      bRoutineFound = true;
	    }
	}
      if (!bRoutineFound)
	{
	  printf("Patch routine not found!\n");
  	  printf("opcode %02X, operand %04X\n", pinstr->opcode, pinstr->operand);
	  assert(false);
	}      
    }
  else
    {
      printf("%02X replaced by %02X at %04X\n", pPRG[PRGAddress], 0x20, pinstr->addr);
      pPRG[PRGAddress] = 0x20; // JSR
      // the next 2 bytes are a code to find the proper routine.
      assert(Routines.size() < 256);
      for (i = 0, bRoutineFound = false; i < Routines.size(); i++)
	{
	  if (Routines[i].opcode == pinstr->opcode && Routines[i].operand == pinstr->operand)
	    {
	      printf("Pointing to routine %s\n", Routines[i].RoutineName);
	      // Special case for the sta 2006 routine @
	      if (Routines[i].opcode == 0x8D &&
		  Routines[i].operand == 0x2006)
		{
		  // Get the special routine at the end of the code
		  lastRoutine = Routines.size() - 1;
		  RamRoutineAddress = Routines[lastRoutine].ramOffset + Routines[lastRoutine].ramSize; // Address of the code in ram, after the last routine
		}
	      else
		{
		  RamRoutineAddress = Routines[i].ramOffset; // Address of the code in ram
		}
	      RamRoutineAddress += RAMROUTINEBASEADDRESS;
	      pPRG[PRGAddress + 1] = RamRoutineAddress & 0xFF;
	      pPRG[PRGAddress + 2] = (RamRoutineAddress >> 8) & 0xFF;
	      bRoutineFound = true;
	    }
	}
      if (!bRoutineFound)
	{
	  printf("Patch routine not found!\n");
  	  printf("opcode %02X, operand %04X\n", pinstr->opcode, pinstr->operand);
	  assert(false);
	}
    }
  //
  instruction = pPRG[PRGAddress] + (pPRG[PRGAddress + 1] << 8) + (pPRG[PRGAddress + 2] << 16);
  popcode_list->print_instruction(pinstr->addr, instruction);
  printf("\n");
}

/*
 * Write routines in ram. They are used to go from Bank 1 where the patched PRG rom is, to bank 0 where emulation code is.
 * Returns the size of the buffer
 */
//#define GOTOEMULATIONBANK
unsigned int Crecompilateur::writeRamRoutineBinary(const char *fileName, std::vector<t_PatchRoutine>& Patches)
{
  FILE          *fp;
  unsigned int   i;
  std::vector<unsigned char> RamBuffer;
  unsigned int   routineAddress;
#ifdef GOTOEMULATIONBANK
  unsigned int   sta2006Address;
#endif
  t_PatchRoutine *pPatch;
  unsigned int    SndRegEmuAddress;
  
  for (i = 0; i < Patches.size(); i++)
    {
      pPatch = &Patches[i];
      // Do nothing with the sound registers here
      // The code here is unused the routines are unused
      if ((pPatch->operand >= 0x4000 && pPatch->operand <= 0x4013) || pPatch->operand == 0x4015)
	{
	  pPatch->ramOffset = RamBuffer.size();
	  // Should not be called!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
	  RamBuffer.push_back(pPatch->opcode);
	  //SndRegEmuAddress = pPatch->operand - 0x4000 + SNDREGEMUBASE;
	  SndRegEmuAddress = pPatch->operand;
	  RamBuffer.push_back(SndRegEmuAddress & 0xFF);
	  RamBuffer.push_back((SndRegEmuAddress >> 8) & 0xFF);
	  RamBuffer.push_back(0x60); // RTS
	  pPatch->ramSize = RamBuffer.size() - pPatch->ramOffset;
	  //
	  pPatch->ramSize = 0;
	}
      else if ((pPatch->operand == 0x4016 || pPatch->operand == 0x4017)) // Joypadx accesses
	{
	  // Only needs to go from the wram bank to a bank were it can access the io register
	  /*
	    Reading:
	    phb
	    lda #$80
	    pha
	    plb
	    exec
	    plb
	    rts

	    Writing:
	    phb
	    pha
	    lda #$80
	    pha
	    plb
	    exec
	    pla
	    plb
	    rts	
	  */
	  pPatch->ramOffset = RamBuffer.size();
	  RamBuffer.push_back(0x8B); // phb
	  if (pPatch->opcode == 0xAD || pPatch->opcode == 0xBD) // LDA ABS; LDA ABS,X
	    {
	      RamBuffer.push_back(0xA9); // lda #80
	      RamBuffer.push_back(0x80);
	      RamBuffer.push_back(0x48); // pha
	      RamBuffer.push_back(0xAB); // plb
	    }
	  else if (pPatch->opcode == 0x8D) // STA
	    {
	      RamBuffer.push_back(0x48); // pha
	      RamBuffer.push_back(0xA9); // lda #80
	      RamBuffer.push_back(0x80);
	      RamBuffer.push_back(0x48); // pha
	      RamBuffer.push_back(0xAB); // plb
      	      RamBuffer.push_back(0x68); // pla
	    }
	  else
	    {
	      printf("Unsuported joypad read.\n");
	      assert(false);
	    }
	  RamBuffer.push_back(pPatch->opcode);
	  RamBuffer.push_back(pPatch->operand & 0xFF);
	  RamBuffer.push_back((pPatch->operand >> 8) & 0xFF);
	  RamBuffer.push_back(0xAB); // plb
       	  RamBuffer.push_back(0x60); // rts
	  pPatch->ramSize = RamBuffer.size() - pPatch->ramOffset;
	}
      // If it is an indirect jump, only do a jml
      else if (pPatch->opcode == 0x6C) // Indirect jump
	{
  	  pPatch->ramOffset = RamBuffer.size();
	  RamBuffer.push_back(0x08); // PHP
	  RamBuffer.push_back(0x78); // SEI We do ont want any IRQ to occur in bank 0, every IRQ must be in the patched PRG bank
	  RamBuffer.push_back(0x5C); // JML
	  routineAddress = EMULATIONROUTINEADDRESS + 3 * i; // The space for JMP $xxxx
	  RamBuffer.push_back(routineAddress & 0xFF); // routine address
	  RamBuffer.push_back((routineAddress >> 8) & 0xFF);
	  RamBuffer.push_back(0x80); // $80 bank (Fast ROM)
	  pPatch->ramSize = RamBuffer.size() - pPatch->ramOffset;
	}
      // Replace lda PPUSTATUS or ldx PPUSTATUS or ldy PPUSTATUS with a shorter version
      else if ((pPatch->opcode == 0xAD /*|| pPatch->opcode == 0xAE*/) && pPatch->operand == 0x2002)
	{
	  /*
	  ;; Power up test
	  lda StarPPUStatus
	  bne PowerUp     ; If 1, then it is power up (always here, even on reset)
          ; Normal operation
	  ; The scroll registers latches are cleared by a read to this register
	  lda #$00
	  sta WriteToggle
          lda PPUStatus     ; From the IRQ update
	  rts
	PowerUp:
          lda #$00
	  sta StarPPUStatus ; Boot passed
	  lda #$80          ; return boot PPUSTATUS
	  sta PPUStatus
	  rts
	  */
#ifdef SELF_MOD_CODE
	  // Remove the 2 first instructions
#else	  
	  pPatch->ramOffset = RamBuffer.size();
	  RamBuffer.push_back(0xAD); // lda StarPPUStatus
  	  RamBuffer.push_back(0x12);
  	  RamBuffer.push_back(0x09);
	  RamBuffer.push_back(0xD0); // bne
	  RamBuffer.push_back(0x07);
	  RamBuffer.push_back(0x9C); // stz WriteToggle
  	  RamBuffer.push_back(0x06);
  	  RamBuffer.push_back(0x09);
	  RamBuffer.push_back(0xAD); // lda PPUStatus
  	  RamBuffer.push_back(0x0D);
  	  RamBuffer.push_back(0x09);
     	  RamBuffer.push_back(0x60); // rts
	  // PowerUp
	  RamBuffer.push_back(0xA9); // lda #00
	  RamBuffer.push_back(0x00);
	  RamBuffer.push_back(0x8D); // sta StarPPUStatus
  	  RamBuffer.push_back(0x12);
  	  RamBuffer.push_back(0x09);
 	  RamBuffer.push_back(0xA9); // lda #80
	  RamBuffer.push_back(0x80);
	  RamBuffer.push_back(0x8D); // sta PPUStatus
  	  RamBuffer.push_back(0x0D);
  	  RamBuffer.push_back(0x09);	  
     	  RamBuffer.push_back(0x60); // rts
#endif
	  pPatch->ramSize = RamBuffer.size() - pPatch->ramOffset;
	}
      else
	{
	  pPatch->ramOffset = RamBuffer.size();
	  RamBuffer.push_back(0x08); // PHP
	  RamBuffer.push_back(0x78); // SEI We do ont want any IRQ to occur in bank 0, every IRQ must be in the patched PRG bank
	  // No we don't, disable the nmi interrupt
#ifdef DISABLENMIDURINGIOEMULATION
	  RamBuffer.push_back(0xAD); // LDA SNESNMITMP
	  RamBuffer.push_back(0x13);
	  RamBuffer.push_back(0x08);
	  RamBuffer.push_back(0x29); // AND
	  RamBuffer.push_back(0x7F); // #$7F
	  RamBuffer.push_back(0x8D); // STA NMITIMEN
	  RamBuffer.push_back(0x00);
	  RamBuffer.push_back(0x42);
#endif //DISABLENMIDURINGIOEMULATION
	  // Continue with normal operation
	  RamBuffer.push_back(0x22); // JSL
	  routineAddress = EMULATIONROUTINEADDRESS + 3 * i; // The space for JMP $xxxx
	  RamBuffer.push_back(routineAddress & 0xFF); // routine address
	  RamBuffer.push_back((routineAddress >> 8) & 0xFF);
	  RamBuffer.push_back(0x80); // $80 bank (Fast ROM)
#ifdef DISABLENMIDURINGIOEMULATION
	  // Restore NMI
	  RamBuffer.push_back(0xAD); // LDA SNESNMITMP
	  RamBuffer.push_back(0x13);
	  RamBuffer.push_back(0x08);
	  RamBuffer.push_back(0x8D); // STA NMITIMEN
	  RamBuffer.push_back(0x00);
	  RamBuffer.push_back(0x42);
#endif //DISABLENMIDURINGIOEMULATION
	  // Restore flags and interrupts
	  RamBuffer.push_back(0x28); // PLP
	  RamBuffer.push_back(0x58); // CLI for IRQ routines
	  // Add a flag update if it was reading
	  if (pPatch->type == read)
	    {
	      switch (pPatch->opcode)
		{
		case 0xAE:  // LDX
		  {
		    RamBuffer.push_back(0xAE); // LDX Xi
		    RamBuffer.push_back(0x02);
		    RamBuffer.push_back(0x08);
		  }
		  break;
		case 0xAC:  // LDY
		  {
		    RamBuffer.push_back(0xAC); // LDY Yi
		    RamBuffer.push_back(0x04);
		    RamBuffer.push_back(0x08);
		  }
		  break;
	      	case 0x2C:  // BIT
		  {
		    RamBuffer.push_back(0x2C); // BIT Yi
		    RamBuffer.push_back(0x04);
		    RamBuffer.push_back(0x08);
		  }
		  break;
		default: // LDA
		  {
		    RamBuffer.push_back(0x09); // ORA #$00
		    RamBuffer.push_back(0x00);
		  }
		  break;
		}
	    }
	  // Return, enough of it
	  RamBuffer.push_back(0x60); // RTS
	  pPatch->ramSize = RamBuffer.size() - pPatch->ramOffset;
	}
#ifdef GOTOEMULATIONBANK
      // Save the sta routine @
      if (Patches[i].opcode == 0x8D &&
	  Patches[i].operand == 0x2006)
	{
	  sta2006Address = routineAddress;
	}
#endif
    }
  // Add a quicker sta write to ppuaddr
  m_PPUAddrRoutineSize = RamBuffer.size();
  RamBuffer.push_back(0x48); // pha
  RamBuffer.push_back(0xAD); // lda
  RamBuffer.push_back(0x06); // WriteToggle $906
  RamBuffer.push_back(0x09); //
  RamBuffer.push_back(0xD0); // bne
  RamBuffer.push_back(0x08); // Relative @, +8 bytes
  RamBuffer.push_back(0xEE); // inc WriteToggle $906
  RamBuffer.push_back(0x06); //
  RamBuffer.push_back(0x09); //
  RamBuffer.push_back(0x68); // pla
  RamBuffer.push_back(0x8D); // sta PPUmemaddrH $905
  RamBuffer.push_back(0x05); //
  RamBuffer.push_back(0x09); //
  RamBuffer.push_back(0x60); // rts
  // Second branch, the write is finished
  // pla
  // sta PPUmemaddrL
  // stz WriteToggle
  // pha
  // lda #$01
  // sta PPUReadLatch
  // lda PPUmemaddrH
  // and #$3F
  // sta tH
  // pla
  // rts
#ifndef GOTOEMULATIONBANK
  RamBuffer.push_back(0x68); // pla
  RamBuffer.push_back(0x8D); // sta PPUmemaddrL $904
  RamBuffer.push_back(0x04); //
  RamBuffer.push_back(0x09); //
  RamBuffer.push_back(0x48); // pha
  RamBuffer.push_back(0x9C); // stz
  RamBuffer.push_back(0x06); // WriteToggle $906
  RamBuffer.push_back(0x09);
  RamBuffer.push_back(0xA9); // lda
  RamBuffer.push_back(0x01); // #$01
  RamBuffer.push_back(0x8D); // sta
  RamBuffer.push_back(0x1A); // PPUReadLatch is at $81A
  RamBuffer.push_back(0x08);
  RamBuffer.push_back(0xAD); // lda
  RamBuffer.push_back(0x05); // PPUmemaddrH $905
  RamBuffer.push_back(0x09); //
  RamBuffer.push_back(0x29); // and #$3F
  RamBuffer.push_back(0x3F); //
  RamBuffer.push_back(0x8D); // sta
  RamBuffer.push_back(0xA1); // tH is at $09A1
  RamBuffer.push_back(0x09);
  RamBuffer.push_back(0x68); // pla
#else //GOTOEMULATIONBANK
  RamBuffer.push_back(0x68); // pla
  RamBuffer.push_back(0x22); // JSL to sta $2006
  RamBuffer.push_back(sta2006Address & 0xFF); // Address of the full routine
  RamBuffer.push_back((sta2006Address >> 8) & 0xFF); //
  RamBuffer.push_back(0x80); // $80 bank
#endif //GOTOEMULATIONBANK
  RamBuffer.push_back(0x60); // rts
  m_PPUAddrRoutineSize = RamBuffer.size() - m_PPUAddrRoutineSize;
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
  return i;
}

/*
 * Sorts the routines by write, read, and indirectjumps
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
void Crecompilateur::writeRoutineVector(FILE *fp, Copcodes *popcode_list, std::vector<t_PatchRoutine>& Patches, int readIndex, int indJmpIndex, int soundEmuLine)
{
  unsigned int i;
  unsigned int size;

  fprintf(fp, "\n.ENDS\n\n\n");
  fprintf(fp, ";-------------------------------------------------------------------------------------\n");
  fprintf(fp, "; Routines called through the ram code\n");
  fprintf(fp, ".BANK 0 SLOT 0\n");
  fprintf(fp, ".ORG    $7000\n");
  fprintf(fp, ".SECTION \"RamEntry\" SEMIFREE\n");
  fprintf(fp, "FromRamRoutinesTable:\n");
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
      if ((Patches[i].operand >= 0x4000 && Patches[i].operand <= 0x4013) || Patches[i].operand == 0x4015)
	{
	  fprintf(fp, "jmp %s\t\t; not used, Sound regs\n", Patches[i].RoutineName);
	}
      else
	{
	  fprintf(fp, "jmp %s\n", Patches[i].RoutineName);
	}
    }
  // Number of io routines
  fprintf(fp, "\n.DEFINE NBIOROUTINES %d\n", (int)Patches.size());
  if (Patches.size() == 0)
    {
      printf("Something is wrong in the PRG patching: no patches found.\n");
      return;
    }
  size = Patches[(int)Patches.size() - 1].ramOffset + Patches[(int)Patches.size() - 1].ramSize;
  size += m_PPUAddrRoutineSize;
  fprintf(fp, ".DEFINE RAMBINSIZE   %d\n", size);
  fprintf(fp, ".DEFINE RAMBINWSIZE  %d\n", size / 2 + (size & 1)); // Add 1 if odd in order to copy all the data 
  fprintf(fp, ".DEFINE READROUTINESINDEX %d\n", readIndex);
  fprintf(fp, ".DEFINE INDJMPINDEX %d\n", indJmpIndex);
  // Sound emulation line
  fprintf(fp, ".DEFINE SOUNDEMULINE %d\n", soundEmuLine);
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
  bool                        bnesIRQVect;
  bool                        bnesNMIVect;
    
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
      if (pindjmp->GetPatchingDisabled())
	{
	  fprintf(fp, "\n; Indirect jump emulation checks are disabled.\n");
	}
      // Write the ram routines here in order to have their sizes and label @
      snprintf(filePath, cstrsz, "%sRam.bin", outName);
      writeRamRoutineBinary(filePath, PatchRoutines);
      // Write the Vector and size Defines
      writeRoutineVector(fp, popcode_list, PatchRoutines, readIndex, indJmpIndex, pindjmp->GetSoundEmuLine());
      // Patch the rom buffer
      bnesIRQVect = bnesNMIVect = false;
      pinstr = plisting->get_next(true);
      while (pinstr != NULL)
	{
	  switch (pinstr->isvectorstart)
	    {
	    case resetstart:
	      // Label of the first instruction executed on start/reset. Bank 1
	      fprintf(fp, "\n.DEFINE NESRESET   $7E%04X", pinstr->addr);
	      break;
	    case nmistart:
	      // Label of the non maskable interrupt routine
	      fprintf(fp, "\n.DEFINE NESNMI     $7E%04X", pinstr->addr);
	      bnesNMIVect = true;
	      break;
	    case irqbrkstart:
      	      // Label of the IRQ/BRK interrupt routine
	      fprintf(fp, "\n.DEFINE NESIRQBRK  $7E%04X", pinstr->addr);
	      bnesIRQVect = true;
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
	      // Patch the io port code
	      patchBRK(pinstr, popcode_list, pPRG, PRGSize, PatchRoutines, &mapper);
	      break;
	    case replaceBackupRam:
	      //outReplaceBackupRam(fp, pinstr, popcode_list);
	      break;
	    case replaceJumpIndirect:
	      // Patch the indirect jump code
	      if (!pindjmp->GetPatchingDisabled())
		{
		  patchBRK(pinstr, popcode_list, pPRG, PRGSize, PatchRoutines, &mapper);
		}
	      break;
	    default:
	      break;
	    };
	  pinstr = plisting->get_next(false);
	}
      if (!bnesNMIVect)
	{
	  fprintf(fp, "\n.DEFINE NESNMI     $%04X", 0); // Empty
	}
      if (!bnesIRQVect)
	{
	  fprintf(fp, "\n.DEFINE NESIRQBRK  $%04X", 0); // Empty
	}
      fprintf(fp, "\n\n.ENDS\n");
      fclose(fp);
      // Save info about the cartridge
      snprintf(filePath, cstrsz, "mapper.inc");
      fp = fopen(filePath, "w");
      if (prom->m_Vertical_mirroring)
	{
	  fprintf(fp, "\n\n.DEFINE HORIZONTALSCROLLING");
	}
      else
	{
	  fprintf(fp, "\n\n.DEFINE VETICALSCROLLING");	  
	}
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
    }
  catch (int e)
    {
      return 1;
    }
  return 0; 
}

