# upernes
A Nes to Super Nes recompiler.

upernes takes rom files for the Nintendo Nes and recompiles them to make Super Nes smc rom files.

Principle:
The rom is disassembled, the tile data is separated. The 6502  machine code is analysed and stored in a list.
Once this list is made, the code is modified in order to replace read/writes to the original nes hardware by
calls to 65C816 assembler routines. The memory is slightly reorganised, the data is taken from the original code
in a first bank and the modified code runs from a second bank. Most of the original 6502 code is kept and runs
in emulation mode.
upernes outputs an assembler file and converted tile data in outsrc, they must be copied in asm/ with "cpconversion.sh"
and compiled to a rom with "wla-65816".
"wla-65816" does all the work of puting everything together.

Tricky parts are:
The indirect jumps, they cannot be detected by reading the ROM, they must be displayed
when running into an unknown address on the SNES. Added manually to a txt file, and the
rom recompiled including the new indirect address.
The read/writes to the Nes hardware: replaced by 16 bit routines.
All in all it has been proven possible to make the conversion.

How it is developed:
Very simple test roms each one targeting an hardware aspect are written in the directory "rom/nes/dev/".
Those roms are single test cases for things like background, scrolling, sprites, indirect jumps.
They are simple because it is or was difficult in 2010 to debug snes code.
The program is written in C++ and 65C816 assembler routines plus 6502 test roms. You need the "wla-65816" snes
assembler, nesasm plus an snes emulator with debug functionality. you may also need a software to edit nes
graphic data.
(check source/asm/memap.txt for information on code and data remaping)

Status:
The disassembler and assembler coded in C++ is nearly finished since 2011.
The emulated PPU is work in progress, it must be taken at once with a clear view of what os programmed.
Any working contribution will be apreciated. Basically, the remaining work is: finish the io APU emulation,
integrate the NSF player for SNES by Memblers, add/fix interrupts. And finally add comon bank switching for
bigger roms.
The emulation part is very tricky because not everything is at his original place and because of the assembler
langage.

Copyright 2015 Patrick Xavier Areny released under the GPL licence.


