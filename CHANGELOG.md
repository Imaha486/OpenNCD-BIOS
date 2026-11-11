# Changelog

## 2.0

- New hardware mode for emulators that model the CD drive, the sector decoder and the transfer window (MAME, NeoCD libretro core). The BIOS now reads the disc itself: drive command link, sector reads, ISO 9660 root directory, `IPL.TXT`, and transfer of PRG, FIX, SPR, Z80, PCM and PAT files.
- CD audio in hardware mode: track lookup, play, pause, resume, looping and play-once.
- `BIOSF_LOADFILE`, `BIOSF_LOADFILEX` and `BIOSF_UPLOAD` work in hardware mode.
- The mode is chosen automatically. NeoRaine 1.4.3 keeps working with the same image.
- BIOS calls no longer change the status register, so games that run in user mode can call them. A reset requested from user mode is handled through the privilege exception.
- Landmark sequences for the BIOS scan of newer Raine versions (untested).
- Region is read with the correct polarity in each mode.

## 1.0

- First version, for NeoRaine 1.4.3 only.
- System calls, memory card, `MESS_OUT`, loading screen, math and random tables.
