
#include <stdio.h>
#include <assert.h>
#include "rom_file.h"
#include "mapper.h"

Cmapper::Cmapper()
{
}

void Cmapper::init(Crom_file *prom)
{
  assert((prom->m_PRG_size % PRG_BANK_SIZE) == 0);
  if (prom->m_PRG_size >= (BANKSIZE / 2))
    // PRG starts at 0x8000
    m_cprgbase = BANKSIZE / 2;
  else
    // PRG starts at 0xC000, last 16KB
    m_cprgbase = BANKSIZE - prom->m_PRG_size;
  assert((m_cprgbase >= (BANKSIZE / 2)) && m_cprgbase < BANKSIZE);
}

int Cmapper::cpu2prg(int address)
{
  int ret;

  ret = address - m_cprgbase;
  assert(ret >= 0 && ret < BANKSIZE);
  return (ret);
}

unsigned int Cmapper::prgbase()
{
  return m_cprgbase;
}
