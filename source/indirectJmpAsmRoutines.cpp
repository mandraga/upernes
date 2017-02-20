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

// Creates "indjump.asm" where the indirectjump address validity test is executed.

#include <stdio.h>
#include <string.h>
#include <list>
#include <assert.h>

#include "opcode_6502.h"
#include "opcodes.h"
#include "rom_file.h"
#include "cpu6502.h"
#include "nes.h"
#include "instruction6502.h"
#include "label.h"
#include "recompilateur.h"
#include "indirectJmp.h"
#include "indirectJmpAsmRoutines.h"

/* Example: jmp ($0006)
.BANK 0
.ORG 0
.SECTION "IndJump"

IndJmp0006:
	sta Acc			; save Acc
	clc			; To native mode
	xce
	rep #$20		; A to 16bits
	lda $0006		; Loads the indirect address
	;; ------------------------------
	cmp addr1		; Is it address 1?
	bne testaddr2		; no, then test the next possible address
	sep #$20		; A to 8bits
	sec			; yes, then return to emulation mode
	xce			; 
	lda Acc			; restore Acc
	jmp labeladdr2		; Goto the indirect address
IndJmp0006testaddr2:
	cmp addr2
	bne testaddr3
	sec
	xce
	lda Acc
	phl
	jmp labeladdr3	
IndJmp0006testaddr3:
	cmp addr3
	bne IndJmp06Fails
	sec
	xce
	lda Acc
	phl
	jmp labeladdr3
IndJmp0006Fails:
	rep #$30
	lda #$06		; Address of the indirect address
	ldx $06
	ldy original jmp address
	jmp endindjmp
	;; ------------------------------
.ENDS
*/


void CindirectJmpAsmRoutines::write_asm_routines_header(FILE *fp)
{
  fprintf(fp, ".include \"var.inc\"\n");
  fprintf(fp, ".include \"cartridge.inc\"\n");
  fprintf(fp, "\n");
  fprintf(fp, ".BANK 0\n.ORG 0\n.SECTION \"IndJump\"\n");
}

void CindirectJmpAsmRoutines::write_asm_testfailcase(FILE *fp, int addr, int jmpoperand)
{
  fprintf(fp, "\trep #$30                   ; All 16bits \n");
  fprintf(fp, "\tlda #$%04X                 ; Address of the indirect address\n", jmpoperand);
  fprintf(fp, "\tldx $%04X                  ; Indirect address\n", jmpoperand); // Will load the indirect address from the ram.
  fprintf(fp, "\tjmp endindjmp              ; The address is unknown then print it\n");
  fprintf(fp, "\t;; ------------------------------\n");
  fprintf(fp, "\n");
}

bool CindirectJmpAsmRoutines::get_indirect_jump_labelnumber(t_label_list *plabel_gen_list, int addr, int *pnum)
{
  t_label_list::iterator ilabelgenl;

  for (ilabelgenl = plabel_gen_list->begin(); ilabelgenl != plabel_gen_list->end(); ilabelgenl++)
    {
      if ((*ilabelgenl).addr == addr)
	{
	  if (!(*ilabelgenl).is_indirectjmp)
	    printf("Program Error: an address set as a possible indirect jump destination has his indirect flag cleared!\n");
	  assert((*ilabelgenl).is_indirectjmp);
	  *pnum = (*ilabelgenl).countijmp;
	  return true;
	}
    }
  return false;
}

int  CindirectJmpAsmRoutines::create_indjump_asm_routines(const char *outname,
							  CindirectJmpRuntimeLabels *pindjmp,
							  t_label_list *plabel_gen_list)
{
  FILE         *fp;
  bool         first;
  bool         firstadd;
  unsigned int jmpoperand;
  unsigned int addr;
  //unsigned int prevjmpoperand;
  int          lcounter;
  int          indlabelnumber;

  try
    {
      fp = fopen(outname, "w");
      if (fp == NULL)
	{
	  snprintf(m_error_str, sizeof(m_error_str),
		   "in create_indjump_asm_routines opening the file \"%s\" failed", outname);
	  throw int(1);
	}
      //      fp = stdout;
      write_asm_routines_header(fp);
      // For each indirect jump, creates a test routine
      first = true;
      //prevjmpoperand = 0xFFFFFF; // starts with an impossible value for a nes address.

      if (pindjmp->next_operand(first, &jmpoperand) == false)
	fprintf(fp, "\t; no indirect jump\n");
      else
	{
	  // FIXME case where no addres was found but an indirect jump occurs????
	  while (pindjmp->next_operand(first, &jmpoperand))
	    {
	      first = false;
	      fprintf(fp, "\n\n");
	      fprintf(fp, ".ACCU 16\n");
	      fprintf(fp, "IndJmp%04X:\n", jmpoperand);
	      fprintf(fp, "\tsta Acc                    ; save Acc\n");
	      fprintf(fp, "\tclc                        ; To native mode\n");
	      fprintf(fp, "\txce\n");
	      // Go through the possible known addresses
	      firstadd = true;
	      if (pindjmp->next_indaddr(firstadd, jmpoperand, &addr))
		{
		  fprintf(fp, "\trep #$20                   ; A to 16bits\n");
		  fprintf(fp, "\tlda $%04X                  ; load the indirect address\n", jmpoperand);
		  fprintf(fp, "\t;; ------------------------------\n");
		  lcounter = 1;
		  while (pindjmp->next_indaddr(firstadd, jmpoperand, &addr))
		    {
		      firstadd = false;
		      // Compares A with all the known addresses
		      fprintf(fp, ".ACCU 16\n");
		      fprintf(fp, "\tcmp #$%04X                 ; Is it address $%04X?\n", addr, addr);
		      fprintf(fp, "\tbne IndJmp%04Xtestaddr%04d ; no then test the next possible address\n", jmpoperand, lcounter);
		      fprintf(fp, "\tsep #$20                   ; A to 8bits\n");
		      fprintf(fp, "\tsec                        ; return to emulation mode\n");
		      fprintf(fp, "\txce\n");
		      fprintf(fp, "\tlda Acc                    ; restore the Accumulator\n");
		      if (get_indirect_jump_labelnumber(plabel_gen_list, addr, &indlabelnumber))
			fprintf(fp, "\tjmp indirectlabel%04d   ; static jump to the indirect label\n", indlabelnumber);
		      else
			assert(false);
		      fprintf(fp, "IndJmp%04Xtestaddr%04d:\n", jmpoperand, lcounter);
		      lcounter++;
		    }
		}
	      write_asm_testfailcase(fp, addr, jmpoperand);
	    }
	}
      fprintf(fp, "\n.ENDS\n");
      fclose(fp);
    }
  catch (int e)
    {
      return 1;
    }
  return 0;
}
