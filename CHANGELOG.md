# Changelog

## 2.1

Found by a code audit and a new self-test disc (`tests/`), not by a game report.

- Fixed: a `BIOSF_LOADFILE` / `BIOSF_LOADFILEX` list with more than 32 files lost everything after the 32nd. Lists of any length are now loaded in batches.
- Fixed: in hardware mode, discs with more than 600 files in the root directory could not find the files beyond the 600th and often did not boot. Those are now looked up on the disc.
- Fixed: `CARD` save with data too large for the free space deleted the existing save of the same slot before reporting "full". The old save is now kept.
- Changed: in hardware mode, a CD audio request that the sound program leaves in Z80 RAM is now taken and cleared, instead of only being compared with the previous one. Sound programs that wait for the request to be cleared no longer stall, and the same request can be posted twice.
- Changed: a play request for the track that is already playing is ignored instead of restarting it.
- Changed: PAT files may span several sectors, and a record with address `0000` or `FFFF` is skipped instead of ending the file.
- Changed: sprite loads beyond bank 3 wrap around like the two-bit bank register does.
- Added: `$C00576` sends a byte to the sound CPU.
- Added: per-frame counter at `$10F749`, the drive heartbeat at `$10FE84`/`$10FE85`, the state bytes left after a load, and a set of constants in the system work area. Games are known to read these.
- License changed from MIT to zlib. Versions up to 2.0 remain available under MIT.

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
