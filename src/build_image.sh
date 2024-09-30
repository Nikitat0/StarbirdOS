#!/bin/sh

# ./build_image.sh path/to/boot.bin /path/to/kernel.bin /path/to/store/output

dd if=/dev/zero of=$3 bs=1024 count=1440
dd if=$1 of=$3 conv=notrunc
dd if=$2 of=$3 seek=1 conv=notrunc
