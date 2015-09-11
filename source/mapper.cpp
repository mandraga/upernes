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
#include "rom_file.h"
#include "mapper.h"

Cmapper::Cmapper()
{
}

void Cmapper::init(Crom_file *prom)
{
  assert((prom->m_PRG_size % PRG_BANK_SIZE) == 0);
  if (prom->m_PRG_size >= (BANKSIZE / 2))
    // PRG starts at 0x8000
    m_cprgbase = BANKSIZE / 2;
  else
    // PRG starts at 0xC000, last 16KB
    m_cprgbase = BANKSIZE - prom->m_PRG_size;
  assert((m_cprgbase >= (BANKSIZE / 2)) && m_cprgbase < BANKSIZE);
}

int Cmapper::cpu2prg(int address)
{
  int ret;

  ret = address - m_cprgbase;
  assert(ret >= 0 && ret < BANKSIZE);
  return (ret);
}

unsigned int Cmapper::prgbase()
{
  return m_cprgbase;
}
