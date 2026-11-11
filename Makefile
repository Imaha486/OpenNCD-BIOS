# OpenNCD BIOS - needs python3 and m68k binutils (m68k-linux-gnu-as / -ld)
all:
	python3 build.py

check: all
	sha256sum out/neocd.bin out/neocd_be.bin

clean:
	rm -rf out dist __pycache__

.PHONY: all check clean
