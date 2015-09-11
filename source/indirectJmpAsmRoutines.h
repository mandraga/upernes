
class CindirectJmpAsmRoutines
{
public:
  // in indirectJmpAsmRoutines.cpp
  int  create_indjump_asm_routines(const char *outname, CindirectJmpRuntimeLabels *pindjmp, t_label_list *plabel_gen_list);
private:
  // in indirectJmpAsmRoutines.cpp
  void write_asm_routines_header(FILE *fp);
  void write_asm_testfailcase(FILE *fp, int addr, int jmpoperand);
  bool get_indirect_jump_labelnumber(t_label_list *plabel_gen_list, int addr, int *pnum);
public:
  char              m_error_str[64];
};
