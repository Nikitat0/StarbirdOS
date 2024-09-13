.PHONY: run

run: build/boot.img
	qemu-system-i386 -fda $<

build:
	mkdir build

build/boot.bin: boot.nasm | build
	nasm -f bin $< -o $@

build/boot.img: build/boot.bin
	# dd if=/dev/zero of=$@ bs=1K count=1440
	dd if=$< of=$@ conv=notrunc
