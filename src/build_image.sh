#!/bin/sh

# ./build_image.sh /path/to/kernel.bin /path/to/store/output

dd if=/dev/zero of=$2 bs=1024 count=1440 status=none
dd if=$1 of=$2 conv=notrunc status=none
