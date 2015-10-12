
class Cparser
{
enum
  {
    get_new_element,
    opcode_element,
    opcode_memuse_line,
    opcode_memuse_call,
    opcode_memuse_code,
    opcode_memuse_size,
    opcode_memuse_cycles,
    opcode_memuse_next,
    opcode_flags,
    opcode_description
  };
public:
  Cparser();
  ~Cparser(); 
  int open_data(char *file_name);
  int build_list(Cmnemonic_6502 **pmnemo_6502, int *nb_mnemonics);
  int close_data();
private:
  // A function for each parsing state
  void get_new(int res);
  void get_opcode(int res);
  void get_memuse_line(int res);
  void get_call_str(int res);
  void get_op_code(int res);
  void get_opcall_size(int res);
  void get_opcode_cycles(int res);
  void memuse_next_state(int res);
  void get_active_flags(int res);
  void get_description(int res, Cmnemonic_6502 **pmnemo_6502, int *nb_mnemonics);

public:
  char m_error_str[64];
private:
  int  m_state;
  int  m_current_op_category;
  Cmnemonic_6502 *m_ptmpmnemo;
};
