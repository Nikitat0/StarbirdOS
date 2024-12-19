#!/bin/sh

# ./build_image.sh /path/to/kernel.bin /path/to/init.jedi /path/to/store/output

dd if=/dev/zero of=$3 bs=1024 count=1440 status=none
dd if=$1 of=$3 conv=notrunc status=none
dd if=$2 of=$3 bs=1024 seek=128 conv=notrunc status=none
