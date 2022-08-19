#
#
# Makefile for nes roms
#
#

ifeq ($(OS), Windows_NT)
OPERATINGON=__WINDOWS
else
OPERATINGON=__LINUX
endif

ifeq ($(OPERATINGON),__LINUX)
	ASM=nesasm
else
	ASM=NESASM3.EXE
endif

PROJECT=ppuIO

clean:
	@rm -f *.o
	@rm -f *.nes
	@rm -f *.fns
	@rm -f *~
	@rm -f $(COMMONSRCDIR)/*~
	@rm -f $(OUTPUT_DIR)$(EXE_NAME)


all: 
	$(ASM) $(PROJECT).asm

