# Installing wla-65816:
# download the binaries and add the path to them somewere like in your shell configuration.
# add it to .bashrc like: PATH=~/home/me/upernes/asm/wla_linux_binaries/:$PATH
#
ASM= wla-65816
LINK= wlalink
LILKFILE= linkfile.prj
FLAGS= -o

objects = init.o instructions.o iopemulation.o
default: all

$(objects): %.o: %.asm
	@echo "$@" >> $(LILKFILE)
	@echo "-------- Makes: $<"
	$(ASM) $(FLAGS) $< 

#For versoin 10 which doe snot assemble well  witht he current code: $(ASM) $(FLAGS) $@ $< 

linkfile:
	-rm $(LILKFILE)
	echo "[objects]" > $(LILKFILE)

# linkfile.prj
all: linkfile $(objects)
	wlalink -rv linkfile.prj "$(ROM_NAME)"

clean:
	-rm *.obj
	-rm *.o
	-rm *~
	-rm *.bin
	-rm *.asm
	-rm *.prj
	-rm *.fig
