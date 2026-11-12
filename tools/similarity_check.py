#!/usr/bin/env python3
# SPDX-License-Identifier: Zlib
# Copyright (c) 2026 Imaha486
"""Compare a build of OpenNCD BIOS with a reference ROM that you supply.

    python3 tools/similarity_check.py out/neocd.bin /path/to/reference.bin

Both files must be 512 KiB and in the same byte order.  The reference file is
only read and compared byte by byte; nothing is disassembled.

Two figures are printed for the code areas (0x700-0x1FFF and 0x4300-0x19FFF;
the generated math tables in between are skipped because games require their
contents):

  * bytes that are equal at the same offset (zeros and 0xFF are ignored)
  * runs of 12 or more bytes of OpenNCD code that also occur anywhere in the
    reference, with the bytes of each run so that you can see what they are
"""
import sys

N = 12

def main():
    if len(sys.argv) != 3:
        sys.exit(__doc__)
    mine = open(sys.argv[1], 'rb').read()
    ref = open(sys.argv[2], 'rb').read()
    if len(mine) != 0x80000 or len(ref) != 0x80000:
        sys.exit('both files must be 524288 bytes long')
    area = list(range(0x700, 0x2000)) + list(range(0x4300, 0x1A000))
    used = sum(1 for i in area if mine[i] not in (0x00, 0xFF))
    same = sum(1 for i in area if mine[i] == ref[i] and mine[i] not in (0x00, 0xFF))
    print('code bytes in use        : %d' % used)
    print('equal at the same offset : %d' % same)

    grams = set(ref[i:i + N] for i in range(len(ref) - N))
    hits = [i for i in area if mine[i:i + N] in grams and len(set(mine[i:i + N])) > 3]
    runs = []
    for h in hits:
        if runs and h <= runs[-1][1] + 1:
            runs[-1][1] = h
        else:
            runs.append([h, h])
    print('shared runs of %d+ bytes  : %d' % (N, len(runs)))
    for a, b in runs:
        length = b - a + N
        print('  0x%05X  %3d bytes  %s' % (a, length, mine[a:a + length].hex()))

if __name__ == '__main__':
    main()
