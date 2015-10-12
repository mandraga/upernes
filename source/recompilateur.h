
enum
  {
    noreplace,
    replaceBackupRam,
    replaceIOPort,
    replaceJumpIndirect
  };

class Crecompilateur
{
public:
  Crecompilateur();

  int re(const char *outname, Cprogramlisting *plisting,
	 Copcodes *popcode_list, Crom_file *prom);
  t_label_list *get_label_gen_info();

private:
  void labelgen(t_label *plabel);
  void create_label_list(Cprogramlisting *plisting, Copcodes *pops);
  t_label *findlabel(int addr);
  int isreplaced(t_pinstr pinstr, Copcodes *popcode_list);

  // recompilesimple.cpp
  void writeheader(FILE *fp);
  void printlabel(FILE *fp, t_pinstr pinstr);
  void strprintoperandlabel(t_pinstr pinstr, Copcodes *popcode_list, char *pstrout, int len);
  void outinstr(FILE *fp, t_pinstr pinstr, Copcodes *popcode_list);
  // recompileIO.cpp
  void print_save(FILE *fp);
  void print_restore(FILE *fp);
  void routineSTAiop(FILE *fp, int iopaddr, Copcodes *popcode_list);
  void routineLDAiop(FILE *fp, int iopaddr, Copcodes *popcode_list);
  void routineLDXiop(FILE *fp, int iopaddr, Copcodes *popcode_list);
  void routineLDYiop(FILE *fp, int iopaddr, Copcodes *popcode_list);
  void routineSTXiop(FILE *fp, int iopaddr, Copcodes *popcode_list);
  void routineSTYiop(FILE *fp, int iopaddr, Copcodes *popcode_list);
  void outReplaceIOport(FILE *fp, t_pinstr pinstr, Copcodes *popcode_list);
  bool findinstr(const char *mnemonicstr, t_instrlist *plist, Copcodes *popcode_list);
  void writeiop_routines(FILE *fp, Cprogramlisting *plisting, Copcodes *popcode_list);
  // recompileIndJmp.cpp
  void outReplaceJumpIndirect(FILE *fp, t_pinstr pinstr, Copcodes *popcode_list);

public:
  char m_error_str[128];
private:
  t_label_list m_label_gen_list;
};
