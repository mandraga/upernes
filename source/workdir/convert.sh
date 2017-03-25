#!bash
# echo commands
#set -vx

UPERNES_PATH="../binw64"

if [ "$1" = "" ]; then
	echo "usage: convert.sh \"rompath/romname\" [\"output_path\"]";
fi
if [ "$2" = "" ]; then
	OUTPUT_PATH="./"
else
	OUTPUT_PATH=$2
fi
echo "output path = " $OUTPUT_PATH
# Copy all the things in the asm directory
cp ../asm/*.asm ./
cp ../asm/*.inc ./
cp ../asm/linkfile.prj ./
cp ../opcodes.txt ./
cp ../asm/data/* ./data/

# Runs uppernes on the nes rom
set +vx
$UPERNES_PATH/upernes.exe $1 $OUTPUT_PATH

# Extract the ROM name from the path
ROM_NAME=$(echo $1 | sed "s/.*\///")
ROM_NAME=$(echo $ROM_NAME | sed "s/nes/fig/")
echo "Rom name = " $ROM_NAME
# Put it in the environment for the Makefile
export ROM_NAME
# Delete the previous one if any
rm $ROM_NAME
# Build the snes rom using the makefile
make all

unset ROM_NAME
set +vx

# Clean the static sources
rm ./CHR.asm
rm ./indjmp.asm
rm ./init.asm
rm ./PaletteUpdate.asm
rm ./DMABGUpdate.asm
rm ./instructions.asm
rm ./intvectors.asm
rm ./iopemulation.asm
rm ./LoadGraphics.asm
rm ./print.asm
rm ./rom.asm
rm ./Sound.asm
rm ./Strings.asm
rm ./zeromem.asm
rm ./sprite0.asm
rm ./*.inc
rm ./opcodes.txt
