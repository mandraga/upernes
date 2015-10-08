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

#include <string.h>
#include <stdio.h>
#include <unistd.h>
#include <assert.h>
#include "opcode_6502.h"
#include "opcodes.h"
#include "rom_file.h"
#include "mapper.h"
#include "cpu6502.h"
#include "nes.h"
#include "instruction6502.h"
#include "indirectJmp.h"
#include "img.h"
#include "Ivideo.h"
#include "disasm.h"

#define BASE_ADDR  m_mapper.prgbase()

Cdisasm::Cdisasm():
  JUMP_stack(NULL),
  JUMP_stack_sz(0),
  pexplore(NULL),
  m_cur_addr(0),
  m_instr_addr(0),
  m_img(256, 256)
{
}

Cdisasm::~Cdisasm()
{
  if (pexplore)
    delete[] pexplore;
  if (JUMP_stack)
    delete[] JUMP_stack;
}

int Cdisasm::init(Crom_file *prom)
{
  assert(prom);
  JUMP_stack_sz = 0;
  JUMP_stack = new unsigned short[3 * prom->m_PRG_size];
  pexplore = new char[prom->m_PRG_size];
  memset(pexplore, 0, prom->m_PRG_size);
  m_mapper.init(prom);
  return 0;
}

int Cdisasm::next_jump_in_stack()
{
  if (JUMP_stack_sz > 0)
    {
      m_cur_addr = JUMP_stack[--JUMP_stack_sz];
      return 1;
    }
  else
    return 0;  
}

unsigned int Cdisasm::cpu2prg(unsigned int addr)
{
  return m_mapper.cpu2prg(addr);
}

unsigned int Cdisasm::get_routine_addr(unsigned int addr, Crom_file *prom)
{
  addr = prom->m_pPRG[cpu2prg(addr)] + (prom->m_pPRG[cpu2prg(addr + 1)] << 8);
  return (addr);
}

void Cdisasm::add_known_branches(int cur_addr, unsigned int operand, CindirectJmpRuntimeLabels *pindjmp)
{
  bool         first;
  unsigned int addr;

  // Here the branch address is unknown until execution but add the known addresses from the configuration file.
  first = true;
  while (pindjmp->next_op_address(first, operand, &addr))
    {
      first = false;
      if (addr < BASE_ADDR)
	{
	  // FIXME move this to the config file read function
	  printf("Error: an indirect jump goes to ram at 0x%x!\n", m_cur_addr);
	  assert(false);
	}
      m_listing.insert_branch(cur_addr, addr);
    }
}

int Cdisasm::get_next_instruction(unsigned long *instruction,
				  Copcodes *pops, Crom_file *prom,
				  CindirectJmpRuntimeLabels *pindjmp)
{
  unsigned char opcode;
  int           opsz;
  int           i;
  int           operand;
  unsigned int  addr;
  unsigned int  ind_addr;

  if (m_cur_addr < (int)BASE_ADDR || m_cur_addr >= 0xFFFF)
    {
      printf("program address out of PRG rom at 0x%x %d\n", m_cur_addr, m_cur_addr);
      return unrecerror;
    }
  opcode = prom->m_pPRG[cpu2prg(m_cur_addr)];
  if (!pops->is_valid(opcode))
    {
      *instruction = opcode;
      return invalidopcode;
    }
  if (pexplore[cpu2prg(m_cur_addr)] != 0)
    {
      return (JUMP_stack_sz > 0? alreadyread : stopdisasm);
    }
  // Find instruction size
  opsz = pops->op_call_size(opcode);
  // Get next bytes of this instruction
  for (*instruction = 0, i = 0; i < opsz; i++)
    {
      addr = cpu2prg(m_cur_addr + i);
      *instruction |= prom->m_pPRG[addr] << (i * 8);
      // "Teinte" ce qui est parcouru
      pexplore[addr] = 1;
      m_img.pixel(addr % 256, addr / 256) = m_color;
    }
  operand = ((*instruction) >> 8) & 0xFFFF;
  m_instr_addr = m_cur_addr;
  m_listing.insert(opcode, operand, m_instr_addr);
  // Test for the case of a JUMP or increment program address
  if (pops->is_mnemonic(opcode, "jmp"))
    {
      addr = operand;
      if (opcode == 0x4C) // absolute jump
	{
	  // check if the address goes to ram
	  if (addr < BASE_ADDR)
	    {
	      printf("jump goes to out of prg at 0x%x\n", m_cur_addr);
	      return unrecerror;
	    }
	  JUMP_stack[JUMP_stack_sz++] = addr;
	  m_listing.insert_branch(m_cur_addr, addr);
	}
      else
	{
	  // indirect jump
	  if (addr < BASE_ADDR)
	    {
	      printf("At 0x%04X: indirect jump reads @ in ram at 0x%X\n", m_instr_addr, addr);
	      pindjmp->addjmpoperand(addr, true); // Add it to the indirect jump list
	      add_known_branches(m_cur_addr, operand, pindjmp); // Add the already known branches to the listing
	      return unrecerror;
	    }
	  else
	    {
	      fprintf(stderr, "Warning: improbable/strange indirect jump at 0x%04X!\n", addr);
	      sleep(4);
	      ind_addr = prom->m_pPRG[cpu2prg(addr)];
	      ind_addr += prom->m_pPRG[cpu2prg(addr + 1)] << 8;
	      addr = ind_addr;
	      if (addr < BASE_ADDR)
		{
		  printf("Error: indirect jump with @ in rom goes to ram at 0x%x\n", m_cur_addr);
		  return unrecerror;
		}
	      else
		{
		  // Indirect jump from an address stored in rom to code address in rom, equivalent to a static jump
		  // Pushed on the jump stack
		  JUMP_stack[JUMP_stack_sz++] = addr;
		  m_listing.insert_branch(m_cur_addr, addr);
		  printf("Indirect jump using rom\n");
		}
	    }

	}
      // Follow the jump
      assert(next_jump_in_stack() != 0);
      return jumpto;
    }
  else
    {
      // Relative branch +-128Bytes
      if (pops->is_branch(opcode))
	{
	  ind_addr = m_cur_addr + 2;
	  // the relative address is a signed byte
	  addr = ind_addr + ((signed char)(operand & 0xFF));
	  JUMP_stack[JUMP_stack_sz++] = addr;
	  m_listing.insert_branch(m_cur_addr, addr);
	}
      else
	if (pops->is_mnemonic(opcode, "jsr"))
	  {
	    // Put the subroutine address on the stack
	    addr = operand;
	    JUMP_stack[JUMP_stack_sz++] = addr;
	    m_listing.insert_branch(m_cur_addr, addr);
	  }
	else
	  if (pops->is_mnemonic(opcode, "rts") ||
	      pops->is_mnemonic(opcode, "rti"))
	    {
	      // Return from subroutine, do not go past this instruction
	      // Try a previous branch if present
	      return newinstruction;
	    }
    }
  // Prochaine instruction
  if (m_cur_addr > 0xFFFF - opsz)
    {
      printf("address pointer reached the end of the PRG rom\n");
      return stopdisasm;
    }
  m_cur_addr += opsz;
  return newinstruction;
}

int Cdisasm::disasm_vector(Copcodes *pops, Crom_file *prom,
			   int addr, const char *vector_name,
			    CindirectJmpRuntimeLabels *pindjmp)
{
  return (disasm_addr(pops, prom, get_routine_addr(addr, prom), vector_name, pindjmp));
}

int Cdisasm::disasm_addr(Copcodes *pops, Crom_file *prom,
			 int addr, const char *addr_name,
			 CindirectJmpRuntimeLabels *pindjmp)
{
  int ret;
  unsigned long instruction;
  
  m_cur_addr = addr;
  printf("\nDisassembling %s at 0x%x:\n", addr_name, addr);
  while ((ret = get_next_instruction(&instruction, pops, prom, pindjmp)) != stopdisasm)
    {
      switch (ret)
	{
	case unrecerror:
	  pops->print_instruction(m_instr_addr, instruction);
	  if (next_jump_in_stack() == 0)
	    return 1;
	  break;
	case newinstruction:
	  pops->print_instruction(m_instr_addr, instruction); 
	  break;
	case jumpto:
	  	  pops->print_instruction(m_instr_addr, instruction);
	  //printf("\n");
	  break;
	case alreadyread:
	  printf("%x already covered\n", m_cur_addr);
	  if (next_jump_in_stack() == 0)
	    return 1;
	  break;
	case invalidopcode:
	  printf("invalid opcode $%x at 0x%04x\n", (unsigned int)instruction & 0xFF, m_cur_addr);
	  if (next_jump_in_stack() == 0)
	    return 1;
	  break;
	};
#if 0
      copy_to_bitmap(&m_img, 30, 30);
      update_screen();
#endif
    }
  printf("Disassembling finished\n");
  return 0;
}

int Cdisasm::disasm(Copcodes *pops, Crom_file *prom, CindirectJmpRuntimeLabels *pindjmp)
{
  bool          first;
  unsigned int  addr;
  unsigned int  operand;

  m_color = 0xFE12;
  if (disasm_vector(pops, prom, VECTOR_ADDR_RESET, "RESET", pindjmp))
    {    
      printf("critical error disassembling the interrupt vector\n");
    }
  m_color = 0xF800;
  if (disasm_vector(pops, prom, VECTOR_ADDR_NMI, "NMI", pindjmp))
    {    
      printf("critical error disassembling the interrupt vector\n");
    }
  m_color = 0x001F;
  if (disasm_vector(pops, prom, VECTOR_ADDR_IRQ_BRK, "IRQBRK", pindjmp))
    {    
      printf("critical error disassembling the interrupt vector\n");
    }
  // Disassembles runtime indirect addresses
  m_color = 0x0780;
  first = true;
  while (pindjmp->next_address(first, &addr, &operand))
    {
      first = false;
      if (disasm_addr(pops, prom, addr, "Extra indirect address", pindjmp))
	{
	  printf("critical error disassembling the procedure\n");
	}
        m_color += 0x61C4;
    }
  // 0xC3BF, 0xC3ed, 0xC434, 0xC455
  if (pindjmp->update_indjump_file(prom))
    {
      printf("Error: %s\n", pindjmp->m_error_str);
      return 1;
    }

  copy_to_bitmap(&m_img, 30, 30);
  update_screen();
  //m_listing.print_listing(pops);
  m_listing.list_IO_accessed();
  m_listing.print_IO_accessed();
  m_listing.list_mem_accesses(pops);
  m_listing.print_mem_accesses();

  sleep(2);
  return 0;
}

Cprogramlisting *Cdisasm::getlisting()
{
  return &m_listing;
}
