
#define NBMNEMONICS 56

enum en_opcategory
  {
    Move,
    Logic,
    Arithmetic,
    Jump,
    Stack,
    Flags,
    Interrupts
  };

enum en_memaccess
  {
    Acc,
    Imm,
    PCR,
    zp,
    zpX,
    zpY,
    Abs,
    AbsX,
    AbsY,
    Ind,
    IndX,
    IndY,
    Implied
  };


class Copcodes
{
public:
  Copcodes();
  ~Copcodes();
  
  int fill_structure(char *file_path);
  void print_list(); // Debug test
  // In opcode_utils.cpp
  bool is_valid(unsigned char opcode);
  int  op_call_size(unsigned char opcode);
  bool is_branch(unsigned char opcode);
  bool is_mnemonic(unsigned char opcode, const char *mnemonic);
  int  addressing(unsigned char opcode);
  void print_instruction(int instr_addr, unsigned long  instruction);
  void out_instruction(FILE *fd, int opcode, int operand, char *label);
private:
  int  build_search_table();
  void print_category(int category);
  void print_flags(unsigned char Flags);
  bool check_mnemonic_number();
  // In opcode_utils.cpp
  t_ops *find_op(unsigned char opcode, Cmnemonic_6502 *pmnemonic);
  void out_operand(FILE *fd, int opcode, int operand, char *label);
  void out_mnemonic(FILE *fd, int opcode);
private:
  int             m_nb_mnemonics;
  Cmnemonic_6502  *m_pmnemonics_6502[256];
  Cmnemonic_6502  *m_pop2mnemonic[256]; // Opcode to mnemonic search table
};

