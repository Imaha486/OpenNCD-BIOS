#!/usr/bin/env python3
# SPDX-License-Identifier: Zlib
# Copyright (c) 2026 Imaha486
"""Build script for OpenNCD BIOS.
   Produces  out/neocd.bin      (byte-swapped word order, as NeoRaine expects)
             out/neocd_be.bin   (plain big-endian 68000 image)"""
import subprocess, sys, os
from font import make_font
from tables import TABLES
ROOT=os.path.dirname(os.path.abspath(__file__))
SRC=os.path.join(ROOT,'src','bios.s'); OUT=os.path.join(ROOT,'out'); os.makedirs(OUT,exist_ok=True)
AS='m68k-linux-gnu-as'; LD='m68k-linux-gnu-ld'
def run(*a): subprocess.check_call(a)
obj=os.path.join(OUT,'bios.o'); raw=os.path.join(OUT,'bios.raw')
defs=[x for x in sys.argv[1:] if x.startswith('--defsym')]
run(AS,'-I',os.path.join(ROOT,'src'),'-m68000','--register-prefix-optional',*defs,'-o',obj,'-a='+os.path.join(OUT,'bios.lst'),SRC)
run(LD,'-Ttext=0xC00000','--oformat','binary','-e','0xC00000','-o',raw,obj)
img=bytearray(open(raw,'rb').read())
assert len(img)<=0x7C000, hex(len(img))
img+=bytes(0x80000-len(img))
# data tables used directly by games (see tables.py)
for off,gen in TABLES:
    data=gen()
    assert not any(img[off:off+len(data)]), 'table area %X is not free'%off
    img[off:off+len(data)]=data
# loading-screen font: the emulator reads it straight from the file image
# (tile data in text-layer format) at offset 0x7C000, 0x4000 bytes.
font=make_font()
assert len(font)==0x4000
def swap(b):
    b=bytearray(b); b[0::2],b[1::2]=b[1::2],b[0::2]; return b
img[0x7C000:0x80000]=swap(font)      # pre-swapped so the final file holds raw tile bytes
# sanity checks for the fixed interface points
assert img[0xA822:0xA824]==b'\x4B\xF9'
assert img[0x582:0x584]==b'\x4E\xF9'
# landmark sequences must be unique in the way the searching emulator expects
import struct
def find_all(pat,limit):
    return [n for n in range(0,limit,2) if img[n:n+len(pat)]==pat]
l=find_all(bytes.fromhex('0011C817'),0x10000); assert len(l)==3 and l[2]==0xB028, [hex(x) for x in l]
l=find_all(bytes.fromhex('7E7F22D8'),0x70000); assert len(l)==2, [hex(x) for x in l]
n=l[1]; assert struct.unpack('>I',img[n-10:n-6])[0]==0xC1701C
l=[x for x in find_all(bytes.fromhex('2B7C00004000'),0x70000)]; assert len(l)==1 and struct.unpack('>I',img[l[0]+10:l[0]+14])[0]==0xC7C000
cp=struct.unpack('>I',img[0x560:0x564])[0]-0xC00000+0x10
assert any(img[cp+k:cp+k+4]==bytes.fromhex('1B7C0002') for k in range(0,0x20,2))
assert all(img[k:k+2]!=b'\x4E\x75' for k in (0xB00C,0xB00E,0xB016,0xB018,0xB01E,0xB020)), 'jump address looks like rts'
open(os.path.join(OUT,'neocd_be.bin'),'wb').write(img)
open(os.path.join(OUT,'neocd.bin'),'wb').write(swap(img))
print('built',len(img),'bytes; code end',hex(len(open(raw,'rb').read())))
