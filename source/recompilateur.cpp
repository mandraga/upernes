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
//     upernes Copyright 2015 Patrick Areny - "arenyp at yahoo.fr"

#include <stdio.h>
#include <string.h>
#include <vector>
#include <assert.h>
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


Crecompilateur::Crecompilateur()
{
  strcpy(m_error_str, "");
}

void Crecompilateur::labelgen(t_label *plabel)
{
  static int jsr = 0;
  static int jmp = 0;
  static int ind = 0;

  if (plabel->is_jsr)
    plabel->countjsr = jsr++;
  else
    plabel->countjsr = -1;
  if (plabel->is_staticjmp)
    plabel->countjmp = jmp++;
  else
    plabel->countjmp = -1;    
  if (plabel->is_indirectjmp)
    plabel->countijmp = ind++;
  else
    plabel->countijmp = -1;
  assert(jmp < 10000 && jsr < 10000);
}

void Crecompilateur::create_label_list(Cprogramlisting *plisting,
				       Copcodes *pops)
{
  t_label         tmplabel;
  Instruction6502 *pinstr;
  bool            bstart = true;

  m_label_gen_list.clear();
  pinstr = plisting->get_next(bstart);
  bstart = false;
  while (pinstr != NULL)
    {
      if (pinstr->is_label())
	{

	  assert(pinstr->label_category(pops, &tmplabel.is_jsr, &tmplabel.is_staticjmp, &tmplabel.is_indirectjmp));
	  labelgen(&tmplabel);
	  tmplabel.addr = pinstr->addr;
	  m_label_gen_list.push_front(tmplabel);
	}
      pinstr = plisting->get_next(bstart);
    }
}

t_label_list *Crecompilateur::get_label_gen_info()
{
  return &m_label_gen_list;
}

t_label *Crecompilateur::findlabel(int addr)
{
  t_label_list::iterator LI;

  for (LI = m_label_gen_list.begin(); LI != m_label_gen_list.end(); LI++)
    {
      if ((*LI).addr == addr)
	return (&(*LI));
    }
  return NULL;
}

// Only instructions addressing 16bits are replaced.
// And this 16bit address must access an IO port or the backup ram, and not the joystick 1 register.
int Crecompilateur::isreplaced(t_pinstr pinstr, Copcodes *popcode_list)
{
  int addressing;
  int addr;

  addressing = popcode_list->addressing(pinstr->opcode);
  if (addressing < 0)
    {
      addressing = popcode_list->addressing(pinstr->opcode);
      fprintf(stderr, "Wrong address and opcode $%4X at $%4X!!!! FIXME rom code confusion?\n", pinstr->opcode, pinstr->addr);
      return shityOpcode;
    }
  //assert (addressing >= 0);
  switch (addressing)
    {
    case Ind:
      return replaceJumpIndirect;
    case Abs:
    case AbsX:
    case AbsY:
    case IndX:
    case IndY:
      addr = pinstr->operand;
      if (IS_PORT(addr)
#ifdef DONOTPATCHJOYPADRW
	  && addr != JOYSTICK1 /*&& addr != JOYSTICK2_SNDSEQUENCER*/
#endif
	  )
	{
	  return replaceIOPort;
	}
      if (IS_PORT_RANGE(addr)
#ifdef DONOTPATCHJOYPADRW
	  && addr != JOYSTICK1 /*&& !(addr == JOYSTICK2_SNDSEQUENCER && pinstr->type == read)*/
#endif
	  )
	{
	  snprintf(m_error_str, sizeof(m_error_str),
		   "unknown Io port $%4X", addr);
	  throw int(1);
	}
      if (IS_BACKUP_RAM_RANGE(pinstr->addr))
	return replaceBackupRam;
    default:
      break;
    };
  return noreplace;
}

int Crecompilateur::re(const char *outname, Cprogramlisting *plisting,
		       Copcodes *popcode_list, Crom_file *prom)
{
  FILE                       *fp;
  Instruction6502            *pinstr;
  bool                        irqbrkvector = false;
  bool                        nmivector = false;
  std::vector<t_PatchRoutine> PatchRoutines;

  try
    {
      fp = fopen(outname, "w");
      if (fp == NULL)
	{
	  snprintf(m_error_str, sizeof(m_error_str),
		   "opening file %s failed", outname);
	  throw int(1);
	}
      //      fp = stdout;
      create_label_list(plisting, popcode_list);
      writeheader(fp);
      pinstr = plisting->get_next(true);
      while (pinstr != NULL)
	{
	  switch (pinstr->isvectorstart)
	    {
	    case resetstart:
	      // Label of the first instruction executed on start/reset
	      fprintf(fp, "NESReset:\n");
	      break;
	    case nmistart:
	      // Label of the non maskable interrupt routine
	      fprintf(fp, "NESNonMaskableInterrupt:\n");
	      nmivector = true;
	      break;
	    case irqbrkstart:
	      //
	      fprintf(fp, "NESIRQBRK:\n");
	      irqbrkvector = true;
	      break;
	    default:
	      break;
	    }
	  printlabel(fp, pinstr);
	  switch (isreplaced(pinstr, popcode_list))
	    {
	    case noreplace:
	      outinstr(fp, pinstr, popcode_list);
	      break;
	    case replaceIOPort:
	      outReplaceIOport(fp, pinstr, popcode_list);
	      break;
	    case replaceBackupRam:
	      //outReplaceBackupRam(fp, pinstr, popcode_list);
	      break;
	    case replaceJumpIndirect:
	      outReplaceJumpIndirect(fp, pinstr, popcode_list);
	      break;
	    case shityOpcode:
	      printf("shitty opcode at $%04X!!\n", pinstr->addr);
	      break;
	    default:
	      break;
	    };
	  pinstr = plisting->get_next(false);
	}
      fprintf(fp, "\n");
      if (!nmivector)
	{
	  fprintf(fp, "NESNonMaskableInterrupt:\n");
	  fprintf(fp, "\tjmp DebugHandler\n");
	}
      if (!irqbrkvector)
	{
	  fprintf(fp, "NESIRQBRK:\n");
	  fprintf(fp, "\tjmp DebugHandler\n");
	}
      fprintf(fp, "\n");
      // io port accesses are replaced by a jsr to a routine,
      // the routines are written here.
      writeiop_routines(fp, plisting, popcode_list, PatchRoutines);
      fprintf(fp, "\n.ENDS\n");
      fclose(fp);
    }
  catch (int e)
    {
      return 1;
    }
  return 0;
}

