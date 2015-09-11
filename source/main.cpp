
#include <stdio.h>
#include "opcode_6502.h"
#include "opcodes.h"
#include "rom_file.h"
#include "mapper.h"
#include "cpu6502.h"
#include "nes.h"
#include "instruction6502.h"
#include "indirectJmp.h"
#include "label.h"
#include "recompilateur.h"
#include "indirectJmpAsmRoutines.h"
#include "img.h"
#include "Ivideo.h"
#include "disasm.h"
//#include "file_io.h"

int recompile(Cprogramlisting *plisting,
	      Copcodes *popcode_list, Crom_file *prom,
	      CindirectJmpRuntimeLabels *pindjmp)
{
  Crecompilateur recompilateur;
  CindirectJmpAsmRoutines asr;

  if (recompilateur.re("outsrc/recomp.asm", plisting, popcode_list, prom))
    {
      printf("Error: %s\n", recompilateur.m_error_str);
      return 1;
    }
  if (asr.create_indjump_asm_routines("outsrc/indjmp.asm", pindjmp, recompilateur.get_label_gen_info()))
    {
      printf("Error: %s\n", asr.m_error_str);
      return 1;
    }
  return 0;
}

int disassemble(Copcodes *popcode_list, Crom_file *prom)
{
  CindirectJmpRuntimeLabels indjmp;
  Cdisasm                   disassembler;

  switch (indjmp.init(prom))
    {
    case 1:
      printf("Error: %s\n", indjmp.m_error_str);
      return 1;
    case 2:
      printf("%s\n", indjmp.m_error_str);
      return 0;
    }
  if (disassembler.init(prom))
      return 1;
  disassembler.disasm(popcode_list, prom, &indjmp);
  recompile(disassembler.getlisting(), popcode_list, prom, &indjmp);
  return 0;
}

int open_rom(char *file_path, Copcodes *popcode_list)
{
  Crom_file rom;

  if (rom.open_nes(file_path))
    {
      printf("Error: %s\n", rom.m_error_str);
      return 1;
    }
  rom.print_inf();
  rom.dump("outsrc/data/nesprg.bin", "outsrc/data/neschr.bin");
  disassemble(popcode_list, &rom);
  return 0;
}

int main(int argc, char *argv[])
{
  Copcodes *popcode_list;
  char path[] = "./opcodes.txt";
  //char ROMpath[] = "../rom/Super Mario Bros. (W) [!].nes";
  //char ROMpath[] = "../rom/nes/Balloon Fight (JU) [!].nes";
  //char ROMpath[] = "../rom/nes/dev/ppu0/ppu0.nes";
  //char ROMpath[] = "../rom/Xevious (E).nes";
  //char ROMpath[] = "../rom/Galaga (U).nes";
  char *ROMpath;
  Ivideo scr;

  if (argc > 1)
    ROMpath = argv[1];
  else
    return 0;
  scr.init_video(640, 480);
  popcode_list = NULL;
  popcode_list = new Copcodes();
  if (popcode_list->fill_structure((char*)path) == 0)
    {
#if 0
      popcode_list->print_list();
#else
      printf("\n\n");
#endif
      open_rom(ROMpath, popcode_list);
    }
  delete popcode_list;
  scr.free_video();
  return 0;
}
