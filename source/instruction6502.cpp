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
#include "opcode_6502.h"
#include "opcodes.h"
#include "cpu6502.h"
#include "nes.h"
#include "instruction6502.h"

Instruction6502::Instruction6502(unsigned short instraddr):
  opcode(-1),
  operand(0),
  addr(instraddr),
  branchaddr(0),
  binsubroutine(false),
  pbranches(NULL)
{
}

Instruction6502::~Instruction6502()
{
  if (pbranches != NULL)
    {
      delete pbranches;
      pbranches = NULL;
    }
}

bool Instruction6502::is_label()
{
  return (pbranches != NULL);
}

bool Instruction6502::label_category(Copcodes *pops, bool *pis_jsr, bool *pis_staticjmp, bool *pis_indjmp)
{
  t_instrlist::iterator li;
  
  *pis_jsr = *pis_staticjmp = *pis_indjmp = false;
  if (!is_label())
    return false;
  // A link to this label must be a jump
  for (li = pbranches->begin(); li != pbranches->end(); li++)
    {
      if (pops->is_mnemonic((*li)->opcode, "jsr"))
	*pis_jsr = true;
      if (pops->is_mnemonic((*li)->opcode, "jmp"))
	{
	  if ((*li)->opcode == 0x6C) // indirect jump
	    *pis_indjmp = true;
	  else
	    *pis_staticjmp = true;
	}
      else
	if (pops->is_branch((*li)->opcode))
	  *pis_staticjmp = true;
    }
  return (*pis_jsr || *pis_staticjmp || *pis_indjmp);
}

Cprogramlisting::Cprogramlisting():
  m_bckupaccess(0),
  m_stackaccess(0)
{
  memset(m_memaccesses, 0, sizeof(m_memaccesses));
}

Cprogramlisting::~Cprogramlisting()
{
  t_instrlist::iterator II;

  if (m_listing.size())
    {
      for (II = m_listing.begin(); II != m_listing.end(); II++)
	{
	  assert((*II) != NULL);
	  delete (*II);
	}
    }
}

Instruction6502 *Cprogramlisting::find_instr(int addr)
{
  t_instrlist::iterator II;

  for (II = m_listing.begin(); II != m_listing.end() && ((*II)->addr <= addr); II++)
    {
      if ((*II)->addr == addr)
	return (*II);
    }
  return NULL;
}

Instruction6502 *Cprogramlisting::create_instr(int addr)
{
  t_instrlist::iterator II;
  t_pinstr              pinstr;
 
  for (II = m_listing.begin(); II != m_listing.end() && ((*II)->addr < addr); II++);
  pinstr = new Instruction6502(addr);
  m_listing.insert(II, 1, pinstr);
  return pinstr;
}

void Cprogramlisting::insert(int opcode, int operand, int addr, int vectstart)
{
  Instruction6502 *instr;

  if ((instr = find_instr(addr)) == NULL)
    instr = create_instr(addr);
  assert(instr);
  instr->opcode = opcode;
  instr->operand = operand;
  instr->addr = addr;
  instr->isvectorstart = vectstart;
}

void Cprogramlisting::insert_branch(int jmpaddr, int destaddr)
{
  Instruction6502 *instr;
  Instruction6502 *jmpinstr;

  if ((instr = find_instr(destaddr)) == NULL)
    instr = create_instr(destaddr);
  assert(instr);
  if (instr->pbranches == NULL)
    instr->pbranches = new t_instrlist;
  jmpinstr = find_instr(jmpaddr);
  assert(jmpinstr); // The jump instruction going to destaddr must be already in the list
  jmpinstr->branchaddr = destaddr;
  instr->pbranches->push_front(jmpinstr);
}

// Partial execution
int Cprogramlisting::update_state(int addr, Ccpu6502 cpustate)
{
  Instruction6502 *instr;

  instr = find_instr(addr);
  assert(instr);
  instr->cpustate = cpustate;
  return 0;
}

void Cprogramlisting::print_listing(Copcodes *pops)
{
  t_instrlist::iterator II;
  unsigned long         instruction;
  int                   prevaddr = -1;
  int                   prevopsz = -1;
  int                   label = 0;

  for (II = m_listing.begin(); II != m_listing.end(); II++)
    {
      if (prevaddr != -1 &&
	  prevaddr + prevopsz != (*II)->addr)
	{
	  printf("XXXXXXXXXXXXXX\n");
	}
      instruction = (*II)->opcode + ((*II)->operand << 8);
      if ((*II)->is_label())
	{
	  printf("LABEL%d:\n", label++);
	}
      pops->print_instruction((*II)->addr, instruction);
      prevaddr = (*II)->addr;
      prevopsz = pops->op_call_size((*II)->opcode);
    }
}

void Cprogramlisting::list_IO_accessed()
{
  t_instrlist::iterator II;
  int                   operand;
  
  m_bckupaccess = 0;
  for (II = m_listing.begin(); II != m_listing.end(); II++)
    {
      operand = (*II)->operand;
      if (IS_PORT_RANGE(operand))
	{
	  if (IS_PORT(operand))
	    {
	      assert(PORT2INDEX(operand) < NBIOPORTS);
	      m_IOaccesses[PORT2INDEX(operand)].push_front((*II));
	    }
	  else
	    {
	      printf("Error, unknown IO port 0x%04X used at 0x%04X\n", 
		     operand, (*II)->addr); 
	    }
	}
      else
	{
	  if (IS_BACKUP_RAM_RANGE(operand))
	    m_bckupaccess++;
	  else
	    if (IS_STACK_RANGE(operand))
	      m_stackaccess++;
	}
    }
}

bool Cprogramlisting::get_IO_accessed(bool start, t_instrlist **plist)
{
  t_instrlist::iterator II;
  static int            pind = 0;

  if (start)
      pind = 0;
  for (; pind < NBIOPORTS; pind++)
    {
      if (m_IOaccesses[pind].size())
	{
	  *plist = &(m_IOaccesses[pind]);
	  pind++;
	  return true;
	}
    }
  *plist = NULL;
  return false;
}

void Cprogramlisting::print_IO_accessed()
{
  t_instrlist::iterator II;
  int                   pind;

  printf("\n");
  for (pind = 0; pind < NBIOPORTS; pind++)
    {
      if (m_IOaccesses[pind].size())
	printf("%4d access%s to port $%04x %s.\n", (int)m_IOaccesses[pind].size(),
	       m_IOaccesses[pind].size() > 1? "es" : "  ",
	       CnesIO::m_nesios[pind].addr, CnesIO::m_nesios[pind].name);
//       for (II = m_listing.begin(); II != m_listing.end(); II++)
// 	{
// 	}
    }
  printf("\n");
  if (m_bckupaccess)
    printf("Backup ram accessed %d times.\n", m_bckupaccess);
  else
    printf("No backup ram access.\n");
  if (m_stackaccess)
    printf("Absolute accesses to the stack: %d.\n", m_stackaccess);
  else
    printf("No absolute access to the stack.\n");
}

void Cprogramlisting::list_mem_accesses(Copcodes *pops)
{
  t_instrlist::iterator II;
  int                   memaccess;

  memset(m_memaccesses, 0, sizeof(m_memaccesses));
  for (II = m_listing.begin(); II != m_listing.end(); II++)
    {
      memaccess = pops->addressing((*II)->opcode);
      assert(memaccess <= Implied);
      m_memaccesses[memaccess]++;
    }
}

void Cprogramlisting::print_mem_accesses()
{
  int                   i;

  printf("\nMemory addressing:\n");
  for (i = 0; i <= Implied; i++)
    {
      printf("   ");
      switch (i)
	{
	case Acc:
	  printf("Acc\t\t");
	  break;
	case Imm:
	  printf("Imm\t\t");
	  break;
	case PCR:
	  printf("PCR\t\t");
	  break;
	case zp:
	  printf("zp\t\t");
	  break;
	case zpX:
	  printf("zpX\t\t");
	  break;
	case zpY:
	  printf("zpY\t\t");
	  break;
	case Abs:
	  printf("Absolute\t");
	  break;
	case AbsX:
	  printf("Absolute indexed X");
	  break;
	case AbsY:
	  printf("Absolute indexed Y");
	  break;
	case Ind:
  	  printf("Indirect jmp\t\t");
	  break;
	case IndX:
	  printf("zp indirect indexed X");
	  break;
	case IndY:
	  printf("zp indirect post indexed Y");
	  break;
	case Implied:
	  printf("Implied");
	  break;
	};
      printf("\t %d\n", m_memaccesses[i]);
    }
  printf("\n");
}

Instruction6502 *Cprogramlisting::get_next(bool start)
{
  if (start)
    {
      m_listeur = m_listing.begin();
      return *m_listeur;
    }
  else
    m_listeur++;
  if (m_listeur == m_listing.end())
    return NULL;
  return *m_listeur;
}
