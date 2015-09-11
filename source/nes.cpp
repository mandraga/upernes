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

#include <assert.h>
//#include <stdio.h>
#include <string.h>
#include "nes.h"

t_nesioport CnesIO::m_nesios[] = {
  {0x2000, "PPUC1"},
  {0x2001, "PPUC2"},
  {0x2002, "PPUSTATUS"},
  {0x2003, "SPRADDR"},
  {0x2004, "SPRDATA"},
  {0x2005, "SCROLOFFSET"},
  {0x2006, "PPUMEMADDR"},
  {0x2007, "PPUMEMDATA"},
  {0x4000, "SNDSQR1CTRL"},
  {0x4001, "SNDSQR1E"},
  {0x4002, "SNDSQR1PERIOD"},
  {0x4003, "SNDSQR1LENPH"},
  {0x4004, "SNDSQR2CTRL"},
  {0x4005, "SNDSQR2E"},
  {0x4006, "SNDSQR2PERIOD"},
  {0x4007, "SNDSQR2LENPH"},
  {0x4008, "SNDTRIACTRL"},
  {0x4009, "NOTUSED"},         // $4009 unused
  {0x400A, "SNDTRIAPERIOD"},
  {0x400B, "SNDTRIALENPH"},
  {0x400C, "SNDNOISECTRL"},
  {0x400D, "NOTUSED"},         // $400D unused
  {0x400E, "SNDNOISESHM"},
  {0x400F, "SNDNOISELEN"},
  {0x4010, "SNDDMCCTRL"},
  {0x4011, "SNDDMCDAC"},
  {0x4012, "SNDDMCSADDR"},
  {0x4013, "SNDDMCSLEN"},
  {0x4014, "DMASPRITEMEMACCESS"},
  {0x4015, "SNDCHANSWITCH"},
  {0X4016, "JOYSTICK1"},
  {0X4017, "JOYSTICK2_SNDSEQUENCER"}};

bool CnesIO::isio(int addr)
{
  int i;

  assert(sizeof(m_nesios) / sizeof(t_nesioport) == 32);
  for (i = 0; i < (int)(sizeof(m_nesios) / sizeof(t_nesioport)); i++)
    {
      if (m_nesios[i].addr == addr)
	return true;
    }
  return false;
}

const char *CnesIO::getioname(int addr)
{
  int i;

  assert(sizeof(m_nesios) / sizeof(t_nesioport) == 32);
  for (i = 0; i < (int)(sizeof(m_nesios) / sizeof(t_nesioport)); i++)
    {
      if (m_nesios[i].addr == addr)
	return m_nesios[i].name;
    }
  return NULL;
}


/* CPU memory map
--------------------------------------- $10000
 Upper Bank of Cartridge ROM
--------------------------------------- $C000
 Lower Bank of Cartridge ROM
--------------------------------------- $8000
 Cartridge RAM (may be battery-backed)
--------------------------------------- $6000
 Expansion Modules
--------------------------------------- $5000
 Input/Output
--------------------------------------- $2000
 2kB Internal RAM, mirrored 4 times
--------------------------------------- $0000
*/

/* PPU memory map
--------------------------------------- $4000
 Empty
--------------------------------------- $3F20
 Sprite Palette
--------------------------------------- $3F10
 Image Palette
--------------------------------------- $3F00
 Empty
--------------------------------------- $3000
 Attribute Table 3
--------------------------------------- $2FC0
 Name Table 3 (32x30 tiles)
--------------------------------------- $2C00
 Attribute Table 2
--------------------------------------- $2BC0
 Name Table 2 (32x30 tiles)
--------------------------------------- $2800
 Attribute Table 1
--------------------------------------- $27C0
 Name Table 1 (32x30 tiles)
--------------------------------------- $2400
 Attribute Table 0
--------------------------------------- $23C0
 Name Table 0 (32x30 tiles)
--------------------------------------- $2000
 Pattern Table 1 (256x2x8, may be VROM)
--------------------------------------- $1000
 Pattern Table 0 (256x2x8, may be VROM)
--------------------------------------- $0000
*/

/* Sprite memory map
--------------------------------------- $0000
 Sprite attributes (256 Bytes, 63 x 4Bytes)
*/
