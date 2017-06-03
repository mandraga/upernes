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

#include <string.h>
#include <stdio.h>
#include <assert.h>
#include "rom_file.h"

Crom_file::Crom_file():
  m_pPRG(NULL),
  m_pCHR(NULL),
  m_PRG_size(-1),
  m_CHR_size(-1),
  m_mapper(-1),
  m_Vertical_mirroring(false),
  m_Batery(false),
  m_Trainer(false),
  m_4screen_VRAM(false)
{
  strcpy(m_error_str, "");
  strcpy(m_name_str, "");
}

Crom_file::~Crom_file()
{
  delete[] m_pPRG;
  delete[] m_pCHR;
}

int Crom_file::read_mapper(unsigned char *header)
{
  m_mapper = header[6] >> 4;
  if (m_mapper > 0)
    {
      snprintf(m_error_str, sizeof(m_error_str), "ines header: mapper %d not suported", m_mapper);
      return 1;
    }
  if (header[7])
    {
      snprintf(m_error_str, sizeof(m_error_str), "ines header: extended mappers not suported (byte 7 is %x)", header[7]);
      return 1;
    }
  // Flags
  m_Vertical_mirroring = (header[6] & 1) != 0;
  m_Batery = (header[6] & 2) != 0;
  m_Trainer = (header[6] & 4) != 0;
  m_4screen_VRAM = (header[6] & 8) != 0;
  return 0;
}

int Crom_file::proces_header(unsigned char *header)
{
  const unsigned char cheader[] = FIRST_4BYTES;
  int i;

  // Check header
  for (i = 0; i < 4; i++)
    if (cheader[i] != header[i])
      {
	snprintf(m_error_str, sizeof(m_error_str), "ines header");
	return 1;
      }
  // PRG
  i = (int)header[4];
  if (i == 0 || i > 64)
      {
	snprintf(m_error_str, sizeof(m_error_str), "wrong PRG memory size");
	return 1;
      }
  m_PRG_size = i * PRG_BANK_SIZE; // 16KB page
  // CHR
  i = (int)header[5];
  if (i > 64)
      {
	snprintf(m_error_str, sizeof(m_error_str), "wrong CHR memory size");
	return 1;
      }  
  m_CHR_size = i * CHR_BANK_SIZE; // 8KB page
  // Read rom mapper and flags
  if (read_mapper(header))
    return 1;
  // Bytes 8 to 15 must be 0x00
  for (i = 8; i < 16; i++)
    if (header[i])
      {
	snprintf(m_error_str, sizeof(m_error_str), " byte %d in ines header is not 0", i);
	return 1;
      }
  return 0;
}

int Crom_file::read_roms(FILE *fp)
{
  int rd;

  m_pPRG = new unsigned char[m_PRG_size];
  if ((rd = fread(m_pPRG, m_PRG_size, 1, fp)) != 1)
    {
      snprintf(m_error_str, sizeof(m_error_str), "prg rom read");
      return 1;
    }
  if (m_CHR_size)
    {
      m_pCHR = new unsigned char[m_CHR_size];
      if ((rd = fread(m_pCHR, m_CHR_size, 1, fp)) != 1)
	{
	  snprintf(m_error_str, sizeof(m_error_str), "chr rom read");
	  return 1;
	}
    }
  return 0;
}

int Crom_file::open_nes(char *file_path)
{
  FILE *fp;
  unsigned char header[16];
  int  size;

  fp = fopen(file_path, "rb");
  if (fp == NULL)
    {
      snprintf(m_error_str, sizeof(m_error_str), "open file %s", file_path);
      return 1;
    }
  strncpy(m_name_str, file_path, sizeof(m_name_str));
  if ((size = fread(header, 16, 1, fp)) == 0)
    {
      snprintf(m_error_str, sizeof(m_error_str), "read file %s", file_path);
      return 2;
    }
  if (proces_header(header))
    return 3;
  if (read_roms(fp))
    return 4;
  fclose(fp);
  return 0;
}

void Crom_file::print_inf()
{
  int prg_banks;
  int chr_banks;
  char c;

  prg_banks = m_PRG_size / PRG_BANK_SIZE;
  chr_banks = m_CHR_size / CHR_BANK_SIZE;
  printf("Rom file: %s\n", m_name_str);
  printf("mapper %d\n", m_mapper);
  c = prg_banks > 1? 's' : ' ';
  printf("PRG: %2dKB %2d bank%c\n", m_PRG_size / 1024, prg_banks, c);
  if (m_CHR_size)
    {
      c = chr_banks > 1? 's' : ' ';
      printf("CHR: %2dKB %2d bank%c\n", m_CHR_size / 1024, chr_banks, c);
    }
  else
    printf("CHR: none\n");
  if (m_Vertical_mirroring)
    printf("Vertical mirroring ");
  if (m_Batery)
    printf("Backup battery ");
  if (m_Trainer)
    printf("Trainer ");
  if (m_4screen_VRAM)
    printf("4 screen VRAM");
  printf("\n");
}

int Crom_file::dump_buffer(const char *name, unsigned char *buffer, int size)
{
  FILE *fp;
  int   ret = 0;

  fp = fopen(name, "wb"); // Binary or it will not work (oversized data...).
  if (fp)
    {
      ret = fwrite(buffer, 1, size, fp);
      fclose(fp);
    }
  return ret;
}

int Crom_file::dump(const char *prgname, const char *chrname)
{
  assert(m_PRG_size % PRG_BANK_SIZE == 0);
  if (dump_buffer(prgname, m_pPRG, m_PRG_size) == 0)
    return 1;
  if (dump_buffer(chrname, m_pCHR, m_CHR_size) == 0)
    return 1;
  return 0;
}

unsigned long Crom_file::buffer_crc(unsigned char *buffer, int size)
{
  int           i;
  unsigned long lcrc;
  unsigned char crc[4];

  for (i = 0; i < 4; i++)
    crc[i] = 0;
  for (i = 0; i < size; i++)
    {
      crc[i & 3] ^= buffer[i];
    }
  lcrc = 0;
  lcrc = crc[3] << 24;
  lcrc |= crc[2] << 16;
  lcrc |= crc[1] << 8;
  lcrc |= crc[0];
  return (lcrc);
}

unsigned long Crom_file::crc()
{
  unsigned long crc;

  crc = buffer_crc(m_pPRG, m_PRG_size);
  crc ^= buffer_crc(m_pCHR, m_CHR_size);
  return (crc & 0x00000000FFFFFFFF);
}

int Crom_file::getromname(char *str, unsigned int sz)
{
  int  i;

  // Find the '/' of the path beforet he file name
  for (i = strlen(m_name_str) - 1; i > 0; i--)
    if (m_name_str[i] == '/')
      {
	i++;
	break ;
      }
  if (strlen(&m_name_str[i]) >= sz)
    return 1;
  strncpy(str, &m_name_str[i], sz);
  return 0;
}

int Crom_file::create_rom_headerfile(const char *file_name)
{
  FILE *fp;
  int  prg_banks;

  try
    {
      fp = fopen(file_name, "w");
      if (fp == NULL)
	{
	  snprintf(m_error_str, sizeof(m_error_str),
		   "in create_rom_headerfile opening the file \"%s\" failed", file_name);
	  throw int(1);
	}
      fprintf(fp, ";; --------------------------------------------------------------------\n");
      fprintf(fp, "; PRG\n");
      fprintf(fp, ".BANK 1 SLOT 0\n");
      prg_banks = m_PRG_size / PRG_BANK_SIZE;
      switch (prg_banks)
	{
	case 1:
	  fprintf(fp, ".ORG $4000\n"); // If the prg rom is <= 16kb then it begins in the uper bank (0xC000) but 0x4000 in wla-dx
	  break;
	case 2:
	  fprintf(fp, ".ORG 0\n");
	  break;
	default:
	  assert(false);
	};
      //      fprintf(fp, ".SECTION \"OriginalPRGrom\" FORCE\n");
      //fprintf(fp, ".SECTION \"PatchedPRGrom\"\n");
      //fprintf(fp, "PRGrom:\n");
      fprintf(fp, ";.INCBIN \"nesprg.bin\"\n"); // comented
      fprintf(fp, ".INCBIN \"patchedPrg.bin\"\n");
      //fprintf(fp, ".ENDS\n");
      fclose(fp);
    }
  catch (int e)
    {
      return 1;
    }
  return 0;
}

void Crom_file::GetPrgCopy(unsigned char *pBuffer)
{
  memcpy(pBuffer, m_pPRG, m_PRG_size);
}

