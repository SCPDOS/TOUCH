#!/bin/sh

touch:
	nasm touch.asm -o ./bin/TOUCH.COM -f bin -l ./lst/touch.lst -O0v
