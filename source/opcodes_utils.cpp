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
#include <assert.h>
#include "opcode_6502.h"
#include "opcodes.h"

bool Copcodes::is_valid(unsigned char opcode)
{
  return (m_pop2mnemonic[opcode] != 0);
}

t_ops *Copcodes::find_op(unsigned char opcode, Cmnemonic_6502 *pmnemonic)
{
  int i;

  for (i = 0; i < pmnemonic->nb_ops; i++)
    {
      if (pmnemonic->ops[i].opcode == opcode)
	return (&pmnemonic->ops[i]);
    }
  return NULL;
}

int  Copcodes::op_call_size(unsigned char opcode)
{
  t_ops *ptmpop;

  if (!is_valid(opcode))
    {
      printf("invalid opcode: $%x\n", opcode);
      return 0;
    }
  ptmpop = find_op(opcode, m_pop2mnemonic[opcode]);
  assert(ptmpop != NULL);
  return ptmpop->size_B;
}

bool Copcodes::is_mnemonic(unsigned char opcode, const char *mnemonic)
{
  return (strncmp(m_pop2mnemonic[opcode]->mnemonic, mnemonic, MNEMONIC_STR_SZ) == 0);
}

bool Copcodes::is_branch(unsigned char opcode)
{
  if (!is_valid(opcode))
    {
      printf("invalid opcode: $%x\n", opcode);
      return false;
    }
  return (m_pop2mnemonic[opcode]->category == Jump &&
          !is_mnemonic(opcode, "nop") &&
          !is_mnemonic(opcode, "rts") &&
          !is_mnemonic(opcode, "jmp") &&
          !is_mnemonic(opcode, "jsr"));
}

int Copcodes::addressing(unsigned char opcode)
{
  t_ops *ptmpop;

  if (!is_valid(opcode))
    {
      printf("invalid opcode: $%x\n", opcode);
      return -1;
    }
  ptmpop = find_op(opcode, m_pop2mnemonic[opcode]);
  assert(ptmpop != NULL);
  return ptmpop->memaccess;
}

void Copcodes::out_operand(FILE *fd, int opcode, int operand, char *label)
{
  t_ops *ptmpop;

  ptmpop = find_op(opcode, m_pop2mnemonic[opcode]);
  assert(ptmpop != NULL);
  if (label)
    {
      fprintf(fd, "%s", label);
    }
  else
    {
      switch (ptmpop->memaccess)
	{
	case Acc:
	  fprintf(fd, "A");
	  break;
	case Imm:
	  fprintf(fd, "#$%02X", operand);
	  break;
	case PCR:
	  fprintf(fd, "L$%02X", operand);
	  break;
	case zp:
	  fprintf(fd, "$%02X", operand);
	  break;
	case zpX:
	  fprintf(fd, "$%02X,X", operand);
	  break;
	case zpY:
	  fprintf(fd, "$%02X,Y", operand);
	  break;
	case Abs:
	  fprintf(fd, "$%04X", operand);
	  break;
	case AbsX:
	  fprintf(fd, "$%04X,X", operand);
	  break;
	case AbsY:
	  fprintf(fd, "$%04X,Y", operand);
	  break;
	case Ind:
	  fprintf(fd, "($%04X)", operand);
	  break;
	case IndX:
	  fprintf(fd, "($%02X,X)", operand);
	  break;
	case IndY:
	  fprintf(fd, "($%02X),Y", operand);
	  break;
	case Implied:
	  break;
	};
    }
}

void Copcodes::out_mnemonic(FILE *fd, int opcode)
{
  fprintf(fd, "%s", m_pop2mnemonic[opcode]->mnemonic);
}

void Copcodes::out_instruction(FILE *fd, int opcode, int operand, char *label)
{
  out_mnemonic(fd, opcode);
  fprintf(fd, " ");
  out_operand(fd, opcode, operand, label);
}

void Copcodes::print_instruction(int instr_addr, unsigned long instruction)
{
  unsigned char opcode = instruction & 0xFF;
  char  out[50];

  if (!is_valid(opcode))
    {
      printf("invalid opcode: $%x\n", opcode);
      return ;
    }
  printf("%4x ", instr_addr);
  out_instruction(stdout, opcode, (instruction >> 8) & 0xFFFF, NULL);
  snprintf(out, sizeof(out), "\t%s", m_pop2mnemonic[opcode]->pstr_description);
  //  while (index(out, '\n'))
  //  *index(out, '\n') = ' ';
  while (strchr(out, '\n'))
    *strchr(out, '\n') = ' ';
  printf("%s", out);
  printf("\n");
}
