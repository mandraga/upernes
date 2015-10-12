

class Cimage
{
public:
  Cimage(int resx, int resy);
  ~Cimage();

  unsigned short &pixel(int x, int y);
  unsigned short *line(int y);
  void clear();

public:
  int sx;
  int sy;
  int Bpp;
  int sizep;
  int sizeB;
  unsigned short *buffer;
};
