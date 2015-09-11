// Creates a binary file containing the 56 nes colors + 8 unused
// coded in RGB 555 format
// This is used to convert a nes color to snes color

#include <stdio.h>

typedef struct
{
  int r;
  int g;
  int b;
}        t_rgb;

t_rgb pal[4][16];

#define IN(rv,gv,bv) p[index].r = rv; p[index].g = gv; p[index++].b = bv;

void main()
{
  t_rgb *p;
  int index;
  FILE *fp;
  int lum;
  int i;
  unsigned short rgb;
  unsigned short b[64];

  // 0x00
  p = &pal[0x00][(index = 0)];
  IN(124, 124, 124);
  IN(0, 0, 252);
  IN(0, 0, 188);
  IN(68, 40, 18);
  IN(148, 0, 132);
  IN(168, 0, 32);
  IN(168, 16, 0);
  IN(136, 20, 0);
  IN(80, 48, 0);
  IN(0, 120, 0);
  IN(0, 104, 0);
  IN(0, 88, 0);
  IN(0, 64, 88);
  IN(0, 0, 0);
  IN(0, 0, 0);
  IN(0, 0, 0);
  // 0x10
  p = &pal[0x01][(index = 0)];
  IN(188, 188, 188);
  IN(0, 120, 248);
  IN(0, 88, 248);
  IN(104, 68, 252);
  IN(216, 0, 204);
  IN(228, 0, 88);
  IN(248, 56, 0);
  IN(228, 92, 16);
  IN(172, 124, 0);
  IN(0, 184, 0);
  IN(0, 168, 0);
  IN(0, 168, 68);
  IN(0, 136, 136);
  IN(0, 0, 0);
  IN(0, 0, 0);
  IN(0, 0, 0);
  // 0x20
  p = &pal[0x02][(index = 0)];
  IN(248, 248, 248);
  IN(60, 188, 252);
  IN(104, 136, 252);
  IN(152, 120, 248);
  IN(248, 120, 248);
  IN(248, 88, 152);
  IN(248, 120, 88);
  IN(252, 160, 68);
  IN(248, 184, 0);
  IN(184, 248, 24);
  IN(88, 216, 84);
  IN(88, 248, 152);
  IN(0, 232, 216);
  IN(120, 120, 120);
  IN(0, 0, 0);
  IN(0, 0, 0);
  // 0x30
  p = &pal[0x03][(index = 0)];
  IN(252, 252, 252);
  IN(164, 228, 252);
  IN(184, 184, 248);
  IN(216, 184, 248);
  IN(248, 184, 248);
  IN(248, 164, 192);
  IN(240, 208, 176);
  IN(252, 224, 168);
  IN(248, 216, 120);
  IN(216, 248, 120);
  IN(184, 248, 184);
  IN(184, 248, 216);
  IN(0, 252, 252);
  IN(216, 216, 216);
  IN(0, 0, 0);
  IN(0, 0, 0);
  fp = fopen("palette.dat", "w");
  if (fp == NULL)
    return ;
  for (lum = 0, index = 0; lum < 4; lum++)
    for (i = 0; i < 0x10; i++)
      {
	// -bbb bbgg gggr rrr
	rgb = pal[lum][i].b >> 3;
	rgb = rgb << 5;
	rgb |= pal[lum][i].g >> 3;
	rgb = rgb << 5;
	rgb |= pal[lum][i].r >> 3;
	b[index++] = rgb;
      }
  fwrite(&b, 128, 1, fp);
  fclose(fp);
}

