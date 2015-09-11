
ASM= wla-65816
LINK= wlalink
FLAGS= -o

objects = ppu0.o

default: all

$(objects): %.o: %.asm
	@echo "-------- Makes: $<"
	$(ASM) $(FLAGS) $<

# linkfile.prj
all: $(objects)
	wlalink -vr linkfile.prj ppu0.fig

palgen:
	gcc -g palgen.c -o palgen

clean:
	-rm *.obj
	-rm *.o
	-rm *~
	-rm palgen
#	-rm palette.dat

