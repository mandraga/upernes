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

// Opens the file containing the opcode description and puts them in a file.
//
#include <string.h>
#include <stdio.h>
#include "opcode_6502.h"
#include "opcodes.h"
#include "parser.h"
//#include "file_io.h"

Copcodes::Copcodes():
	m_nb_mnemonics(0)
{
  // Set every pointer to NULL
  memset(m_pmnemonics_6502, 0, sizeof(Cmnemonic_6502));
  memset(m_pop2mnemonic, 0, sizeof(m_pop2mnemonic));
}

Copcodes::~Copcodes()
{
  while (m_nb_mnemonics > 0)
      delete m_pmnemonics_6502[--m_nb_mnemonics];
}

int Copcodes::fill_structure(char *file_path)
{
  Cparser parser;
  int     ret = 0;

  // Call the parser
  if (parser.open_data(file_path))
    {
      printf("Error: %s\n", parser.m_error_str);
      ret = 1;
    }
  else
    {
      if (parser.build_list(m_pmnemonics_6502, &m_nb_mnemonics))
	{
	  printf("Error: %s\n", parser.m_error_str);
	  ret = 2;
	}
      else
	{
	  if (build_search_table())
	    ret = 3;
	}
      parser.close_data();
    }
  return (ret);
}

int Copcodes::build_search_table()
{
  int i, y;
  Cmnemonic_6502  *pmnem;

  if (check_mnemonic_number())
    return 1;
  for (i = 0; i < m_nb_mnemonics; i++)
    {
      pmnem = m_pmnemonics_6502[i];
      for (y = 0; y < pmnem->nb_ops; y++)
	{
	  if (m_pop2mnemonic[pmnem->ops[y].opcode] != 0)
	    {
	      printf("Error: double opcode $%x\n", pmnem->ops[y].opcode);
	      return 1;
	    }
	  m_pop2mnemonic[pmnem->ops[y].opcode] = m_pmnemonics_6502[i];
	}
    }
  return 0;
}

bool Copcodes::check_mnemonic_number()
{
  if (m_nb_mnemonics != NBMNEMONICS)
    {
      printf("Wrong number of mnemonics %d, expects %d\n", m_nb_mnemonics, NBMNEMONICS);
      return true;
    }
  return false;
}

void Copcodes::print_category(int category)
{
  switch (category)
    {
    case Arithmetic:
      printf("Arithmetic");
      break;
    case Logic:
      printf("Logic");
      break;
    case Move:
      printf("Move");
      break;
    case Stack:
      printf("Stack");
      break;
    case Jump:
      printf("Jump");
      break;
    case Flags:
      printf("Flags");
      break;
    case Interrupts:
      printf("Interrupts");
      break;
    default:
      printf("Warning: unknown mnemonic category");
    };
}

void Copcodes::print_flags(unsigned char Flags)
{
  char flagstr[32];
  int  i;

  strcpy(flagstr, "C Z I D B S V N");
  for (i = 0; i < 8; i++)
    if ((Flags & (1 << i)) == 0)
      flagstr[2 * i] = ' '; // lettre remplacée par un espace
  printf("Flags: %s\n", flagstr);
}

void Copcodes::print_list()
{
  int i;
  Cmnemonic_6502  *pmnem;

  for (i = 0; i < m_nb_mnemonics; i++)
    {
      pmnem = m_pmnemonics_6502[i];
      print_category(pmnem->category);
      printf(": \n%s\n", pmnem->mnemonic);
      print_flags(pmnem->Flags);
      printf("Desciption: %s\n\n", pmnem->pstr_description);
    }
}
