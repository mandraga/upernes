#
# Makefile for the ply library
#
#

CC = g++
FLAGS = -Wall -g -c

clean:
	rm -f *.o
	rm -f *.bin
	rm -f *~

all:
	$(CC) $(FLAGS) video.cpp
	ar rcs libvideo.a video.o
	rm *.o
