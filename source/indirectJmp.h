
typedef std::list<int>              t_jmpaddrlist;
typedef std::list<int>::iterator    t_jmpaddriter;

typedef struct
{
  bool          bnew;
  unsigned int  jopaddr;         // The indirect jump operand value, address of the indirect address
  t_jmpaddrlist addrlist;        // Addresses where it can jump
} t_indirjmp;

typedef std::list<t_indirjmp>           t_indjmplist;
typedef std::list<t_indirjmp>::iterator t_indirjmpiter;

class CindirectJmpRuntimeLabels
{
enum
  {
    get_new_line,
    get_crc,
    jumpaddr_var,
    jumpaddr_addr
  };
public:
  CindirectJmpRuntimeLabels();
  ~CindirectJmpRuntimeLabels();
  int  init(Crom_file *rom, char *output_path);
  int  addjmpoperand(unsigned int jopaddr, bool bnew);
  int  update_indjump_file(Crom_file *rom, char *output_path);
  bool next_address(bool first, unsigned int *paddr, unsigned int *poperand);
  bool next_op_address(bool first, unsigned int jopaddr, unsigned int *paddr);
  bool next_operand(bool first, unsigned int *pjoperand);
  bool next_indaddr(bool first, unsigned int joperand, unsigned int *paddr);
  bool GetPatchingDisabled();
private:
  int  find_config_filename(Crom_file *rom, char *cfg_file_name, char *output_path);
  bool check_crc(Crom_file *rom);
  void writeheader(FILE *fp, Crom_file *rom);
  void writenewjumps(FILE *fp);
  // in indirectJmp_parse.cpp
  int  open_data(char *file_name);
  int  close_data();
  int  list_add_jopaddr(unsigned int jopaddr);
  void add_addr(unsigned int addr);
  void get_new(int res);
  void get_32b_crc(int res);
  void get_8b_addr(int res);
  void get_16b_addr(int res);
  int  build_list();

public:
  char              m_error_str[4096];
private:
  unsigned long     m_crc;
  int               m_state;
  unsigned int      m_currentjopaddr;
  bool              m_binit;
  t_indjmplist      m_jmplist;
  t_indirjmpiter    m_Ijopaddr;
  t_jmpaddriter     m_Iaddr;
  bool              m_bDisableIndJumpPatching;
};
