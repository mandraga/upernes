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
"wla-65816" puts everything back together to an smc file.

Tricky modifications:
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
assembler, nesasm, an snes emulator with debug functionality. You may also need a software to edit nes
graphic data.
(check source/asm/memap.txt for information on code and data remaping)

Status:
The disassembler, and instructions rewriting coded in C++ is more or less finished since 2011.
The emulated PPU is work in progress, it needs a good knowledge of what's going on in the consoles.
Any working contribution will be apreciated. Basically, the remaining work is: finish the PPU io emulation,
integrate the NSF player for SNES by Memblers, add/fix interrupts. And finally add comon bank switching for
bigger roms.
The emulation part is very tricky because not everything is at his original place.

Tests:
T1 Palette   1
T2 PPU       1
T3 PPU       0
T4 PPU       0
T5 PPUScrol  0 scrolling ok
T6 PPUSprtie 0 too much sprites
T7 Pad0      0 color and backgorund error
T8 indjump   1 displays the adress


Windows installation:

Since the best snes debuggers are only available on windows, you may be interested in how to install
upernes on windows.
First install Msys2, it is the build environment, using gcc, make.
You must install the following modules from the Msys module installer:
    Make - Used to make upernes and to call wla-65816
    Gdb - Used to debug upernes
    SDL2 - Used to show the disassembly progress.
    Flex and Bison - Used to parse opcodes
You need to install wla-65816 from the web site. Wla-65816 is one of the best assemblers for retro gaming.
Add wla-65816 to your windows path (like adding C:\dev\snes\wladx_binaries_20040822\ to your $PATH)
I use FCEUX for the nes roms and bsnes-plus for the snes roms because they have a debugger.

How to use upernes:

Once everythnig is installed, go to the directory upernes/source/workdir/ and call ./convert.sh "rompath/romname" "outputpath"
This script calls upernes on the nes rom file and disassembles it and rebuilds the graphic tables. It then makes copies
of the source code and ressources and builds the output rom using wla-65816.
Indirect jumps cannot be analysed until the jump adress is known. Therefore the snes rom will stop on every missing
indirect jump adress and display the adress on a "crash" screen. You must add this address to romfilename.txt and call a new
convertion until all the indirect jumps are known.

Tools used, & authors:
SPC700 APU emulator (c)2001-2003 Joey Parsell (Memblers http://www.parodius.com/~memblers/) w/ assistance from Kevin Horton, and others
wla-65816 assembler by Ville Helin
NESASM3
the FCEUX comunity
NES Screen Tool by Shiru
Super Sleuth by Kris Bleakley (was the best emulator with debugger at the start of the project)
"bsnes-plus" based on Byuu's bsnes with improved debugging added by devinacker, undisbeliever and others.


upernes,(c)2015 Patrick Xavier Areny, upernes is released under the GPL licence.
my blog: http://www.blog.vreemdelabs.com/

