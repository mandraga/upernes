
ASM= wla-65816
LINK= wlalink
LILKFILE= linkfile.prj
FLAGS= -o

objects = init.o recomp.o instructions.o iopemulation.o indjmp.o

default: all

$(objects): %.o: %.asm
	@echo "$@" >> $(LILKFILE)
	@echo "-------- Makes: $<"
	$(ASM) $(FLAGS) $<

linkfile:
	-rm $(LILKFILE)
	echo "[objects]" > $(LILKFILE)

# linkfile.prj
all: linkfile $(objects)
	wlalink -vr linkfile.prj ppu0.fig

clean:
	-rm *.obj
	-rm *.o
	-rm *~

