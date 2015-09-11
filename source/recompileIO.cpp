
#include <stdio.h>
#include <string.h>
#include <assert.h>
#include "opcode_6502.h"
#include "opcodes.h"
#include "rom_file.h"
#include "cpu6502.h"
#include "nes.h"
#include "instruction6502.h"
#include "label.h"
#include "recompilateur.h"

void Crecompilateur::print_save(FILE *fp)
{
  fprintf(fp, "\tphp\n\tstx Xi\n");
}

void Crecompilateur::print_restore(FILE *fp)
{
  fprintf(fp, "\tldx Xi\n\tplp\n");
}

void Crecompilateur::routineSTAiop(FILE *fp, int iopaddr, Copcodes *popcode_list)
{
  fprintf(fp, "\nrsta_%02X:\n", iopaddr); // Print the label name
  // Save status...
  print_save(fp);
  // Put the io port somewhere
  fprintf(fp, "\tldx #$%02X\n", 2 * PORT2INDEX(iopaddr));
  fprintf(fp, "\tjsr staioportroutine\n");
  print_restore(fp);
  fprintf(fp, "\trts\n");
}

void Crecompilateur::routineLDAiop(FILE *fp, int iopaddr, Copcodes *popcode_list)
{
  fprintf(fp, "\nrlda_%02X:\n", iopaddr);
  print_save(fp);
  // Put the io port somewhere
  fprintf(fp, "\tldx #$%02X\n", 2 * PORT2INDEX(iopaddr));
  fprintf(fp, "\tjsr ldaioportroutine\n");
  print_restore(fp);
  fprintf(fp, "\tora #$00		; test N Z flags without affecting A\n");
  fprintf(fp, "\trts\n");
}

void Crecompilateur::routineLDXiop(FILE *fp, int iopaddr, Copcodes *popcode_list)
{
  fprintf(fp, "\nrldx_%02X:\n", iopaddr);
  fprintf(fp, "\tsta Acc\n");
  fprintf(fp, "\tldx #$%02X\n", 2 * PORT2INDEX(iopaddr));
  fprintf(fp, "\tjsr ldaioportroutine\n");
  fprintf(fp, "\tsta Xi\n");
  fprintf(fp, "\tlda Acc\n");
  fprintf(fp, "\tldx Xi		; x like if it has been loaded by a ldx\n");  
  fprintf(fp, "\trts\n");
}

void Crecompilateur::routineLDYiop(FILE *fp, int iopaddr, Copcodes *popcode_list)
{
  fprintf(fp, "\nrldy_%02X:\n", iopaddr);
  print_save(fp);
  fprintf(fp, "\tsta Acc\n");
  fprintf(fp, "\tldx #$%02X\n", 2 * PORT2INDEX(iopaddr));
  fprintf(fp, "\tjsr ldaioportroutine\n");
  fprintf(fp, "\tsta Yi\n");
  fprintf(fp, "\tlda Acc\n");
  print_restore(fp);
  fprintf(fp, "\tldy Yi		; y like if it has been loaded by a ldy\n");
  fprintf(fp, "\trts\n");
}

void Crecompilateur::routineSTXiop(FILE *fp, int iopaddr, Copcodes *popcode_list)
{
  fprintf(fp, "\nrstx_%02X:\n", iopaddr);
  // Save status...
  print_save(fp);
  fprintf(fp, "\tsta Acc\n");
  fprintf(fp, "\ttxa\n");
  fprintf(fp, "\tldx #$%02X\n", 2 * PORT2INDEX(iopaddr));
  fprintf(fp, "\tjsr ldaioportroutine\n");
  fprintf(fp, "\tlda Acc\n");
  print_restore(fp);
  fprintf(fp, "\trts\n");
}

void Crecompilateur::routineSTYiop(FILE *fp, int iopaddr, Copcodes *popcode_list)
{
  fprintf(fp, "\nrsty_%02X:\n", iopaddr);
  // Save status...
  print_save(fp);
  fprintf(fp, "\tsta Acc\n");
  fprintf(fp, "\ttya\n");
  // Y is saved in the call
  fprintf(fp, "\tldx #$%02X\n", 2 * PORT2INDEX(iopaddr));
  fprintf(fp, "\tjsr ldaioportroutine\n");
  fprintf(fp, "\tlda Acc\n");
  print_restore(fp);
  fprintf(fp, "\trts\n");
}

void Crecompilateur::outReplaceIOport(FILE *fp, t_pinstr pinstr,
				      Copcodes *popcode_list)
{
  char *pioname;
  bool replaced = false;

  fprintf(fp, "\t;---------------------\n");
  fprintf(fp, "\t;        ");
  popcode_list->out_instruction(fp, pinstr->opcode, pinstr->operand, NULL); // Output the original instruction as a comment
  if ((pioname = (char*)CnesIO::getioname(pinstr->operand)) != NULL)
    fprintf(fp, "  %s\n", pioname);
  else
    fprintf(fp, "\n");

  // TODO add absolute indexed addressing
  int   addressing = popcode_list->addressing(pinstr->opcode);
  assert(addressing == Abs);

  // Replacement functions
  if (popcode_list->is_mnemonic(pinstr->opcode, "sta"))
    {
      fprintf(fp, "\tjsr rsta_%02X\n", pinstr->operand);
      replaced = true;
    }
  if (popcode_list->is_mnemonic(pinstr->opcode, "lda"))
    {
      fprintf(fp, "\tjsr rlda_%02X\n", pinstr->operand);
      assert(!replaced);
      replaced = true;
    }      
  if (popcode_list->is_mnemonic(pinstr->opcode, "ldx"))
    {
      fprintf(fp, "\tjsr rldx_%02X\n", pinstr->operand);
      assert(!replaced);
      replaced = true;
    }
  if (popcode_list->is_mnemonic(pinstr->opcode, "stx"))
    {
      fprintf(fp, "\tjsr rstx_%02X\n", pinstr->operand);
      assert(!replaced);
      replaced = true;
    }
  if (popcode_list->is_mnemonic(pinstr->opcode, "ldy"))
    {
      fprintf(fp, "\tjsr rldy_%02X\n", pinstr->operand);
      assert(!replaced);
      replaced = true;
    }
  if (popcode_list->is_mnemonic(pinstr->opcode, "sty"))
    {
      fprintf(fp, "\tjsr rsty_%02X\n", pinstr->operand);
      assert(!replaced);
      replaced = true;
    }
  if (!replaced)
    {
      snprintf(m_error_str, sizeof(m_error_str),
	       "%s line %d, unsuported opcode conversion ($%02X operand $%04X)", __FILE__, __LINE__, pinstr->opcode, pinstr->operand);
      throw int(1);
    }
  fprintf(fp, "\t;------------\n");
}

bool Crecompilateur::findinstr(const char *mnemonicstr, t_instrlist *plist, Copcodes *popcode_list)
{
  t_instrlist::iterator II;

  for (II = plist->begin(); II != plist->end(); II++)
    {
      if (popcode_list->is_mnemonic((*II)->opcode, mnemonicstr))
	return true;
    }
  return false;
}

void Crecompilateur::writeiop_routines(FILE *fp, Cprogramlisting *plisting, Copcodes *popcode_list)
{
  t_instrlist *plist;
  bool start = true;
  int  iopaddr;

  while (plisting->get_IO_accessed(start, &plist))
    {
      start = false;
      iopaddr = (*plist->begin())->operand; // Get the address from the first access
      if (iopaddr == JOYSTICK1)
	continue ;
      if (findinstr("lda", plist, popcode_list))
	{
	  routineLDAiop(fp, iopaddr, popcode_list);
	}
      if (findinstr("ldx", plist, popcode_list))
	{
  	  routineLDXiop(fp, iopaddr, popcode_list);
	}
      if (findinstr("ldy", plist, popcode_list))
	{
	  routineLDYiop(fp, iopaddr, popcode_list);	  
	}
      if (findinstr("sta", plist, popcode_list))
	{
	  routineSTAiop(fp, iopaddr, popcode_list);
	}
      if (findinstr("stx", plist, popcode_list))
	{
	  routineSTXiop(fp, iopaddr, popcode_list);	  
	}
      if (findinstr("sty", plist, popcode_list))
	{
	  routineSTYiop(fp, iopaddr, popcode_list);
	}
    }
}
