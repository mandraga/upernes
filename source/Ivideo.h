

//#define USE_VIDEO
class Ivideo
{
public:
  Ivideo();
  ~Ivideo();

  void clear();
  int copy_to_bitmap(Cimage *pic, int x, int y);
  int update_screen();
public:
  int init_video(int resolutionx, int resolutiony);
  int free_video();
};
