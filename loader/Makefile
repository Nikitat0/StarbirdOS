.PHONY: run clean

CFGS=$(wildcard config/*.nasm)
VBRS=$(CFGS:config/%.nasm=build/%.bin)
IMAGES=$(VBRS:%.bin=%.img)

ifndef BOOT_CFG
BOOT_CFG=full
endif

run: build/$(BOOT_CFG).img
	qemu-system-i386 -fda $< -display gtk,full-screen=on $(QEMU_EXTRA)

build:
	mkdir build

$(VBRS): build/%.bin:config/%.nasm boot.nasm | build
	nasm -f bin -P $< boot.nasm -o $@

build/pattern.bin: pattern.nasm | build
	nasm -f bin $< -o $@

$(IMAGES): %.img:%.bin build/pattern.bin | build
	dd if=/dev/zero of=$@ bs=1024 count=1440
	dd if=build/pattern.bin seek=4 of=$@ conv=notrunc
	dd if=$< of=$@ conv=notrunc
	dd if=lorem_ipsum.txt of=$@ seek=1 conv=notrunc

clean:
	@rm -rf build
