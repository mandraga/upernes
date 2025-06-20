#!/bin/bash
# echo commands
#set -vx

OS_NAME=$(uname -s)
if [ "$OS_NAME" = "Linux" ]
then
	UPERNES_PATH="../bin/binl64"
	UPERNES_BINARY="upernes"
else
	UPERNES_PATH="../bin/binw64"
	UPERNES_BINARY="upernes.exe"
fi

if [ "$1" = "" ]; then
	echo "usage: convert.sh \"rompath/romname\" [\"output_path\"]";
	exit 0
fi
if [ "$2" = "" ]; then
	OUTPUT_PATH="./"
else
	OUTPUT_PATH=$2
fi
echo "output path = $OUTPUT_PATH"
# Copy all the things from the asm directory
cp ../source/asm/*.asm ./
cp ../source/asm/*.inc ./
cp ../source/asm/linkfile.prj ./
cp ../source/opcodes.txt ./
cp ../source/asm/data/* ./data/
cp ../source/asm/Memblers_2a03.bin ./

echo "romfile = $1"

# Runs uppernes on the nes rom
set +vx
echo -e "Calling: $UPERNES_PATH/$UPERNES_BINARY \"$1\" \"$OUTPUT_PATH\""
$UPERNES_PATH/$UPERNES_BINARY "$1" "$OUTPUT_PATH"
if [ $? -ne 0 ]
then
	echo "Conversion failed"
	exit 1
fi

# Extract the ROM name from the path
ROM_NAME=$(echo "$1" | sed "s/.*\///")
ROM_NAME=$(echo "$ROM_NAME" | sed "s/nes/fig/")
echo "Rom name = $ROM_NAME"
# Put it in the environment for the Makefile
export ROM_NAME
# Delete the previous one if any
if [ -f "$ROM_NAME" ]; then
	rm "$ROM_NAME"
fi
# Build the snes rom using the makefile
make all
RET=$?

unset ROM_NAME
set +vx

#exit 0
# Clean the static sources
rm ./CHR.asm
rm ./indjmp.asm
rm ./init.asm
rm ./PaletteUpdate.asm
rm ./DMABGUpdate.asm
rm ./SpritesUpdate.asm
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
rm ./cartridge.inc
rm ./var.inc
rm ./snesregisters.inc
rm ./opcodes.txt
rm ./Memblers_2a03.bin
