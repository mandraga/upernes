
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
