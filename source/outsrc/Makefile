
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

clean:
	-rm *.obj
	-rm *.o
	-rm *~

