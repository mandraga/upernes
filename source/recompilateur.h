
// When defined, the joypad reads are patched
#define REPLACEJOYPADRW

enum
  {
    noreplace,
    replaceBackupRam,
    replaceIOPort,
    replaceJumpIndirect,
    shityOpcode
  };

enum patchType
  {
    write,
    read,
    indirectJump,
  };

// Routine linked to and instruction and operand
typedef struct     s_PatchRoutine
{
  int              opcode;
  unsigned int     operand;
  char             RoutineName[LABELSZ];  // Name of the routine to be insterted in the array
  patchType        type;
  unsigned int     ramOffset; // Offset in the ram routines block
  unsigned int     ramSize;   // size of the block
}                  t_PatchRoutine;

class Crecompilateur
{
public:
  Crecompilateur();

  int re(const char *outname, Cprogramlisting *plisting,
	 Copcodes *popcode_list, Crom_file *prom);
  t_label_list *get_label_gen_info();
  int patchPrgRom(const char *outPrgName, Cprogramlisting *plisting, Copcodes *popcode_list, CindirectJmpRuntimeLabels *pindjmp, Crom_file *prom);
  
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
  void routineSTAiop(FILE *fp, int iopaddr, Copcodes *popcode_list, t_pinstr pinstr, std::vector<t_PatchRoutine> &PatchRoutines);
  void routineSTAAbsXiop(FILE *fp, int iopaddr, Copcodes *popcode_list, t_pinstr pinstr, std::vector<t_PatchRoutine> &PatchRoutines);
  void routineSTAAbsYiop(FILE *fp, int iopaddr, Copcodes *popcode_list, t_pinstr pinstr, std::vector<t_PatchRoutine> &PatchRoutines);
  void routineLDAiop(FILE *fp, int iopaddr, Copcodes *popcode_list, t_pinstr pinstr, std::vector<t_PatchRoutine> &PatchRoutines);
  void routineLDXiop(FILE *fp, int iopaddr, Copcodes *popcode_list, t_pinstr pinstr, std::vector<t_PatchRoutine> &PatchRoutines);
  void routineLDYiop(FILE *fp, int iopaddr, Copcodes *popcode_list, t_pinstr pinstr, std::vector<t_PatchRoutine> &PatchRoutines);
  void routineBITiop(FILE *fp, int iopaddr, Copcodes *popcode_list, t_pinstr pinstr, std::vector<t_PatchRoutine> &PatchRoutines);
  void routineSTXiop(FILE *fp, int iopaddr, Copcodes *popcode_list, t_pinstr pinstr, std::vector<t_PatchRoutine> &PatchRoutines);
  void routineSTYiop(FILE *fp, int iopaddr, Copcodes *popcode_list, t_pinstr pinstr, std::vector<t_PatchRoutine> &PatchRoutines);
  void ReplaceAbsAddressing(FILE *fp, t_pinstr pinstr, Copcodes *popcode_list, bool &replaced);
  void ReplaceAbsXAddressing(FILE *fp, t_pinstr pinstr, Copcodes *popcode_list, bool &replaced);
  void ReplaceAbsYAddressing(FILE *fp, t_pinstr pinstr, Copcodes *popcode_list, bool &replaced);
  void outReplaceIOport(FILE *fp, t_pinstr pinstr, Copcodes *popcode_list);
  bool findinstr(const char *mnemonicstr, t_instrlist *plist, Copcodes *popcode_list, int &addressing, t_instrlist& instrList);
  void writeiop_routines(FILE *fp, Cprogramlisting *plisting, Copcodes *popcode_list, std::vector<t_PatchRoutine> &PatchRoutines);
  void AddPRGPatch(int iopaddr, Copcodes *popcode_list, t_pinstr pinstr, char *routineName, std::vector<t_PatchRoutine> &PatchRoutines);
  // recompileIndJmp.cpp
  void outReplaceJumpIndirect(FILE *fp, t_pinstr pinstr, Copcodes *popcode_list);
  // patchPrgRom.cpp
  void patchBRK(t_pinstr pinstr, Copcodes *popcode_list, unsigned char *pPRG, unsigned int PRGSize, std::vector<t_PatchRoutine>& Routines, Cmapper *pmapper);
  void writeRoutineVector(FILE *fp, Copcodes *popcode_list, std::vector<t_PatchRoutine>& Patches, int readIndex, int indJmpIndex, int soundEmuLine);
  unsigned int writeRamRoutineBinary(const char *fileName, std::vector<t_PatchRoutine>& Patches);
  void sortRoutines(std::vector<t_PatchRoutine>& Patches, int& readIndex, int& indJmpIndex);
  bool isIn(t_pinstr pinstr, t_instrlist& instrList);
  
public:
  char m_error_str[128];
private:
  t_label_list m_label_gen_list;
  unsigned int m_PPUAddrRoutineSize;
};

