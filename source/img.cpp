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
#include <assert.h>
#include "img.h"

Cimage::Cimage(int resx, int resy):
  sx(resx),
  sy(resy),
  Bpp(2)
{
  sizep = resx * resy;
  sizeB = sizep * sizeof(unsigned short);
  buffer = new unsigned short[sizep];
  clear();
}

Cimage::~Cimage()
{
  if (buffer)
    {
      delete[] buffer;
      buffer = NULL;
    }
}

unsigned short &Cimage::pixel(int x, int y)
{
  assert(x >= 0 && y >= 0 && x < sx && y < sy);
  return buffer[(y * sx) + x];
}

unsigned short *Cimage::line(int y)
{
  return &buffer[y * sx];
}

void Cimage::clear()
{
  memset(buffer, 0, sizeB);
}
