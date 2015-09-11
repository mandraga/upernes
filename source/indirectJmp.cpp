// Loads a config file specific to the rom containing the indirect addresses
// given by the translated program or deduced or found by another mean.
// A crc is used to check that it is the correct rom.
//
// Indirect jump conversion cycle:
//
// 1) An indirect jump is detected disassembling the source
// 2) This indirect jump is added to the conversion configuration file
// 3) In the reassembled rom, the indirect jump is replaced by a routine checking if the indirect address
//    is known (ie has been reassembled).
// 4) During execution, if an unknown address is found the game stops and displays the indirect jump address and the indirect address.
// 5) The indirect address is added by hand to the conversion configuration file.
// Return to 1) where the new address is disassembled.
//
// Aide mémoire:
// 1) Read the file, create a list of the known indirect jump and their potential jump adresses.
// 2) During dissassembly, add the discovered new indirect jumps to the list (knowing nothing yet of their potential jump addresses).
// 2' Update the file. 
// 3) The program must write an asm file containing a routine for every indirect jump. In this routine, the destination addresses
//    are checked and if not known, displays a black screeen with operand address and the missing destination address.
// 4) for each indirect jump in the original program, reassembling adds a jump to the corresponding routine.
//
// 3 steps one at initialisation, one at disassembling and one at reassembling. All with the same data.

#include <stdio.h>
#include <string.h>
#include <list>
#include <assert.h>

#include "rom_file.h"
#include "indirectJmp.h"
#include "parse_codes.h"

#define CFG_FILENAME_SZ 256

CindirectJmpRuntimeLabels::CindirectJmpRuntimeLabels():
  m_crc(-2),
  m_state(get_new_line),
  m_currentjopaddr(-2),
  m_binit(false)
{
  strcpy(m_error_str, "");
}

CindirectJmpRuntimeLabels::~CindirectJmpRuntimeLabels()
{
}

// Constructs the indirect address parameter text file name from the rom name
int CindirectJmpRuntimeLabels::find_config_filename(Crom_file *rom, char *cfg_file_name)
{
  char tmp_rom_file_name[CFG_FILENAME_SZ];
  int  i;

  if (rom->getromname(tmp_rom_file_name, CFG_FILENAME_SZ))
    {
      snprintf(m_error_str, sizeof(m_error_str), "getting the romname (%s line %d)",
	       __FILE__, __LINE__);
      return 1;
    }
  // Replace the last ".nes" by ".txt"
  i = strlen(tmp_rom_file_name) - 4;
  if (strncmp(&tmp_rom_file_name[i], ".nes", 4) != 0)
    {
      snprintf(m_error_str, sizeof(m_error_str), "%s has no \".nes\" extension.",
	       tmp_rom_file_name);
      return 1;
    }
  else
      strcpy(&tmp_rom_file_name[i], ".txt");
  snprintf(cfg_file_name, CFG_FILENAME_SZ, "outsrc/%s", tmp_rom_file_name);
  return 0;
}

int CindirectJmpRuntimeLabels::init(Crom_file *rom)
{
  char cfg_file_name[CFG_FILENAME_SZ];

  if (find_config_filename(rom, cfg_file_name))
    return 1;
  if (open_data(cfg_file_name))
    return 0; // Nothing to do, the file does not exist
  if (build_list())
    {
      close_data();
      return 1;
    }
  if (check_crc(rom))
    return 1;
  if (close_data())
    return 1;
  m_binit = true;
  return 0;
}

// bnew is true if this opcode has been found on the current disassembly
int CindirectJmpRuntimeLabels::addjmpoperand(int jopaddr, bool bnew)
{
  t_indirjmpiter Ijopaddr;
  t_indirjmp indjmp;

  for (Ijopaddr = m_jmplist.begin(); Ijopaddr != m_jmplist.end(); Ijopaddr++)
      if ((*Ijopaddr).jopaddr == jopaddr)
	return 1;
  indjmp.bnew = bnew;
  indjmp.jopaddr = jopaddr;
  m_jmplist.push_front(indjmp);
  return 0;
}

// Returns each indirect jump address and the corresponding operand (address of the address)
bool CindirectJmpRuntimeLabels::next_address(bool first, unsigned int *paddr, unsigned int *poperand)
{
  static t_indirjmpiter Ijopaddr;
  static t_jmpaddriter  Iaddr;

  if (m_jmplist.size() == 0)
    return false;
  if (first)
    {
      Ijopaddr = m_jmplist.begin();
      while (Ijopaddr != m_jmplist.end() && (*Ijopaddr).addrlist.size() == 0)
	Ijopaddr++;
      if (Ijopaddr == m_jmplist.end())
	return false;
      Iaddr = (*Ijopaddr).addrlist.begin();
    }
  if (Iaddr == (*Ijopaddr).addrlist.end())
    {
      Ijopaddr++;
      while (Ijopaddr != m_jmplist.end() && (*Ijopaddr).addrlist.size() == 0)
	Ijopaddr++;
      if (Ijopaddr == m_jmplist.end())
	return false;
      Iaddr = (*Ijopaddr).addrlist.begin();
    }
  *paddr = (*Iaddr);
  *poperand = (*Ijopaddr).jopaddr;
  Iaddr++;
  return true;
}

// Returns each indirect address for a given opcode address (used on indirect jumps to create branches lists, to create lables later)
bool CindirectJmpRuntimeLabels::next_op_address(bool first, int jopaddr, unsigned int *paddr)
{
  static t_indirjmpiter Ijopaddr;
  static t_jmpaddriter  Iaddr;

  if (m_jmplist.size() == 0)
    return false;
  if (first)
    {
      for (Ijopaddr = m_jmplist.begin(); Ijopaddr != m_jmplist.end(); Ijopaddr++)
	{
	  if ((*Ijopaddr).jopaddr == jopaddr)
	    break ;
	}
      if (Ijopaddr == m_jmplist.end())
	return false;
      Iaddr = (*Ijopaddr).addrlist.begin();
    }
  else
    assert((*Ijopaddr).jopaddr == jopaddr);
  if (Iaddr != (*Ijopaddr).addrlist.end())
    {
      *paddr = *Iaddr;
      Iaddr++;
      return true;
    }
  return false;
}

bool CindirectJmpRuntimeLabels::check_crc(Crom_file *rom)
{
  char romname[CFG_FILENAME_SZ];

  if (rom->crc() != m_crc)
    {
      assert (rom->getromname(romname, CFG_FILENAME_SZ) == 0);
      snprintf(m_error_str, sizeof(m_error_str), "%s, wrong crc, indirect jumps are not for this rom.", romname);
      return 1;
    }
  return 0;
}

void CindirectJmpRuntimeLabels::writeheader(FILE *fp, Crom_file *rom)
{
  char romname[CFG_FILENAME_SZ];

  assert (rom->getromname(romname, CFG_FILENAME_SZ) == 0);
  fprintf(fp, "## Add here the indirect jump addresses given during converted rom\n");
  fprintf(fp, "## execution or deduced. At runtime, any unknonw indirect address\n");
  fprintf(fp, "## will halt the recompiled rom and display the address.\n");
  fprintf(fp, "#\n");
  fprintf(fp, "# IndirectJump: $06\n");
  fprintf(fp, "# addr  $3201\n");
  fprintf(fp, "# addr  $324E\n");
  fprintf(fp, "#\n");
  fprintf(fp, "# jmp ($06): $06 is the direct page address of the 16bit address to jump.\n");
  fprintf(fp, "# $3201 and $324E are two addresses where it has jumped during\n");
  fprintf(fp, "# the execution or deduced looking at the disassembled program.\n");
  fprintf(fp, "#\n");
  fprintf(fp, "##########################################\n");
  fprintf(fp, "# %s\n", romname);
  fprintf(fp, "\ncrc32:\t$%08X\n\n\n", (unsigned int)rom->crc());
}

void CindirectJmpRuntimeLabels::writenewjumps(FILE *fp)
{
  t_indirjmpiter Ijopaddr;
  t_jmpaddriter  Iaddr;

  for (Ijopaddr = m_jmplist.begin(); Ijopaddr != m_jmplist.end(); Ijopaddr++)
    {
      if ((*Ijopaddr).bnew)
	{
	  fprintf(fp, "IndirectJump: $%02X\n", (*Ijopaddr).jopaddr);
	  Iaddr = (*Ijopaddr).addrlist.begin();
	  while (Iaddr != (*Ijopaddr).addrlist.end())
	    {
	      fprintf(fp, "addr: $%04X\n", (*Iaddr));
	      Iaddr++;
	    }
	  fprintf(fp, "\n\n");
	}
    }
}

int CindirectJmpRuntimeLabels::update_indjump_file(Crom_file *rom)
{
  bool           bupdate;
  t_indirjmpiter jmpiter;
  FILE           *fp;
  char           cfg_file_name[CFG_FILENAME_SZ];

  bupdate = false;
  for (jmpiter = m_jmplist.begin(); jmpiter != m_jmplist.end(); jmpiter++)
      bupdate |= (*jmpiter).bnew;
  if (bupdate)
    {
      if (find_config_filename(rom, cfg_file_name))
	return 1;
      fp = fopen(cfg_file_name, "a");
      if (fp == NULL)
	{
	  snprintf(m_error_str, sizeof(m_error_str),
		   "could not open %s to add indirect jumps", cfg_file_name);
	  return 1;
	}
      if (!m_binit)
	  writeheader(fp, rom);
      // Add the new jumps
      writenewjumps(fp);
      fclose(fp);
    }
  return 0;
}
