#!/bin/sh
# SPDX-License-Identifier: Zlib
# Builds a small self-test disc (needs m68k binutils, python3 and genisoimage):
#   - one LOADFILEX call with a list of 40 files
#   - CARD save / load round trips, including a save that is too large
# Run it in an emulator that can dump RAM.  Expected after a few seconds:
#   0x130900: "DONE"        0x130000..: 0xA5000000 + n * 0x0101 for n = 0..39
#   0x130800: 00 00 00 00 84 00 00 01
set -e
cd "$(dirname "$0")"
mkdir -p out/disc
m68k-linux-gnu-as -m68000 --register-prefix-optional -o out/t.o selftest.s
m68k-linux-gnu-ld -Ttext=0 --oformat binary -e 0 -o out/disc/T.PRG out/t.o
python3 - <<'PY'
import struct
for i in range(40):
    open('out/disc/T%02d.PRG' % i, 'wb').write(struct.pack('>I', 0xA5000000 + i * 0x0101))
open('out/disc/IPL.TXT', 'wb').write(b'T.PRG,0,0\r\n')
PY
genisoimage -quiet -iso-level 1 -sysid "NEO-GEO CD" -V SELFTEST -o out/selftest.iso out/disc
printf 'FILE "selftest.iso" BINARY\n  TRACK 01 MODE1/2048\n    INDEX 01 00:00:00\n' > out/selftest.cue
echo "built tests/out/selftest.cue"
