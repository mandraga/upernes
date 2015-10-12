

#define SZ_INES_HEADER 16

// NES + 0x1A
#define FIRST_4BYTES   {0x4E, 0x45, 0x53, 0x1A}

#define PRG_BANK_SIZE (16 * 1024)
#define CHR_BANK_SIZE (8 * 1024)

class Crom_file
{
public:
  Crom_file();
  ~Crom_file();

  int open_nes(char *file_path);
  void print_inf();
  int dump(const char *prgname, const char *chrname);
  unsigned long crc();
  int getromname(char *str, unsigned int sz);
  int create_rom_headerfile(const char *file_name);
private:
  int read_mapper(unsigned char *header);
  int proces_header(unsigned char *header);
  int read_roms(FILE *fp);
  int dump_buffer(const char *name, unsigned char *buffer, int size);
  unsigned long buffer_crc(unsigned char *buffer, int size);
private:
  char m_name_str[128];
public:
  char m_error_str[128];
  unsigned char *m_pPRG;
  unsigned char *m_pCHR;
  int  m_PRG_size;
  int  m_CHR_size;
  int  m_mapper;
  // Flags
  bool m_Vertical_mirroring;
  bool m_Batery;
  bool m_Trainer;
  bool m_4screen_VRAM;
};
