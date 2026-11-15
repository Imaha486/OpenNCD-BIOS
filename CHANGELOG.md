# Changelog

## 2.5

Games that bring their own file loader. Found with Shinsetsu Samurai Spirits Bushidou Retsuden (Samurai Shodown RPG), which loads every file after the first boot through a loader on the disc instead of through the BIOS calls. What that loader expects from the system was worked out from the game's own code.

- Fixed: the game stopped with an exception right after boot (NeoRaine 1.4.3) or never left the loading screen (hardware mode). Its loader reads the vertical blank vector from the ROM table and takes the long word two bytes into that routine as the address of the system's vertical blank service. The routine is now a plain absolute jump, so that address is valid.
- New (hardware mode): the drive request queue at `$10F472` (indexes `$10F650` / `$10F651`). Request 9 reads sectors starting at the position in `$10F6C8`; requests 5 and 6 stop reading. Each sector is put into the buffer at `$111204` and the count at `$10F688` goes down by one. A sector is only delivered while the game says it is waiting (bit 0 of `$10F657`); otherwise the drive goes back for it. A request with a count of zero ends at once by clearing `$10F6B6`.
- New (hardware mode): the position and length of the root directory are left in `$10F6A8` and `$10F6A6`, and a copy of the first 2 KiB of program memory is kept at `$110004`. Such a loader reads the directory itself and copies that block back over address 0 after each program file.
- New: the loading screen hooks at `$11C808` and `$11C80C` and a default animation script at `$11C810` are set in every mode, and a second copy of the loading screen font sits at `$C6BEB0`, where such a loader fetches it.
- Changed: the console type in `$10FEDF` is now 1 (top loader) instead of 2 (CDZ). With 2 this game expects the system to distribute the sectors to their destinations by itself, which is not implemented.
- Changed: when a disc has more files than the directory cache holds (600), the files of a load list are now looked up in one pass over the directory instead of one pass per file.
- Fixed: a request for a CD audio track that does not exist on the disc started playback at the very beginning of the disc. It is now ignored.

## 2.4

Sound. Found by running the same games under an original BIOS and under this one in the same emulator, and comparing what reaches the sound hardware.

- Fixed: the sound driver is now told to initialise itself (command 3, sent twice) after the sound CPU is started, as a console does. Without it a driver that waits for that command stays silent. This is the suspected cause of a report that Last Resort has neither music nor sound effects; that game was not available for testing.
- Fixed: a sample map passed to `BIOSF_UPLOAD` (type 5) was ignored when the length field was zero. Games leave it at zero; the records are now read until one starts with `0000` or `FFFF`.
- Fixed: `BIOSF_UPLOAD` now advances the source pointer as well as the destination, so a game can upload a long block in consecutive calls.
- Changed: in hardware mode the whole sample memory is filled with `08` (silence) before the game is loaded. It used to be left at zero.

## 2.3

- Fixed: Raine 0.98 could not start a game. Current Raine versions load the game themselves and then start the BIOS at `BIOSF_RESETGAME` (`$C00582`) without patching it, so the BIOS took itself to be on real CD hardware and waited for a drive that Raine does not emulate. The BIOS now recognises this way of starting.
- Fixed: sprite data sent with `BIOSF_UPLOAD` appeared garbled in Raine 0.98 (the title logo of The King of Fighters '94). Sprite memory is now written in whole words; Raine places single bytes differently.
- Changed: when the emulator loads the files but does not perform uploads itself (Raine 0.98), `BIOSF_UPLOAD` goes through the transfer window as in hardware mode.

## 2.2

- Fixed: in hardware mode the game's vertical blank handler could run while the BIOS was still loading the game, on emulators that deliver the vertical blank regardless of the interrupt mask the BIOS sets. The handler then ran in a half-loaded program, and the result was a hang at the loading screen or `SYSTEM HALT - EXCEPTION` (reported with a MAME-based system: vector 04, program counter in the stack area). The BIOS now takes over the vertical blank vector for the whole load and gives it back afterwards, as a console does, and no longer relies on the interrupt level or the mask register for this.
- Fixed: while a program file is loaded over the vector table, the CD interrupt vectors are no longer overwritten even for a moment, and the program's vertical blank vector takes effect only when loading has finished.
- Fixed: the vector number on the exception screen was printed on top of the word EXCEPTION ("EXCEPT04N"). It now follows the text.

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
