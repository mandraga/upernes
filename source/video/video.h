/*****************************************************************************************
* Hardware video interface for color graphics                                            *
*****************************************************************************************/

#ifndef __VIDEO_H__
#define __VIDEO_H__

typedef enum emode
{
  YUY2,
  RGB565,
  RGB555,
} tmode;

typedef struct s_video_defs
{
  unsigned long x_size;               // horizontal size in pixels
  unsigned long y_size;               // vertical size in pixels
  unsigned long bytes_per_pixel;
  unsigned long total_pix_size;       // buffer size in pixels
  unsigned long byte_size;            // buffer size in bytes
  unsigned long total_framebuf_size;  // Total video memory size
  unsigned char *FrameBufferAddress;  // Frame buffer addres
}               t_video_defs;

class Cvideodef
{
public:
  Cvideodef();
  ~Cvideodef();
  int init_video(int resolutionx, int resolutiony);
  void wait_retrace();
  void clear_screen();
  void copy_to_screen(Cimage *pic);

private:
  void quit_video();
private:
  t_video_defs video_defs;
};

#endif /*__VIDEO_H__*/
