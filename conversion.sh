#!/bin/bash
# echo commands
#set -vx

if [ $# -eq 0 ]; then
    echo -e "Usage: ./conversion.sh inputrom.nes"
    echo -e ""
    echo -e "You can test upernes by converting a test rom"
    echo -e "./conversion.sh ./rom/nes/dev/t2_ppu0/ppu0.nes"
    exit 0
fi

# If the assembler is not on the system, then try the docker image
if [ -z $(which wla-65816) ]
then
    echo "Using docker."
    docker run --rm -it -e DISPLAY=$DISPLAY -v /tmp/.X11-unix:/tmp/.X11-unix -u root --privileged -v /dev:/dev -v `readlink -f .`:/opt/workspace -v ~/.ssh:/home/builder/.ssh -v ~/.gitconfig:/home/builder/.gitconfig upernes_image bash -c "usermod -u `id -u` builder && groupmod -g `id -g` builder && bash -c 'su -c \"export PATH=\$PATH && bash ./conversion.sh $1 $2\" builder'"
    exit 0
fi

CURENTPATH=$PWD
echo "input: $1"
ROMPATH=$(realpath "$1")
DEST=$(realpath "./workdir/")
echo "Converting from $ROMPATH to $DEST"
if [ -f "./workdir/" ]; then
	echo "workdir/ not found."
    exit 1
fi
cd ./workdir/
echo $PWD
./convert.sh "$ROMPATH" "$DEST"
if [ "$?" = 0 ]
then
    echo "ok"
    echo "$DEST"
fi

