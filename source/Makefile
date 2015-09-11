#
# Makefile, nes to super nes recompiler
#
#

CC = g++
CFLAGS = -Wall -g -c
LIB = -L./video/ -lvideo -lSDL

EXE_NAME=upernes

default: all

clean:
	rm -f *.o
	rm -f *.bin
	rm -f *~

.PHONY: test
test:
	cat opcodes.txt | ./test_lex_yy

testzz:
	cat opcodes.txt | ./test_lex_zz

lex.yy.o: opcode_desctxt.l parse_codes.h yywrap.c
	flex opcode_desctxt.l
	cc -c lex.yy.c
	cc -c yywrap.c
	cc lex.yy.o -o test_lex_yy -lfl

lex.zz.o: runtimeaddrcfg.l parse_codes.h zzwrap.c
	flex -P zz runtimeaddrcfg.l
	cc -c lex.zz.c
	cc -c zzwrap.c
	cc -c test_lex_zz.c
	cc lex.zz.o zzwrap.o test_lex_zz.o -o test_lex_zz

opcode_6502.o: opcode_6502.h
parser.o: parser.h parse_codes.h
opcodes.o: opcodes.h parser.h opcode_6502.h
opcodes_utils.o: opcodes.h opcode_6502.h
rom_file.o: rom_file.h
indirectJmp.o indirectJmp_parse.o: indirectJmp.h parse_codes.h rom_file.h
mapper.o: mapper.h rom_file.h
disasm.o: disasm.h opcodes.h opcode_6502.h rom_file.h mapper.h cpu6502.h nes.h instruction6502.h indirectJmp.h Ivideo.h img.h
instruction6502.o: instruction6502.h cpu6502.h
nes.o: nes.h
recompilateur.o recompilesimple.o recompileIO.o recompileIndJmp.o: recompilateur.h opcodes.h opcode_6502.h rom_file.h cpu6502.h nes.h instruction6502.h
indirectJmpAsmRoutines.o: recompilateur.h opcodes.h opcode_6502.h rom_file.h cpu6502.h nes.h instruction6502.h indirectJmp.h rom_file.h
img.o: img.h
Ivideo.o: Ivideo.h img.h
main.o: opcodes.h opcode_6502.h rom_file.h mapper.h Ivideo.h img.h

objects = opcode_6502.o parser.o opcodes.o opcodes_utils.o rom_file.o \
mapper.o disasm.o instruction6502.o nes.o recompilateur.o \
recompilesimple.o recompileIO.o recompileIndJmp.o indirectJmp.o \
indirectJmp_parse.o indirectJmpAsmRoutines.o img.o Ivideo.o main.o

flexObjects = lex.yy.o yywrap.o lex.zz.o zzwrap.o

$(objects): %.o: %.cpp
	@echo "-------- Makes: $<"
	$(CC) $(CFLAGS) $<

all: lex.yy.o lex.zz.o $(objects)
	@echo "-------- Makes: $(EXE_NAME)"
	$(CC) $(flexObjects) $(objects) -Lsystem/ $(LIB) -o $(EXE_NAME)

