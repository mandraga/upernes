/*****************************************************************************************
* Video buffer implementation                                                            *
*****************************************************************************************/

#include "SDL/SDL.h"

#include "../img.h"
#include "video.h"

SDL_Surface *g_screen;

/*************************************************************
* Constructions.                                             *
*************************************************************/

Cvideodef::Cvideodef()
{
}

Cvideodef::~Cvideodef()
{
  quit_video();
}

/*************************************************************
* Fonctions.                                                 *
*************************************************************/

int Cvideodef::init_video(int resolutionx, int resolutiony)
{
  t_video_defs *pvideo_defs;

  pvideo_defs = &video_defs;
  /* Initialisation de la librairie vidéo */
  if (SDL_Init(SDL_INIT_VIDEO) < 0)
  {
    printf("Unable to init SDL: %s\n", SDL_GetError());
    return 1;
  }
  /* Initialisation du mode vidéo */
  pvideo_defs->x_size = resolutionx;
  pvideo_defs->y_size = resolutiony;
  g_screen = SDL_SetVideoMode(pvideo_defs->x_size, pvideo_defs->y_size, 16, SDL_HWSURFACE | SDL_DOUBLEBUF);
  if (g_screen == NULL)
  {
    printf("Unable to set %dx%d video: %s\n", (int)pvideo_defs->x_size, (int)pvideo_defs->y_size, SDL_GetError());
    return 1;
  }
  pvideo_defs->bytes_per_pixel = 2;
  pvideo_defs->total_pix_size = pvideo_defs->x_size * pvideo_defs->y_size;
  pvideo_defs->byte_size = pvideo_defs->total_pix_size * pvideo_defs->bytes_per_pixel;
  return(0);
}

void Cvideodef::quit_video()
{
  if (g_screen != NULL)
  SDL_Quit();
}

void Slock(SDL_Surface *screen)
{
  if ( SDL_MUSTLOCK(screen) )
  {
    if ( SDL_LockSurface(screen) < 0 )
    {
      return;
    }
  }
}

void Sulock(SDL_Surface *screen)
{
  if ( SDL_MUSTLOCK(screen) )
  {
    SDL_UnlockSurface(screen);
  }
}

void Cvideodef::copy_to_screen(Cimage *pimg)
{
  unsigned short *pout;
  t_video_defs   *pvd;

  pvd = &video_defs;
  if (pimg->sx != (int)pvd->x_size ||
      pimg->sy != (int)pvd->y_size)
    {
      printf("Warning: SDL image size mismatch in %s line %d\n", __FILE__, __LINE__);
      return ;
    }
  //Slock(g_screen);
  pout = (unsigned short*)g_screen->pixels;
  memcpy(pout, pimg->line(0), pimg->sizeB);
  SDL_Flip(g_screen);
}

void Cvideodef::wait_retrace()
{
  //Sulock(g_screen);
}
