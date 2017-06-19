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

// Calls the second flex parser (zzlex), to read the indirect addresses list from a file

#include <stdio.h>
#include <string.h>
#include <list>
#include <assert.h>

#include "rom_file.h"
#include "indirectJmp.h"
#include "parse_codes.h"

extern FILE *zzin;
extern char *zztext;
extern int   zzleng;
extern int   zznum_line;

extern "C" {
int zzlex(void);
}


int CindirectJmpRuntimeLabels::open_data(char *file_name)
{
  zzin = fopen(file_name, "r");
  if (zzin == NULL)
    {
      snprintf(m_error_str, sizeof(m_error_str), "no config file %s", file_name);
      return 1;
    }
  return 0;
}

int CindirectJmpRuntimeLabels::close_data()
{
  if (zzin == NULL)
    {
      snprintf(m_error_str, sizeof(m_error_str), "file already closed");
      return 1;
    }
  if (fclose(zzin) != 0)
    {
      snprintf(m_error_str, sizeof(m_error_str), "could not close file");
      return 1;
    }
  zzin = NULL;
  return 0;
}

int CindirectJmpRuntimeLabels::list_add_jopaddr(unsigned int jopaddr)
{
  if (addjmpoperand(jopaddr, false))
    {
      snprintf(m_error_str, sizeof(m_error_str),
	       "indirect jump $%02X already in the list", jopaddr);
      return 1;      
    }
  m_Ijopaddr = m_jmplist.begin();
  return 0;
}

void CindirectJmpRuntimeLabels::add_addr(unsigned int addr)
{
  t_indirjmp elt;

  assert(m_currentjopaddr >= 0); // direct page address where the 16bit address is stored
  assert((*m_Ijopaddr).jopaddr == m_currentjopaddr);
  (*m_Ijopaddr).addrlist.push_front(addr);
}

void CindirectJmpRuntimeLabels::get_new(int res)
{
  switch (res)
    {
    case COMMENT:
    case EOL:
      break;
    case CRC:
      m_state = get_crc;
      break;
    case JUMP:
      m_state = jumpaddr_var;
      break;
    case DISJUMP:
      m_bDisableIndJumpPatching = true;
      break;
    case ADDR:
      m_state = jumpaddr_addr;
      break;
    default:
      snprintf(m_error_str, sizeof(m_error_str), "parser line %d, unknown text", zznum_line);
      throw (1);
    };
}

void CindirectJmpRuntimeLabels::get_32b_crc(int res)
{
  unsigned int out;

  switch (res)
    {
    case DWORD:
      sscanf(zztext + 1,"%x", &out);
      m_crc = out;
      m_state = get_new_line;
      break;
    default:
      snprintf(m_error_str, sizeof(m_error_str),
	       "parser line %d expects $hex dword", zznum_line);
      throw (1);
    };
}

void CindirectJmpRuntimeLabels::get_8b_addr(int res)
{
  unsigned int out;

  switch (res)
    {
    case BYTE:
      sscanf(zztext + 1,"%x", &out);
      m_currentjopaddr = out;
      if (list_add_jopaddr(m_currentjopaddr))
	throw (1);
      m_state = get_new_line;
      break;
    default:
      snprintf(m_error_str, sizeof(m_error_str),
	       "parser line %d expects $hex byte", zznum_line);
      throw (1);
    };  
}

void CindirectJmpRuntimeLabels::get_16b_addr(int res)
{
  unsigned int out;

  switch (res)
    {
    case WORD:
      sscanf(zztext + 1,"%x", &out);
      // Add the addr to the list
      add_addr(out);
      m_state = get_new_line;
      break;
    default:
      snprintf(m_error_str, sizeof(m_error_str),
	       "parser line %d expects $hex word", zznum_line);
      throw (1);
    };
}

int  CindirectJmpRuntimeLabels::build_list()
{
  int res;

  zznum_line = 1;
  try
    {
      while ((res = zzlex()) != 0)
	{
	  switch (m_state)
	    {
	    case get_new_line:
	      get_new(res);
	      break;
	    case get_crc:
	      get_32b_crc(res);
	      break;
	    case jumpaddr_var:
	      get_8b_addr(res);
	      break;
	    case jumpaddr_addr:
	      get_16b_addr(res);
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
