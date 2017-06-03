//     This program is free software: you can redistribute it and/or modify
//     it under the terms of the GNU General Public License as published by
//     the Free Software Foundation, either version 3 of the License, or
//     (at your option) any later version.
//
//     This program is distributed in the hope that it will be useful,
//     but WITHOUT ANY WARRANTY; without even the implied warranty of
//     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//     GNU General Public License for more details.
//
//     You should have received a copy of the GNU General Public License
//     along with this program.  If not, see <http://www.gnu.org/licenses/>.
//
//     upernes Copyright 2015 Patrick Xavier Areny - "arenyp at yahoo.fr"

#include <stdio.h>
#include <vector>
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
	      CindirectJmpRuntimeLabels *pindjmp,
	      char *outpath)
{
  Crecompilateur recompilateur;
  CindirectJmpAsmRoutines asr;
  const int cstrsz = 4096;
  char      path[cstrsz];

  snprintf(path, cstrsz, "%s/%s", outpath, "recomp.asm");
  if (recompilateur.re(path, plisting, popcode_list, prom))
    {
      printf("Error: %s\n", recompilateur.m_error_str);
      return 1;
    }
  snprintf(path, cstrsz, "%s/%s", outpath, "indjmp.asm");
  if (asr.create_indjump_asm_routines(path, pindjmp, recompilateur.get_label_gen_info()))
    {
      printf("Error: %s\n", asr.m_error_str);
      return 1;
    }
  snprintf(path, cstrsz, "%s/%s", outpath, "patchedPrg");
  if (recompilateur.patchPrgRom(path, plisting, popcode_list, pindjmp, prom))
    {
      printf("Error: %s\n", recompilateur.m_error_str);
      return 1;
    }
  snprintf(path, cstrsz, "%s/%s", outpath, "romprg.asm");
  prom->create_rom_headerfile(path);
  return 0;
}

int disassemble(Copcodes *popcode_list, Crom_file *prom, char *output_path)
{
  CindirectJmpRuntimeLabels indjmp;
  Cdisasm                   disassembler;

  switch (indjmp.init(prom, output_path))
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
  disassembler.disasm(popcode_list, prom, &indjmp, output_path);
  recompile(disassembler.getlisting(), popcode_list, prom, &indjmp, output_path);
  return 0;
}

int open_rom(char *file_path, char *output_path, Copcodes *popcode_list)
{
  Crom_file rom;
  const int strsz = 1024;
  char      prg_path[strsz];
  char      chr_path[strsz];

  if (rom.open_nes(file_path))
    {
      printf("Error: %s\n", rom.m_error_str);
      return 1;
    }
  rom.print_inf();
  snprintf(prg_path, strsz, "%s/%s", output_path, "nesprg.bin");
  snprintf(chr_path, strsz, "%s/%s", output_path, "neschr.bin");
  rom.dump(prg_path, chr_path);
  disassemble(popcode_list, &rom, output_path);
  return 0;
}

int main(int argc, char *argv[])
{
  Copcodes *popcode_list;
  char path[] = "./opcodes.txt";
  char outpath[] = "./";
  //#define FORCE_FILE
#ifdef FORCE_FILE
  char ROMpath[] = "../../rom/nes/smb1.nes";
  //char ROMpath[] = "../rom/nes/BalloonF.nes";
  //char ROMpath[] = "../rom/nes/dev/ppu0/ppu0.nes";
  //char ROMpath[] = "../rom/Xevious (E).nes";
  //char ROMpath[] = "../rom/Galaga (U).nes";
#else
  char *ROMpath;
#endif
  char *OutputPath;
  Ivideo scr;

#ifndef FORCE_FILE
  if (argc > 1)
    ROMpath = argv[1];
  else
    {
      printf("Usage: upernes romname.nes [output directory]\n\n");
      return 0;
     }
#endif
  if (argc > 2)
    {
      OutputPath = argv[2];
    }
  else
    {
      OutputPath = outpath;
    }
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
      open_rom(ROMpath, OutputPath, popcode_list);
    }
  delete popcode_list;
  scr.free_video();
  return 0;
}

