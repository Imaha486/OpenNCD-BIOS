# SPDX-License-Identifier: Zlib
# Copyright (c) 2026 Imaha486
"""Data tables that games read directly from the system ROM address space.

Their existence, location and indexing were determined from how game
programs use them; the contents are regenerated here from first principles.

  0xC02000  4096 bytes  direction of the vector (dx,dy), index = dy*64+dx,
                        dx,dy in 0..63, result 0..0x40 (0x100 = full turn)
  0xC03000  4096 bytes  length of the vector (dx,dy), same index
  0xC04000  256 words   |sin| of the angle (0x100 = full turn) as a 0.16
                        fraction; exactly 1.0 is stored as the value 1
  0xC04200  256 bytes   pseudo random sequence (a permutation of 0..255)
"""
import math

def direction_table():
    t = bytearray(4096)
    for dy in range(64):
        for dx in range(64):
            if dx or dy:
                t[dy*64+dx] = min(0x40, int(round(math.atan2(dy, dx)*128/math.pi)))
    return bytes(t)

def length_table():
    t = bytearray(4096)
    for dy in range(64):
        for dx in range(64):
            t[dy*64+dx] = int(round(math.hypot(dx, dy)))
    return bytes(t)

def sine_table():
    out = bytearray()
    for i in range(256):
        v = int(round(abs(math.sin(i*math.pi/128))*65536))
        if v >= 65536:
            v = 1                       # marker for "multiply by one"
        out += v.to_bytes(2, 'big')
    return bytes(out)

def random_table():
    # Fisher-Yates shuffle driven by a small linear congruential generator
    state = 0x4F4E4344                  # "ONCD"
    def rnd(n):
        nonlocal state
        state = (state*1664525 + 1013904223) & 0xFFFFFFFF
        return (state >> 8) % n
    p = list(range(256))
    for i in range(255, 0, -1):
        j = rnd(i+1)
        p[i], p[j] = p[j], p[i]
    return bytes(p)

TABLES = [(0x2000, direction_table), (0x3000, length_table),
          (0x4000, sine_table), (0x4200, random_table)]
