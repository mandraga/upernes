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

#include <stdio.h> // FIXME remove from here
#include <string.h>
#include "assert.h"
#include "opcode_6502.h"
#include "opcodes.h"
#include "parse_codes.h"
#include "parser.h"

// Utilise lex seul pour récupérer les éléments de texte
extern FILE *yyin;
extern char *yytext;
extern int  yyleng;
extern int  num_line;
extern unsigned char Bflags;

extern "C" {
int yylex(void);
}

#define CMP_MEMUSE_STR(s) (strlen(yytext) == strlen(s) && strncmp(yytext, s, strlen(s)) == 0)

Cparser::Cparser():
  m_state(get_new_element),
  m_current_op_category(-1),
  m_ptmpmnemo(NULL)
{
  strcpy(m_error_str, "");
}

Cparser::~Cparser()
{
}

int Cparser::open_data(char *file_name)
{
  yyin = fopen(file_name, "r");
  if (yyin == NULL)
    {
      snprintf(m_error_str, sizeof(m_error_str), "open file %s", file_name);
      return 1;
    }
  return 0;
}

int Cparser::close_data()
{
  if (yyin == NULL)
    {
      snprintf(m_error_str, sizeof(m_error_str), "file already closed");
      return 1;
    }
  if (fclose(yyin) != 0)
    {
      snprintf(m_error_str, sizeof(m_error_str), "could not close file");
      return 1;
    }
  yyin = NULL;
  return 0;
}

void Cparser::get_new(int res)
{
  switch (res)
    {
    case COMMENT:
    case EOL:
      break;
    case ARITHMETIC:
      m_current_op_category = Arithmetic;
      break;
    case LOGIC:
      m_current_op_category = Logic;
      break;
    case MOVE:
      m_current_op_category = Move;
      break;
    case STACK:
      m_current_op_category = Stack;
      break;
    case FLAGS:
      m_current_op_category = Flags;
      break;
    case JUMP:
      m_current_op_category = Jump;
      break;
    case INTERRUPT:
      m_current_op_category = Interrupts;
      break;
    case OPCODEDEF:
      if (m_current_op_category == -1)
	{
	  snprintf(m_error_str, sizeof(m_error_str), "parser line %d, no op type", num_line);
	  throw (1);
	}
      m_state = opcode_element;
      break;
    default:
      snprintf(m_error_str, sizeof(m_error_str), "parser line %d, no op type", num_line);
      throw (1);
    };
}

void Cparser::get_opcode(int res)
{
  switch (res)
    {
    case OPCODESTR:
      m_ptmpmnemo = new Cmnemonic_6502();
      strncpy(m_ptmpmnemo->mnemonic, yytext, 3);
      m_ptmpmnemo->category = m_current_op_category;
      m_state = opcode_memuse_line;
      break;
    default:
      snprintf(m_error_str, sizeof(m_error_str), "parser line %d expects mnemonic", num_line);
      throw (1);
    };
}

void Cparser::get_memuse_line(int res)
{
  int curop;

  switch (res)
    {
    case MEMUSE:
      curop = m_ptmpmnemo->nb_ops;
      m_ptmpmnemo->ops[curop].memaccess = -1;
      if (CMP_MEMUSE_STR("Implied"))
	  m_ptmpmnemo->ops[curop].memaccess = Implied;
      if (CMP_MEMUSE_STR("Acc"))
	  m_ptmpmnemo->ops[curop].memaccess = Acc;
      if (CMP_MEMUSE_STR("Imm"))
	  m_ptmpmnemo->ops[curop].memaccess = Imm;
      if (CMP_MEMUSE_STR("PCR"))
	  m_ptmpmnemo->ops[curop].memaccess = PCR;
      if (CMP_MEMUSE_STR("zp"))
	  m_ptmpmnemo->ops[curop].memaccess = zp;
      if (CMP_MEMUSE_STR("zpX"))
	  m_ptmpmnemo->ops[curop].memaccess = zpX;
      if (CMP_MEMUSE_STR("zpY"))
	  m_ptmpmnemo->ops[curop].memaccess = zpY;
      if (CMP_MEMUSE_STR("Abs"))
	  m_ptmpmnemo->ops[curop].memaccess = Abs;
      if (CMP_MEMUSE_STR("AbsX"))
	  m_ptmpmnemo->ops[curop].memaccess = AbsX;
      if (CMP_MEMUSE_STR("AbsY"))
	  m_ptmpmnemo->ops[curop].memaccess = AbsY;
      if (CMP_MEMUSE_STR("Ind"))
	  m_ptmpmnemo->ops[curop].memaccess = Ind;
      if (CMP_MEMUSE_STR("IndX"))
	  m_ptmpmnemo->ops[curop].memaccess = IndX;
      if (CMP_MEMUSE_STR("IndY"))
	  m_ptmpmnemo->ops[curop].memaccess = IndY;
      if (m_ptmpmnemo->ops[curop].memaccess == -1)
	{
	snprintf(m_error_str, sizeof(m_error_str), "parser line %d wrong mem access", num_line);
	throw (1);
	}
      m_state = opcode_memuse_call;
      break;
    default:
      snprintf(m_error_str, sizeof(m_error_str), "parser line %d expects Acc or Imm, zp, Abs...", num_line);
      throw (1);
    };
}

void Cparser::get_call_str(int res)
{
  int curop;

  switch (res)
    {
    case OPSTR:
      curop = m_ptmpmnemo->nb_ops;
      strncpy(m_ptmpmnemo->ops[curop].pstr_call, yytext, sizeof(m_ptmpmnemo->ops[0].pstr_call));
      m_state = opcode_memuse_code;
      break;
    default:
      snprintf(m_error_str, sizeof(m_error_str), "parser line %d OPCODESTR expected", num_line);
      throw (1);
    };
}

void Cparser::get_op_code(int res)
{
  int          curop;
  unsigned int out;

  switch (res)
    {
    case BYTE:
      curop = m_ptmpmnemo->nb_ops;
      sscanf(yytext + 1,"%x", &out);
      m_ptmpmnemo->ops[curop].opcode = (unsigned char)out;
      m_state = opcode_memuse_size;
      break;
    default:
      snprintf(m_error_str, sizeof(m_error_str), "parser line %d expects operation hexadecimal code", num_line);
      throw (1);
    };
}

void Cparser::get_opcall_size(int res)
{
  int          curop;

  switch (res)
    {
    case NUMBER:
      curop = m_ptmpmnemo->nb_ops;
      sscanf(yytext,"%d", &m_ptmpmnemo->ops[curop].size_B);
      m_state = opcode_memuse_cycles;
      break;
    default:
      snprintf(m_error_str, sizeof(m_error_str), "parser line %d expects opcode size", num_line);
      throw (1);
    };
}

void Cparser::get_opcode_cycles(int res)
{
  int          curop;

  switch (res)
    {
    case NUMBER:
      curop = m_ptmpmnemo->nb_ops;
      strncpy(m_ptmpmnemo->ops[curop].cycles, yytext, CYCLE_STR_SZ);
      break;
    case EOL:
      m_ptmpmnemo->nb_ops++; // Next opcode variant can follow
      m_state = opcode_memuse_next;
      break;
    default:
      snprintf(m_error_str, sizeof(m_error_str), "parser line %d expects opcode cycles number", num_line);
      throw (1);
    };
}

void  Cparser::memuse_next_state(int res)
{
  switch (res)
    {
    case FLAGS:
      m_state = opcode_flags;
      break;
    case DESCRIPTION:
      m_state = opcode_description;
      break;
    case MEMUSE:
      get_memuse_line(res);
      break;
    default:
      snprintf(m_error_str, sizeof(m_error_str), "parser line %d unexpected token", num_line);
      throw (1);
      break;
    };
}

void  Cparser::get_active_flags(int res)
{
  switch (res)
    {
    case EOL:
      m_ptmpmnemo->Flags = Bflags;
      break;
    case DESCRIPTION:
      m_state = opcode_description;
      break;
    default:
      snprintf(m_error_str, sizeof(m_error_str), "parser line %d expected flags or description", num_line);
      throw (1);
    };
}

void  Cparser::get_description(int res, Cmnemonic_6502 **pmnemo_6502, int *nb_mnemonics)
{
  switch (res)
    {
    case DESCRIPTION_TXT:
      strncpy(m_ptmpmnemo->pstr_description, yytext, sizeof(m_ptmpmnemo->pstr_description));
      pmnemo_6502[*nb_mnemonics] = m_ptmpmnemo; // Add the mnemonic to the list
      (*nb_mnemonics)++;
      m_ptmpmnemo = NULL;
      assert(*nb_mnemonics < 256);
      m_state = get_new_element;
      break;
    default:
      snprintf(m_error_str, sizeof(m_error_str), "parser line %d expected description text+\\n", num_line);
      throw 1;
    };
}

int  Cparser::build_list(Cmnemonic_6502 **pmnemo_6502, int *nb_mnemonics)
{
  int res;

  num_line = 1;
  try
    {
      while ((res = yylex()) != 0)
	{
	  switch (m_state)
	    {
	    case get_new_element:
	      get_new(res);
	      break;
	    case opcode_element:
	      get_opcode(res);
	      break;
	    case opcode_memuse_line:
	      get_memuse_line(res);
	      break;
	    case opcode_memuse_call:
	      get_call_str(res);
	      break;
	    case  opcode_memuse_code:
	      get_op_code(res);
	      break;
	    case opcode_memuse_size:
	      get_opcall_size(res);
	      break;
	    case opcode_memuse_cycles:
	      get_opcode_cycles(res);
	      break;
	    case opcode_memuse_next:
	      memuse_next_state(res);
	      break;
	    case opcode_flags:
	      get_active_flags(res);
	      break;
	    case opcode_description:
	      get_description(res, pmnemo_6502, nb_mnemonics);
		break;
	    };
	}
    }
  catch (int e)
    {
      return 1;
    }
  return 0;
}

