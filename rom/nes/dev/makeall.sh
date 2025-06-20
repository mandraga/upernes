#!/bin/bash

DIRS=$(ls -d */)
for direc in $DIRS; do
    cd "./$direc/"
    make clean
    make all
    cd ../
done
exit 0

for direc in $DIRS; do
    cd "./$direc/"
    echo "./$direc/"
    hexdump *.fns | head -1
    cd ../
done