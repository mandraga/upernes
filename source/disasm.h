

class Cdisasm : public Ivideo
{
  enum
    {
      unrecerror,
      newinstruction,
      jumpto,
      alreadyread,
      invalidopcode,
      middleofapreviousinstruction,
      stopdisasm
    };
 enum
    {
      enNewAddr = 0,
      enOpcode,
      enArgs
    };

public:
  Cdisasm();
  ~Cdisasm();

  int init(Crom_file *prom);
  int disasm(Copcodes *pops, Crom_file *prom, CindirectJmpRuntimeLabels *pindjmp, char *output_path);
  Cprogramlisting *getlisting();

private:
  unsigned int cpu2prg(unsigned int addr);
  unsigned int get_routine_addr(unsigned int addr, Crom_file *prom);
  void add_known_branches(int cur_addr, unsigned int operand, CindirectJmpRuntimeLabels *pindjmp);
  int next_jump_in_stack();
  int get_next_instruction(unsigned long *instruction,
			   Copcodes *pops, Crom_file *prom,
			   CindirectJmpRuntimeLabels *pindjmp);
  //int disasm_vector(Copcodes *pops, Crom_file *prom, int addr, const char *name, CindirectJmpRuntimeLabels *pindjmp);
  int disasm_addr(Copcodes *pops, Crom_file *prom, int addr, const char *addr_name, CindirectJmpRuntimeLabels *pindjmp);
public:
  // JUMPs to be explored
  unsigned short  *JUMP_stack;
  int             JUMP_stack_sz;
  // Explored instructions
  char            *pexplore;
private:
  int             m_cur_addr;
  int             m_instr_addr;
  Cmapper         m_mapper;
  Cprogramlisting m_listing;
  int             m_NMI_vector_start;
  int             m_Reset_vector_start;
  int             m_IRQBRK_vector_start;

  unsigned short  m_color;
  Cimage          m_img;
};
