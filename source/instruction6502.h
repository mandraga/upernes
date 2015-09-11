
#include <list>

enum
  {
    nojump,
    jump,
    jsr,
    relativebranch
  };

typedef class Instruction6502 *t_pinstr;
typedef std::list<t_pinstr> t_instrlist;

class Instruction6502
{
public:
  Instruction6502(unsigned short addr);
  ~Instruction6502();
  bool is_label();
  bool label_category(Copcodes *pops, bool *pis_jsr, bool *pis_jmp, bool *pis_indjmp);
public:
  // Instruction data
  int            opcode;
  unsigned short operand;
  unsigned short addr;
  unsigned short branchaddr;  // Only for branches
  bool binsubroutine;
  t_instrlist *pbranches; // List of branches having this instruction for destination
  // known cpu state
  Ccpu6502       cpustate;
};

class Cprogramlisting
{
public:
  Cprogramlisting();
  ~Cprogramlisting();

  void insert(int opcode, int operand, int addr);
  void insert_branch(int jmpaddr, int destaddr);
  Instruction6502 *find_instr(int addr);

  void print_listing(Copcodes *pops);

  void list_IO_accessed();
  bool get_IO_accessed(bool start, t_instrlist **plist);
  void print_IO_accessed();


  void list_mem_accesses(Copcodes *pops);
  void print_mem_accesses();

  Instruction6502 *get_next(bool start);

  // Partial execution
  int update_state(int addr, Ccpu6502 cpustate);
private:
  Instruction6502 *create_instr(int addr);
private:
  t_instrlist m_listing;
  t_instrlist m_IOaccesses[NBIOPORTS];
  int         m_bckupaccess;
  int         m_stackaccess;
  int         m_memaccesses[Implied  + 1];
  t_instrlist::iterator m_listeur;
};
