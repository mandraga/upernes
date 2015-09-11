
#include <stdio.h>
#include <string.h>
#include <assert.h>
#include "img.h"
#include "video/video.h"
#include "Ivideo.h"

Cvideodef *g_pvideout = NULL;
Cimage *pscr = NULL;

Ivideo::Ivideo()
{
}

Ivideo::~Ivideo()
{
}

int Ivideo::init_video(int resolutionx, int resolutiony)
{
  assert (g_pvideout == NULL || pscr == NULL);
  g_pvideout = new Cvideodef();
  pscr = new Cimage(resolutionx, resolutiony);
  return g_pvideout->init_video(resolutionx, resolutiony);
}

int Ivideo::free_video()
{
  assert(g_pvideout != NULL && pscr != NULL);
  delete g_pvideout;
  g_pvideout = NULL;
  delete pscr;
  pscr = NULL;
  return 0;
}

void Ivideo::clear()
{
  pscr->clear();
  //g_pvideout->clear();
}

int Ivideo::copy_to_bitmap(Cimage *pimg, int xpos, int ypos)
{
  int   j;
  int   sz;
  unsigned short *ppixel;
  unsigned short *pout;

  assert(pscr != NULL && pimg != NULL);
  if (xpos < 0 ||
      pimg->sx > (int)pscr->sx ||
      ypos < 0 ||
      pimg->sy > (int)pscr->sy)
    {
      printf("Warning: image copy out of the window\n");
      return 1;
    }
  for (j = 0; j < pimg->sy && ypos + j < pscr->sy; j++)
    {
      ppixel = pimg->line(j);
      pout   = pscr->line(ypos + j);
      sz = xpos + pimg->sx > pscr->sx? pscr->sx : xpos + pimg->sx;
      sz -= xpos;
      memcpy(&pout[sz], ppixel, sz * sizeof(unsigned short));
    }
  return 0;
}

int Ivideo::update_screen()
{
  assert(g_pvideout != NULL && pscr != NULL);
  g_pvideout->copy_to_screen(pscr);
  return 0;
}
