#
# Makefile, nes to super nes recompiler
#
#

ifeq ($(OS), Windows_NT)
OPERATINGON=__WINDOWS
else
OPERATINGON=__LINUX
endif
RELEASE=TRUE

CC = g++
C  = gcc
INCLUDES = "/usr/include/"

ifeq ($(OPERATINGON),__LINUX)
	CHECKSTACK=-fstack-protector-all
	OUTPUT_DIR=./binl64/
else
	CHECKSTACK=
	OUTPUT_DIR=./binw64/
endif

FLAGS = -Wall -g $(CHECKSTACK) -c -I$(INCLUDES)
LIB = -L./video/ -lvideo -lSDL
ifeq ($(OPERATINGON),__LINUX)
CONSOLEFLAG=
EXT=
else
CONSOLEFLAG=-mconsole
EXT=.exe
endif

EXE_NAME=upernes

SRCDIR=.
OBJDIR=obj

default: all

clean:
	rm -f *.o
	rm -f *.bin
	rm -f *~
	rm -f $(OBJDIR)/*.o
	rm -f $(OUTPUT_DIR)$(EXE_NAME)$(EXT)

.PHONY: test
test:
	cat opcodes.txt | ./test_lex_yy$(EXT)

testzz:
	cat opcodes.txt | ./test_lex_zz$(EXT)

lex.yy.o: opcode_desctxt.l parse_codes.h yywrap.c
	flex opcode_desctxt.l
	$(C) -c lex.yy.c
	$(C) -c yywrap.c
	$(C) -c test_lex_yy.c
	$(C) lex.yy.o yywrap.o test_lex_yy.o -o test_lex_yy$(EXT) $(CONSOLEFLAG)
#-lfl

lex.zz.o: runtimeaddrcfg.l parse_codes.h zzwrap.c
	flex -P zz runtimeaddrcfg.l
	$(C) -c lex.zz.c
	$(C) -c zzwrap.c
	$(C) -c test_lex_zz.c
	$(C) lex.zz.o zzwrap.o test_lex_zz.o -o test_lex_zz$(EXT) $(CONSOLEFLAG)

$(OBJDIR)/opcode_6502.o: opcode_6502.h
$(OBJDIR)/parser.o: parser.h parse_codes.h
$(OBJDIR)/opcodes.o: opcodes.h parser.h opcode_6502.h
$(OBJDIR)/opcodes_utils.o: opcodes.h opcode_6502.h
$(OBJDIR)/rom_file.o: rom_file.h
$(OBJDIR)/indirectJmp.o:       indirectJmp.h parse_codes.h rom_file.h
$(OBJDIR)/indirectJmp_parse.o: indirectJmp.h parse_codes.h rom_file.h
$(OBJDIR)/mapper.o: mapper.h rom_file.h
$(OBJDIR)/disasm.o: disasm.h opcodes.h opcode_6502.h rom_file.h mapper.h cpu6502.h nes.h instruction6502.h indirectJmp.h Ivideo.h img.h
$(OBJDIR)/instruction6502.o: instruction6502.h cpu6502.h
$(OBJDIR)/nes.o: nes.h
$(OBJDIR)/recompilateur.o:   recompilateur.h opcodes.h opcode_6502.h rom_file.h cpu6502.h nes.h instruction6502.h
$(OBJDIR)/recompilesimple.o: recompilateur.h opcodes.h opcode_6502.h rom_file.h cpu6502.h nes.h instruction6502.h
$(OBJDIR)/recompileIO.o:     recompilateur.h opcodes.h opcode_6502.h rom_file.h cpu6502.h nes.h instruction6502.h
$(OBJDIR)/recompileIndJmp.o: recompilateur.h opcodes.h opcode_6502.h rom_file.h cpu6502.h nes.h instruction6502.h
$(OBJDIR)/indirectJmpAsmRoutines.o: recompilateur.h opcodes.h opcode_6502.h rom_file.h cpu6502.h nes.h instruction6502.h indirectJmp.h rom_file.h
$(OBJDIR)/patchPrgRom.o:     opcode_6502.h opcodes.h rom_file.h cpu6502.h nes.h instruction6502.h label.h recompilateur.h
$(OBJDIR)/img.o: img.h
$(OBJDIR)/Ivideo.o: Ivideo.h img.h
$(OBJDIR)/main.o: opcodes.h opcode_6502.h rom_file.h mapper.h Ivideo.h img.h

OBJS  =  $(OBJDIR)/opcode_6502.o
OBJS +=  $(OBJDIR)/parser.o
OBJS +=  $(OBJDIR)/opcodes.o
OBJS +=  $(OBJDIR)/opcodes_utils.o
OBJS +=  $(OBJDIR)/rom_file.o
OBJS +=  $(OBJDIR)/mapper.o
OBJS +=  $(OBJDIR)/disasm.o
OBJS +=  $(OBJDIR)/instruction6502.o
OBJS +=  $(OBJDIR)/nes.o
OBJS +=  $(OBJDIR)/recompilateur.o
OBJS +=  $(OBJDIR)/recompilesimple.o
OBJS +=  $(OBJDIR)/recompileIO.o
OBJS +=  $(OBJDIR)/recompileIndJmp.o
OBJS +=  $(OBJDIR)/indirectJmp.o
OBJS +=  $(OBJDIR)/indirectJmp_parse.o
OBJS +=  $(OBJDIR)/indirectJmpAsmRoutines.o
OBJS +=  $(OBJDIR)/patchPrgRom.o
OBJS +=  $(OBJDIR)/img.o
OBJS +=  $(OBJDIR)/Ivideo.o
OBJS +=  $(OBJDIR)/main.o

$(OBJS): $(OBJDIR)/%.o : $(SRCDIR)/%.cpp
	@echo "-------- : $<"
	$(CC) $(FLAGS) $< -o $@

flexObjects = lex.yy.o yywrap.o lex.zz.o zzwrap.o

all: lex.yy.o lex.zz.o $(OBJS)
	@echo "-------- Makes: $(EXE_NAME)$(EXT)"
	$(CC) $(flexObjects) $(OBJS) -Lsystem/ $(LIB) -o $(OUTPUT_DIR)$(EXE_NAME)$(EXT) $(CONSOLEFLAG)

