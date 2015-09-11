

#define BANKSIZE 0x10000

class Cmapper
{
public:
  Cmapper();

  void init(Crom_file *prom);
  int cpu2prg(int address);
  unsigned int prgbase();

private:
  int m_cprgbase;
};
