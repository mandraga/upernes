
ASM= wla-65816
LINK= wlalink
FLAGS= -o

source = String.asm
objects = printf.o

default: all

$(objects): %.o: %.asm Strings.asm
	@echo "-------- Makes: $<"
	$(ASM) $(FLAGS) $<

# linkfile.prj
all: $(objects)
	wlalink -vr linkfile.prj printf.fig

palgen:
	gcc -g palgen.c -o palgen

clean:
	-rm *.obj
	-rm *.o
	-rm *~
	-rm palgen
#	-rm palette.dat

