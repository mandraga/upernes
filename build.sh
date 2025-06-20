#!/bin/bash
# echo commands
#set -vx

if [ -z $(which nesasm) ]
then
    docker run --rm -it -e DISPLAY=$DISPLAY -v /tmp/.X11-unix:/tmp/.X11-unix -u root --privileged -v /dev:/dev -v `readlink -f .`:/opt/workspace -v ~/.ssh:/home/builder/.ssh -v ~/.gitconfig:/home/builder/.gitconfig upernes_image bash -c "usermod -u `id -u` builder && groupmod -g `id -g` builder && bash -c 'su -c \"export PATH=\$PATH && bash ./build.sh\" builder'"
    exit 0
fi

echo "Building the nes test roms"
NESROMS=$(ls rom/nes/dev)
echo $NESROMS
CURENTPATH=$PWD
for folder in $NESROMS
do
    cd $CURENTPATH/rom/nes/dev/$folder
    make clean
    make all
    cd $CURENTPATH
done

echo "Building upernes"
cd source
make clean
make
