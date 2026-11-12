|============================================================================
| OpenNCD BIOS  -  an original, clean-room system ROM for emulated
|                  NEOGEO CD hardware
|
| SPDX-License-Identifier: Zlib
| Copyright (c) 2026 Imaha486
|
| Written from scratch against public documentation (NeoGeo Development
| Wiki), the hardware behaviour documented in open-source emulators and
| the observable behaviour of games and emulators.  No code or data from
| any SNK system ROM (or patched derivative) is contained here.
| See docs/CLEANROOM.md.
|
| Assembler: GNU as (m68k), flags: -m68000 --register-prefix-optional
|============================================================================

|---------------------------------------------------------------------------
| Hardware registers
|---------------------------------------------------------------------------
        .equ    REG_P1CNT,      0x300000
        .equ    REG_WATCHDOG,   0x300001
        .equ    REG_SOUND,      0x320000
        .equ    REG_P2CNT,      0x340000
        .equ    REG_STATUS_B,   0x380000
        .equ    VRAM_ADDR,      0x3C0000
        .equ    VRAM_RW,        0x3C0002
        .equ    VRAM_MOD,       0x3C0004
        .equ    REG_LSPCMODE,   0x3C0006
        .equ    REG_IRQACK,     0x3C000C
        .equ    PALETTES,       0x400000
        .equ    PAL_BACKDROP,   0x401FFE
        .equ    MEMCARD,        0x800000
        .equ    UPLOAD_ZONE,    0xE00000
        .equ    REG_CDIRQ,      0xFF0002
        .equ    REG_TRANSAREA,  0xFF0105
        .equ    REG_DISBLSPR,   0xFF0111
        .equ    REG_DISBLFIX,   0xFF0115
        .equ    REG_ENVIDEO,    0xFF0119
        .equ    REG_CDCONFIG,   0xFF011C
        .equ    REG_UPLOAD_EN,  0xFF016F
        .equ    REG_Z80RST,     0xFF0183

|---------------------------------------------------------------------------
| Game program header (loaded from disc at address 0)
|---------------------------------------------------------------------------
        .equ    HDR_CDDAFLAG,   0x107
        .equ    HDR_NGH,        0x108
        .equ    HDR_EYECATCH,   0x114
        .equ    HDR_DIP_JP,     0x116
        .equ    HDR_USER,       0x122
        .equ    HDR_PLAYER_START, 0x128
        .equ    HDR_DEMO_END,   0x12E
        .equ    HDR_COIN_SOUND, 0x134
        .equ    HDR_Z80CDDA,    0x13A

|---------------------------------------------------------------------------
| Documented system RAM
|---------------------------------------------------------------------------
        .equ    SYS_STACK,          0x10F300
        .equ    BIOS_SYSTEM_MODE,   0x10FD80
        .equ    BIOS_SYSRET_STATUS, 0x10FD81
        .equ    BIOS_MVS_FLAG,      0x10FD82
        .equ    BIOS_COUNTRY_CODE,  0x10FD83
        .equ    BIOS_GAME_DIP,      0x10FD84
        .equ    BIOS_P1STATUS,      0x10FD94
        .equ    BIOS_P2STATUS,      0x10FD9A
        .equ    BIOS_P3STATUS,      0x10FDA0
        .equ    BIOS_STATCURNT,     0x10FDAC
        .equ    BIOS_STATCHANGE,    0x10FDAD
        .equ    BIOS_USER_REQUEST,  0x10FDAE
        .equ    BIOS_USER_MODE,     0x10FDAF
        .equ    BIOS_CREDIT_DEC,    0x10FDB0
        .equ    BIOS_START_FLAG,    0x10FDB4
        .equ    BIOS_PLAYER_MOD1,   0x10FDB6
        .equ    BIOS_PLAYER_MOD2,   0x10FDB7
        .equ    BIOS_MESS_POINT,    0x10FDBE
        .equ    BIOS_MESS_BUSY,     0x10FDC2
        .equ    BIOS_CARD_COMMAND,  0x10FDC4
        .equ    BIOS_CARD_ANSWER,   0x10FDC6
        .equ    BIOS_CARD_START,    0x10FDC8
        .equ    BIOS_CARD_SIZE,     0x10FDCC
        .equ    BIOS_CARD_FCB,      0x10FDCE
        .equ    BIOS_CARD_SUB,      0x10FDD0
        .equ    BIOS_LOADANIM,      0x10FDDC    | non-zero: show loading screen
        .equ    BIOS_FRAME_COUNTER, 0x10FE88
        .equ    BIOS_UPZONE,        0x10FEDA
        .equ    BIOS_UPBANK,        0x10FEDB
        .equ    BIOS_STATCURNT_RAW, 0x10FEDC
        .equ    BIOS_STATCHANGE_RAW,0x10FEDD
        .equ    BIOS_UPDEST,        0x10FEF4
        .equ    BIOS_UPSRC,         0x10FEF8
        .equ    BIOS_UPSIZE,        0x10FEFC
        .equ    BIOS_MESS_BUFFER,   0x10FF00

| CD related cells that the emulator and/or games look at
        .equ    CD_PROGRESS,        0x10F690    | word, 0..0x80 while loading
        .equ    CD_READY,           0x10F6D9    | non-zero: drive idle
        .equ    CD_GAME_VBL,        0x10F6EE    | game's level 2 vector
        .equ    CD_CDDA_CMD,        0x10F6F6    | CDDA command latch
        .equ    CD_CDDA_TRACK,      0x10F6F8    | CDDA track (BCD)
        .equ    CD_FILE_TABLE,      0x115A06    | 32 bytes per file to load

|---------------------------------------------------------------------------
| Private work RAM of this BIOS
|---------------------------------------------------------------------------
        .equ    PV_BASE,        0x10FA00
        .equ    PV_STATE,       PV_BASE+0x00    | 0: USER(0) running, 1: later
        .equ    PV_CDDA_ADDR,   PV_BASE+0x02    | Z80 RAM address of CDDA pair
        .equ    PV_CDDA_LAST,   PV_BASE+0x04    | last pair seen
        .equ    PV_BACKDROP,    PV_BASE+0x06    | saved backdrop colour
        .equ    PV_ANIM,        PV_BASE+0x08    | loading screen frame counter
        .equ    PV_CARDTMP,     PV_BASE+0x10    | scratch for CARD
        .equ    PV_MSTACK,      PV_BASE+0x40    | MESS_OUT sub-list stack
        .equ    PV_MSTACK_END,  PV_BASE+0x60
        .equ    PV_BOOTED,      PV_BASE+0x01    | first start-up finished
        .equ    PV_SIZE,        0x100
        .equ    PV_MAGIC,       PV_BASE+0xF0    | marks emulator-assisted loading
        .equ    MAGIC_HLE,      0x4F4E4344

| memory card geometry (8 KiB battery RAM, one byte per odd address)
        .equ    CARD_DIR,       0x040           | 128 entries of 4 bytes
        .equ    CARD_DIR_N,     128
        .equ    CARD_FAT1,      0x240
        .equ    CARD_FAT2,      0x2C0
        .equ    CARD_NBLK,      128
        .equ    CARD_FIRSTBLK,  13

|===========================================================================
        .text
        .org    0
rom_start:
|---------------------------------------------------------------------------
| Exception vector table.  The emulator copies the first 0x80 bytes into
| RAM whenever a program selects the "system" vector table.
|---------------------------------------------------------------------------
        .long   SYS_STACK               |  0 initial SSP
        .long   jt_reset                |  1 reset
        .long   jt_exc_bus              |  2
        .long   jt_exc_addr             |  3
        .long   jt_exc_ill              |  4
        .long   jt_exc_gen2             |  5 zero divide
        .long   jt_exc_gen2             |  6 CHK
        .long   jt_exc_gen2             |  7 TRAPV
        .long   jt_exc_gen1             |  8 privilege
        .long   jt_exc_trace            |  9 trace
        .long   jt_exc_gen2             | 10
        .long   jt_exc_gen2             | 11
        .long   jt_exc_gen2             | 12
        .long   jt_exc_gen2             | 13
        .long   jt_exc_gen2             | 14
        .long   jt_exc_uninit           | 15
        .long   jt_exc_r16              | 16
        .long   jt_exc_r17              | 17
        .long   jt_exc_r18              | 18
        .long   jt_exc_r19              | 19
        .long   jt_exc_r20              | 20
        .long   jt_cdirq21              | 21 CD decoder
        .long   jt_cdirq22              | 22 CD comm
        .long   jt_cdirq23              | 23
        .long   jt_spurious             | 24 spurious
        .long   irq_timer               | 25 level 1 : raster timer
        .long   irq_vblank              | 26 level 2 : vertical blank
        .long   irq_ignore              | 27 level 3
        .long   irq_ignore              | 28
        .long   irq_ignore              | 29
        .long   irq_ignore              | 30
        .long   irq_ignore              | 31
        .rept   32
        .long   jt_exc_gen2             | 32-63 traps / reserved
        .endr

|---------------------------------------------------------------------------
| Identification
|---------------------------------------------------------------------------
        .org    0x100
        .ascii  "OpenNCD BIOS 2.1 - clean-room CD system ROM for emulators. "
        .ascii  "Original work, contains no SNK code. "
        .balign 2

|---------------------------------------------------------------------------
| System type / jump table.  Every slot is 6 bytes (jmp abs.l).
|---------------------------------------------------------------------------
        .org    0x400
        .byte   0x00                    | 0x00 = home system
        .byte   0x00                    | nationality is read from hardware

        .macro  SLOT target
        jmp     (\target).l
        .endm
        .macro  RTSLOTS n
        .rept   \n
        jmp     (ret_rts).l
        .endr
        .endm

jt_reset:       SLOT soft_reset         | C00402
jt_exc_bus:     SLOT exc_bus            | C00408
jt_exc_addr:    SLOT exc_addr           | C0040E
jt_exc_ill:     SLOT exc_ill            | C00414
jt_exc_gen1:    SLOT exc_gen1           | C0041A
jt_exc_trace:   SLOT exc_trace          | C00420
jt_exc_gen2:    SLOT exc_gen2           | C00426
jt_exc_uninit:  SLOT exc_uninit         | C0042C
                SLOT exc_gen2           | C00432
                SLOT system_int1        | C00438 SYSTEM_INT1
                SLOT system_int2        | C0043E SYSTEM_INT2
                SLOT system_return      | C00444 SYSTEM_RETURN
                SLOT system_io          | C0044A SYSTEM_IO
                SLOT credit_check       | C00450 CREDIT_CHECK
                SLOT credit_down        | C00456 CREDIT_DOWN
                SLOT ret_rts            | C0045C READ_CALENDAR (no RTC)
                SLOT ret_rts            | C00462 SETUP_CALENDAR
                SLOT card               | C00468 CARD
                SLOT card_error         | C0046E CARD_ERROR
                SLOT ret_rts            | C00474 HOW_TO_PLAY
                SLOT ret_rts            | C0047A CHECKSUM
                RTSLOTS 11              | C00480-C004BC
                SLOT fix_clear          | C004C2 FIX_CLEAR
                SLOT lsp_1st            | C004C8 LSP_1st
                SLOT mess_out           | C004CE MESS_OUT
                SLOT controller_setup   | C004D4 CONTROLLER_SETUP
                SLOT irq_timer          | C004DA raster timer service
jt_spurious:    SLOT irq_ignore         | C004E0
jt_cdirq23:     SLOT irq_cd_spare        | C004E6
jt_cdirq22:     SLOT irq_cd_link          | C004EC
jt_cdirq21:     SLOT irq_cd_sector        | C004F2
                RTSLOTS 7               | C004F8-C0051C
jt_exc_r16:     SLOT exc_gen2           | C00522
jt_exc_r17:     SLOT exc_gen2           | C00528
jt_exc_r18:     SLOT exc_gen2           | C0052E
jt_exc_r19:     SLOT exc_gen2           | C00534
jt_exc_r20:     SLOT exc_gen2           | C0053A
                SLOT ret_rts            | C00540
                SLOT biosf_upload       | C00546 BIOSF_UPLOAD
                SLOT ret_rts            | C0054C
                SLOT biosf_loadfile     | C00552 BIOSF_LOADFILE
                SLOT ret_rts            | C00558
                SLOT biosf_cdplayer     | C0055E BIOSF_CDPLAYER
                SLOT biosf_loadfilex    | C00564 BIOSF_LOADFILEX
                SLOT biosf_cddacmd      | C0056A BIOSF_CDDACMD
                SLOT biosf_videoen      | C00570 BIOSF_VIDEOEN
                SLOT sound_command      | C00576 send a byte to the sound CPU
                SLOT ret_rts            | C0057C BIOSF_SETCDDMODE
                SLOT soft_reset         | C00582 BIOSF_RESETGAME
                RTSLOTS 63              | C00588-C006FC

ret_rts:
        rts

| d0.b = command for the sound program
sound_command:
        move.b  d0,(0x320000).l
        rts

|===========================================================================
| Interrupt service
|===========================================================================
irq_ignore:
        rte

| level 1 on CD hardware: raster timer
irq_timer:
system_int2:
        move.w  #2,REG_IRQACK
        rte

| level 2 on CD hardware: vertical blank (only used while the system
| vector table is selected; games normally own the vector)
irq_vblank:
        tst.b   BIOS_SYSTEM_MODE
        bpl     system_int1
        move.l  CD_GAME_VBL,-(sp)       | game owns the vblank
        rts

|---------------------------------------------------------------------------
| SYSTEM_INT1 : vblank handling while the system owns the display
|---------------------------------------------------------------------------
system_int1:
        movem.l d0-d7/a0-a6,-(sp)
        move.w  #4,REG_IRQACK
        move.b  d0,REG_WATCHDOG
        bsr     system_io
        bsr     mess_out
        movem.l (sp)+,d0-d7/a0-a6
        rte

|===========================================================================
| Boot
|===========================================================================
| Reset vector.  Emulators that load the game themselves never come here
| first: they start at boot_entry, which leaves a mark in RAM.
| A program running in user mode may come here too: the privilege
| exception raised by the first instruction is recognised in exc_show and
| execution continues here in supervisor mode.
soft_reset:
sup_gate:
        move.w  #0x2700,sr
        lea     SYS_STACK,sp
        move.b  d0,REG_WATCHDOG
        cmp.l   #MAGIC_HLE,PV_MAGIC
        beq     hle_boot
        cmp.w   #0x4E71,(hle_patch).l   | such emulators patch this spot
        bne     hle_boot
        bsr     pv_clear
        clr.b   REG_UPLOAD_EN
        clr.l   CD_GAME_VBL
        bsr     lle_boot                | read the game from the disc ourselves
        bra     boot

| entered from boot_entry
hle_boot:
        move.w  #0x2700,sr
        lea     SYS_STACK,sp
        bsr     pv_clear
        move.l  #MAGIC_HLE,PV_MAGIC
        st      PV_HLE
        bra     boot

pv_clear:
        lea     PV_BASE,a0
        moveq   #PV_SIZE/4-1,d0
1:      clr.l   (a0)+
        dbra    d0,1b
        rts

boot:
        move.w  #0x2700,sr
        lea     SYS_STACK,sp
        move.b  d0,REG_WATCHDOG

        | hardware defaults
        clr.b   REG_UPLOAD_EN           | interrupts may be delivered
        clr.b   REG_DISBLSPR
        clr.b   REG_DISBLFIX
        move.b  #1,REG_ENVIDEO
        move.w  #7,REG_IRQACK
        move.w  #0,REG_LSPCMODE

        | clear documented system RAM and our private area
        lea     BIOS_SYSTEM_MODE,a0
        move.w  #(0x10FE80-0x10FD80)/4-1,d0
1:      clr.l   (a0)+
        dbra    d0,1b
        addq.l  #8,a0                   | 0x10FE80-0x10FE87 belong to the loader
        move.w  #(0x10FF00-0x10FE88)/4-1,d0
5:      clr.l   (a0)+
        dbra    d0,5b
        move.l  #BIOS_MESS_BUFFER,BIOS_MESS_POINT
        move.b  #1,CD_READY
        bsr     init_sysvars

        | nationality from the configuration port
        move.w  REG_CDCONFIG,d0
        tst.b   PV_HLE
        bne     6f
        not.w   d0                      | real port: active low
6:      lsr.w   #8,d0
        and.w   #3,d0
        cmp.w   #3,d0
        bne     3f
        moveq   #2,d0
3:
        move.b  d0,BIOS_COUNTRY_CODE
        clr.b   BIOS_MVS_FLAG

        bsr     controller_setup
        bsr     setup_soft_dips
        bsr     setup_cdda_method
        bsr     card_boot_check

        | make sure the game's vblank vector is known
        tst.l   CD_GAME_VBL
        bne     4f
        move.l  (0x68).w,CD_GAME_VBL
4:
        | clean display
        bsr     fix_clear
        bsr     lsp_1st

        | (re)start the sound CPU with the driver loaded from disc
        clr.b   REG_Z80RST
        move.b  d0,REG_WATCHDOG
        move.b  #0xFF,REG_Z80RST

        | USER request 0 : game initialisation
        clr.b   PV_STATE
        st      PV_BOOTED
        clr.b   BIOS_USER_REQUEST
        clr.b   BIOS_USER_MODE
        clr.b   BIOS_SYSTEM_MODE
        lea     SYS_STACK,sp
        jmp     (HDR_USER).w

|---------------------------------------------------------------------------
| values the system work area holds on a running console
init_sysvars:
        lea     sysvar_list(pc),a0
1:      move.w  (a0)+,d0
        beq     2f
        lea     (0x100000).l,a1
        adda.w  d0,a1                   | (offsets above 0x7FFF are negative:
        adda.l  #0x10000,a1             |  correct for the sign extension)
        move.b  (a0)+,(a1)
        addq.l  #1,a0
        bra     1b
2:      rts
sysvar_list:                            | address - 0x100000, value, pad
        .word   0xF781, 0x0100
        .word   0xF785, 0x4900
        .word   0xFE04, 0x8000
        .word   0xFE0E, 0x0100
        .word   0xFE0F, 0x0F00
        .word   0xFE10, 0x1400
        .word   0xFE12, 0x1800
        .word   0xFE14, 0x1A00
        .word   0xFE16, 0x1C00
        .word   0xFE1F, 0x2000
        .word   0xFEBB, 0x0100
        .word   0xFEBD, 0x0200
        .word   0xFEBE, 0x0100
        .word   0xFEC7, 0x1000          | pointer 0x0010FECA at 0x10FEC6
        .word   0xFEC8, 0xFE00
        .word   0xFEC9, 0xCA00
        .word   0xFEDF, 0x0200
        .word   0xFEE1, 0x0A00
        .word   0

|---------------------------------------------------------------------------
| SYSTEM_RETURN : the game hands control back after a USER request
|---------------------------------------------------------------------------
system_return:
        move.w  #0x2700,sr
        lea     SYS_STACK,sp
        move.b  d0,REG_WATCHDOG
        tst.b   PV_STATE
        bne     start_demo
        move.b  #1,PV_STATE
        cmp.b   #1,(HDR_EYECATCH).w       | game supplies its own boot logo?
        bne     start_demo
        move.b  #1,BIOS_USER_REQUEST
        clr.b   BIOS_USER_MODE
        move.b  #0x80,BIOS_SYSTEM_MODE
        jmp     (HDR_USER).w

start_demo:
        move.b  #2,BIOS_USER_REQUEST
        move.b  #1,BIOS_USER_MODE
        move.b  #0x80,BIOS_SYSTEM_MODE
        clr.b   BIOS_START_FLAG
        jmp     (HDR_USER).w

|---------------------------------------------------------------------------
| software DIP defaults -> BIOS_GAME_DIP
|   table: +0x10 two BCD time words, +0x14 two count bytes,
|          +0x16 ten bytes (high nibble = default choice)
|---------------------------------------------------------------------------
setup_soft_dips:
        moveq   #0,d0
        move.b  BIOS_COUNTRY_CODE,d0
        lsl.w   #2,d0
        lea     (HDR_DIP_JP).w,a0
        move.l  (a0,d0.w),d0
        beq     9f
        btst    #0,d0
        bne     9f
        cmp.l   #0x200000,d0
        bcc     9f
        movea.l d0,a0
        lea     16(a0),a0
        lea     BIOS_GAME_DIP,a1
        moveq   #5,d0
1:      move.b  (a0)+,(a1)+
        dbra    d0,1b
        moveq   #9,d0
2:      move.b  (a0)+,d1
        lsr.b   #4,d1
        move.b  d1,(a1)+
        dbra    d0,2b
9:      rts

|---------------------------------------------------------------------------
| Which Z80 RAM cell (if any) carries CD-DA requests of the sound driver
|---------------------------------------------------------------------------
setup_cdda_method:
        moveq   #0,d0
        move.b  (HDR_CDDAFLAG).w,d1
        and.b   #0x7F,d1
        cmp.b   #2,d1
        bcc     1f
        move.w  #0xFEF8,d0              | default cell
        bra     2f
1:      move.w  (HDR_Z80CDDA).w,d0
        cmp.w   #0xFFFF,d0
        bne     2f
        move.w  #0xFEF8,d0
2:      move.w  d0,PV_CDDA_ADDR
        clr.w   PV_CDDA_LAST
        rts

|===========================================================================
| SYSTEM_IO : inputs, frame counter, CD-DA requests, start buttons
|===========================================================================
system_io:
        lea     BIOS_P1STATUS,a0
        move.b  REG_P1CNT,d0
        bsr     io_player
        lea     BIOS_P2STATUS,a0
        move.b  REG_P2CNT,d0
        bsr     io_player

        move.b  REG_STATUS_B,d0
        not.b   d0
        and.b   #0x0F,d0                | P2 sel, P2 start, P1 sel, P1 start
        move.b  BIOS_STATCURNT,d1
        move.b  d0,BIOS_STATCURNT
        move.b  d0,BIOS_STATCURNT_RAW
        not.b   d1
        and.b   d0,d1
        move.b  d1,BIOS_STATCHANGE
        move.b  d1,BIOS_STATCHANGE_RAW

        addq.l  #1,BIOS_FRAME_COUNTER
        addq.b  #1,(0x10F749).l         | games seed random numbers from this
        tst.b   PV_HLE                  | (otherwise the drive service does it)
        beq     3f
        bsr     cd_heartbeat
3:
        move.w  d1,-(sp)
        bsr     cdda_poll
        move.w  (sp)+,d1

        | start buttons (home system: no credits involved)
        tst.b   BIOS_USER_MODE
        beq     9f
        moveq   #0,d2
        btst    #0,d1
        beq     1f
        cmp.b   #1,BIOS_PLAYER_MOD1
        beq     1f
        bset    #0,d2
1:      btst    #2,d1
        beq     2f
        cmp.b   #1,BIOS_PLAYER_MOD2
        beq     2f
        bset    #1,d2
2:      tst.b   d2
        beq     9f
        move.b  d2,BIOS_START_FLAG
        jsr     (HDR_PLAYER_START).w
9:      rts

| Two counters that climb together while the drive is working.  Some games
| watch the second one and report a disc error if it never moves.
cd_heartbeat:
        addq.b  #1,(0x10FE84).l
        bne     1f
        clr.b   (0x10FE85).l
1:      addq.b  #1,(0x10FE85).l
        rts

| a0 = player block (status, previous, current, change, repeat, timer)
| d0 = raw port value (active low)
io_player:
        not.b   d0
        move.b  2(a0),d1
        move.b  d1,1(a0)
        move.b  d0,2(a0)
        move.b  d1,d2
        not.b   d2
        and.b   d0,d2
        move.b  d2,3(a0)
        cmp.b   d0,d1
        beq     1f
        move.b  d2,4(a0)                | state changed: restart repeat
        move.b  #16,5(a0)
        rts
1:      tst.b   d0
        beq     2f
        subq.b  #1,5(a0)
        bne     2f
        move.b  d0,4(a0)
        move.b  #8,5(a0)
        rts
2:      clr.b   4(a0)
        rts

|---------------------------------------------------------------------------
| CONTROLLER_SETUP : standard pads on both ports
|---------------------------------------------------------------------------
controller_setup:
        move.b  #1,BIOS_P1STATUS
        move.b  #1,BIOS_P2STATUS
        clr.b   BIOS_P3STATUS
        clr.b   BIOS_P3STATUS+6
        rts

|---------------------------------------------------------------------------
| credits do not exist on a home system
|---------------------------------------------------------------------------
credit_check:
credit_down:
        rts

|===========================================================================
| CD-DA
|===========================================================================
| BIOSF_CDDACMD : d0.w = command.b : track.b (BCD)
biosf_cddacmd:
        move.w  d0,-(sp)
        bsr     cdda_issue
        move.w  (sp)+,d0
        rts

cdda_issue:
        tst.b   PV_HLE
        bne     1f
        bra     cda_request
1:      move.b  d0,CD_CDDA_TRACK
        lsr.w   #8,d0
        move.b  d0,CD_CDDA_CMD          | the drive acts on this write
        rts

| The sound driver of many games leaves a command/track pair in Z80 RAM.
| Fetch it through the transfer window and forward any change.
cdda_poll:
        moveq   #0,d0
        move.w  PV_CDDA_ADDR,d0
        beq     9f
        tst.l   BIOS_UPSIZE             | a transfer is being prepared
        bne     9f
        tst.b   WIN_BUSY
        bne     9f
        move.b  #4,REG_TRANSAREA        | window -> Z80 RAM
        add.l   d0,d0
        lea     UPLOAD_ZONE+1,a0
        adda.l  d0,a0
        tst.b   PV_HLE
        beq     3f
        | emulator-assisted mode: watch for a change
        move.b  (a0),d1
        lsl.w   #8,d1
        move.b  2(a0),d1
        cmp.w   PV_CDDA_LAST,d1
        beq     9f
        move.w  d1,PV_CDDA_LAST
        move.w  d1,d0
        bra     cdda_issue
        | hardware mode: take the request and clear it, which is what the
        | sound program expects before it posts the next one
3:      move.b  d0,REG_BUSREQ_Z80
        move.b  (a0),d1
        lsl.w   #8,d1
        move.b  2(a0),d1
        cmp.w   #0xFF00,d1              | command 0xFF: nothing posted
        bcc     8f
        tst.w   d1
        beq     8f
        btst    #9,d1                   | a play request needs a track
        bne     4f
        tst.b   d1
        beq     8f
4:      clr.b   (a0)
        clr.b   2(a0)
        move.b  d0,REG_BUSREL_Z80
        and.w   #0x7FFF,d1              | the top bit only marks it as new
        cmp.w   #0x0800,d1
        bcc     9f
        move.w  d1,d0
        bra     cdda_issue
8:      move.b  d0,REG_BUSREL_Z80
9:      rts

|===========================================================================
| Display helpers
|===========================================================================
| FIX_CLEAR : blank the text layer (tile 0xFF), side columns get tile 0x20
fix_clear:
        move.w  #0x7000,VRAM_ADDR
        move.w  #1,VRAM_MOD
        moveq   #39,d0                  | column
1:      move.w  #0x00FF,d1
        tst.w   d0
        beq     2f
        cmp.w   #39,d0
        bne     3f
2:      move.w  #0x0020,d1
3:      moveq   #31,d2
4:      move.w  d1,VRAM_RW
        dbra    d2,4b
        dbra    d0,1b
        rts

| LSP_1st : park every sprite
lsp_1st:
        move.w  #1,VRAM_MOD
        move.w  #0x8000,VRAM_ADDR       | SCB2 : full size
        move.w  #0x1FF,d0
1:      move.w  #0x0FFF,VRAM_RW
        dbra    d0,1b
        move.w  #0x8200,VRAM_ADDR       | SCB3 : height 0
        move.w  #0x1FF,d0
2:      move.w  #0x0000,VRAM_RW
        dbra    d0,2b
        move.w  #0x8400,VRAM_ADDR       | SCB4 : off screen
        move.w  #0x1FF,d0
3:      move.w  #0xBE00,VRAM_RW
        dbra    d0,3b
        move.w  #0x0000,VRAM_ADDR       | SCB1 of sprite 0
        moveq   #31,d0
4:      move.w  #0x00FF,VRAM_RW
        move.w  #0x0000,VRAM_RW
        dbra    d0,4b
        rts

| BIOSF_VIDEOEN : d0 bit0 = text layer, bit1 = sprites, bit2 = video
biosf_videoen:
        move.l  d1,-(sp)
        btst    #0,d0
        seq     d1
        and.b   #1,d1
        move.b  d1,REG_DISBLFIX
        btst    #1,d0
        seq     d1
        and.b   #1,d1
        move.b  d1,REG_DISBLSPR
        btst    #2,d0
        sne     d1
        and.b   #1,d1
        move.b  d1,REG_ENVIDEO
        move.l  (sp)+,d1
        rts

|===========================================================================
| MESS_OUT : interpret the message command buffer
|   d7 format flags (bit0 sized, bit1 words)   d6 upper byte for byte data
|   d5 end code / size                         d4 current VRAM address
|   a5 data pointer   a4 sub-list stack   a6 buffer cursor   a0 commands
|===========================================================================
mess_out:
        tst.b   BIOS_MESS_BUSY
        bne     ret_rts
        movem.l d0-d7/a0-a6,-(sp)
        lea     BIOS_MESS_BUFFER,a6
        moveq   #0,d7
        moveq   #0,d6
        move.w  #0x00FF,d5
        move.w  #0x7000,d4
        suba.l  a5,a5
1:      cmpa.l  BIOS_MESS_POINT,a6
        bcc     3f
        move.l  (a6)+,d0
        bne     2f
        movea.l a6,a0                   | commands stored in the buffer
        bsr     mess_run
        movea.l a0,a6
        bra     1b
2:      movea.l d0,a0
        bsr     mess_run
        bra     1b
3:      move.l  #BIOS_MESS_BUFFER,BIOS_MESS_POINT
        movem.l (sp)+,d0-d7/a0-a6
        rts

mess_run:
        lea     PV_MSTACK_END,a4
mess_next:
        move.w  (a0)+,d0
        move.w  d0,d1
        lsr.w   #8,d1                   | d1 = parameter byte
        and.w   #0x00FF,d0
        cmp.w   #0x0D,d0
        bhi     mess_end
        add.w   d0,d0
        move.w  mess_jt(pc,d0.w),d0
        jmp     mess_jt(pc,d0.w)
mess_jt:
        .word   mess_end-mess_jt        | 0 end of list
        .word   mess_fmt-mess_jt        | 1 data format
        .word   mess_inc-mess_jt        | 2 auto increment
        .word   mess_adr-mess_jt        | 3 VRAM address
        .word   mess_ptr-mess_jt        | 4 data address
        .word   mess_add-mess_jt        | 5 add to VRAM address
        .word   mess_res-mess_jt        | 6 output from data address
        .word   mess_inl-mess_jt        | 7 output inline data
        .word   mess_txt-mess_jt        | 8 8x16 text
        .word   mess_txt-mess_jt        | 9 8x16 text (alternate set)
        .word   mess_call-mess_jt       | A call sub-list
        .word   mess_ret-mess_jt        | B return
        .word   mess_rep-mess_jt        | C repeat word
        .word   mess_repi-mess_jt       | D repeat, incrementing
mess_end:
        rts

mess_fmt:
        move.w  d1,d7
        and.w   #3,d7
        move.w  (a0)+,d0
        btst    #1,d7
        bne     1f
        move.w  d0,d6
        and.w   #0xFF00,d6
        and.w   #0x00FF,d0
1:      move.w  d0,d5
        bra     mess_next

mess_inc:
        move.w  d1,VRAM_MOD
        bra     mess_next

mess_adr:
        move.w  (a0)+,d4
        move.w  d4,VRAM_ADDR
        bra     mess_next

mess_ptr:
        movea.l (a0)+,a5
        bra     mess_next

mess_add:
        add.w   (a0)+,d4
        move.w  d4,VRAM_ADDR
        bra     mess_next

mess_res:
        movea.l a5,a1
        bsr     mess_data
        movea.l a1,a5
        bra     mess_next

mess_inl:
        movea.l a0,a1
        bsr     mess_data
        move.l  a1,d0
        addq.l  #1,d0
        bclr    #0,d0
        movea.l d0,a0
        bra     mess_next

| write data at a1 according to the current format
mess_data:
        btst    #1,d7
        bne     mess_data_w
        btst    #0,d7
        bne     2f
1:      moveq   #0,d0                   | bytes until end code
        move.b  (a1)+,d0
        cmp.b   d5,d0
        beq     9f
        or.w    d6,d0
        move.w  d0,VRAM_RW
        bra     1b
2:      move.w  d5,d2                   | fixed number of bytes
        beq     9f
        subq.w  #1,d2
3:      moveq   #0,d0
        move.b  (a1)+,d0
        or.w    d6,d0
        move.w  d0,VRAM_RW
        dbra    d2,3b
9:      rts
mess_data_w:
        btst    #0,d7
        bne     2f
1:      move.w  (a1)+,d0                | words until end code
        cmp.w   d5,d0
        beq     9f
        move.w  d0,VRAM_RW
        bra     1b
2:      move.w  d5,d2
        beq     9f
        subq.w  #1,d2
3:      move.w  (a1)+,VRAM_RW
        dbra    d2,3b
9:      rts

| 8x16 text: parameter = font page, bytes up to 0xFF, two tiles per char
mess_txt:
        move.w  #0x20,VRAM_MOD
        lsl.w   #8,d1
1:      moveq   #0,d0
        move.b  (a0)+,d0
        cmp.b   #0xFF,d0
        beq     2f
        or.w    d1,d0
        move.w  d4,VRAM_ADDR
        move.w  d0,VRAM_RW
        addq.w  #1,d4
        add.w   #0x0100,d0
        move.w  d4,VRAM_ADDR
        move.w  d0,VRAM_RW
        add.w   #0x1F,d4                | next column, same row
        bra     1b
2:      move.w  d4,VRAM_ADDR
        move.l  a0,d0
        addq.l  #1,d0
        bclr    #0,d0
        movea.l d0,a0
        bra     mess_next

mess_call:
        cmpa.l  #PV_MSTACK,a4
        bls     mess_end
        movea.l (a0)+,a1
        move.l  a0,-(a4)
        movea.l a1,a0
        bra     mess_next

mess_ret:
        cmpa.l  #PV_MSTACK_END,a4
        bcc     mess_end
        movea.l (a4)+,a0
        bra     mess_next

mess_rep:
        move.w  (a0)+,d0
        subq.w  #1,d1
        bmi     mess_next
1:      move.w  d0,VRAM_RW
        dbra    d1,1b
        bra     mess_next

mess_repi:
        move.w  (a0)+,d0
        subq.w  #1,d1
        bmi     mess_next
1:      move.w  d0,VRAM_RW
        addq.b  #1,d0
        dbra    d1,1b
        bra     mess_next

|===========================================================================
| File transfer services
|===========================================================================
| BIOSF_UPLOAD : copy BIOS_UPSIZE bytes from BIOS_UPSRC to the memory area
| selected by BIOS_UPZONE / BIOS_UPBANK at BIOS_UPDEST.
biosf_upload:
        movem.l d0-d1/a0-a1,-(sp)
        tst.l   BIOS_UPSIZE
        beq     9f
        move.b  BIOS_UPZONE,d0
        move.b  d0,d1
        and.b   #0x0F,d1
        cmp.b   #8,d1                   | 8 = program area, like 0
        bne     1f
        and.b   #0xF0,d0
        move.b  d0,BIOS_UPZONE
        bra     5f
1:      cmp.b   #6,d1                   | 6 = palette RAM
        bne     5f
        movea.l BIOS_UPSRC,a0
        move.l  BIOS_UPDEST,d0
        and.l   #0x1FFE,d0
        lea     PALETTES,a1
        adda.l  d0,a1
        move.l  BIOS_UPSIZE,d0
        lsr.l   #1,d0
        beq     3f
2:      move.w  (a0)+,(a1)+
        subq.l  #1,d0
        bne     2b
3:      move.l  BIOS_UPSIZE,d0
        add.l   d0,BIOS_UPDEST
        clr.l   BIOS_UPSIZE
        bra     9f
5:      tst.b   PV_HLE
        bne     6f
        bsr     lle_upload
        bra     9f
6:      move.w  d0,UPLOAD_ZONE          | the transfer engine does the copy
        clr.l   BIOS_UPSIZE
9:      movem.l (sp)+,d0-d1/a0-a1
        rts

| BIOSF_LOADFILE / BIOSF_LOADFILEX
|   a0 -> list of { name,0 ; bank.b ; (pad to even) ; offset.l } ... 0
biosf_loadfile:
        movem.l d0-d7/a0-a6,-(sp)
        moveq   #1,d7                   | with loading screen
        bra     load_common
biosf_loadfilex:
        movem.l d0-d7/a0-a6,-(sp)
        moveq   #0,d7

load_common:
        move.b  d0,REG_WATCHDOG
        move.l  (0x68).w,d0             | note the game's vblank handler
        cmp.l   #rom_start,d0
        bcc     lc_batch
        move.l  d0,CD_GAME_VBL

| A list may be longer than the table: work through it in batches.  One
| slot always stays empty because the loading screen of some emulators
| uses the memory right behind a completely full table.
lc_batch:
        lea     CD_FILE_TABLE,a1
        move.w  #33*32/4-1,d0
1:      clr.l   (a1)+
        dbra    d0,1b

        lea     CD_FILE_TABLE,a1
        moveq   #30,d6                  | at most 31 files per batch
2:      tst.b   (a0)
        beq     6f
        movea.l a1,a2
        moveq   #14,d1
3:      move.b  (a0)+,d0
        beq     4f
        tst.w   d1
        bmi     3b                      | over-long name: drop the excess
        move.b  d0,(a2)+
        subq.w  #1,d1
        bra     3b
4:      move.b  (a0)+,16(a1)            | bank
        move.l  a0,d0
        addq.l  #1,d0
        bclr    #0,d0
        movea.l d0,a0
        move.l  (a0)+,18(a1)            | offset
        lea     32(a1),a1
        dbra    d6,2b

6:      tst.b   CD_FILE_TABLE
        beq     9f
        tst.b   PV_HLE
        bne     8f
        bsr     lle_load_table
        bra     5f
8:      move.w  PAL_BACKDROP,PV_BACKDROP
        move.w  VRAM_MOD,-(sp)          | the loading screen must not disturb
        clr.b   CD_READY
        move.b  d7,BIOS_LOADANIM
        move.w  #0x0550,REG_CDIRQ       | start the transfer
        nop
        tst.b   d7
        beq     7f
        move.w  PV_BACKDROP,PAL_BACKDROP
7:      move.w  (sp)+,VRAM_MOD
        clr.b   BIOS_LOADANIM
        move.b  #1,CD_READY
        clr.b   REG_UPLOAD_EN
5:      move.b  d0,REG_WATCHDOG
        tst.b   (a0)                    | more files in the list?
        bne     lc_batch
9:      move.b  #1,(0x10F6DB).l         | state games may look at afterwards
        move.b  #1,(0x10FEC4).l
        move.b  d0,REG_WATCHDOG
        movem.l (sp)+,d0-d7/a0-a6
        rts

| BIOSF_CDPLAYER : leave the game.  The emulator notices this parking
| spot and returns to its own user interface.
biosf_cdplayer:
        tst.b   PV_HLE
        beq     soft_reset              | no player here: start the disc again
        move.b  d0,REG_WATCHDOG
        jmp     (park).l
        nop
        .word   0x1B7C,0x0002,0x0000    | (landmark, see the end of this file)

|===========================================================================
| Loading screen (called by the emulator while it streams files)
|===========================================================================
        .equ    LS_ROW,     13
        .equ    LS_BARROW,  16
        .equ    LS_BARCOL,  4
        .equ    LS_BARLEN,  32

| a0 -> zero terminated text, d0 = VRAM address (column major)
ls_print:
        move.w  #0x20,VRAM_MOD
        move.w  d0,VRAM_ADDR
1:      moveq   #0,d0
        move.b  (a0)+,d0
        beq     2f
        move.w  d0,VRAM_RW
        bra     1b
2:      rts

load_screen_init:
        movem.l d0-d2/a0,-(sp)
        move.w  #0x8000,PAL_BACKDROP
        move.w  #1,VRAM_MOD
        move.w  #0x7000,VRAM_ADDR
        move.w  #40*32-1,d0
1:      move.w  #0x0020,VRAM_RW
        dbra    d0,1b
        lea     ls_text(pc),a0
        move.w  #0x7000+15*32+LS_ROW,d0
        bsr     ls_print
        lea     ls_name(pc),a0
        move.w  #0x7000+14*32+26,d0
        bsr     ls_print
        clr.w   PV_ANIM
        moveq   #0,d0
        bsr     ls_bar
        movem.l (sp)+,d0-d2/a0
        rts

load_screen_progress:
        movem.l d0-d2/a0,-(sp)
        moveq   #0,d0
        move.w  CD_PROGRESS,d0          | 0..0x80
        lsr.w   #2,d0
        bsr     ls_bar
        movem.l (sp)+,d0-d2/a0
        rts

| d0 = number of filled cells
ls_bar:
        cmp.w   #LS_BARLEN,d0
        bls     1f
        moveq   #LS_BARLEN,d0
1:      move.w  #0x20,VRAM_MOD
        move.w  #0x7000+LS_BARCOL*32+LS_BARROW,VRAM_ADDR
        moveq   #LS_BARLEN-1,d1
2:      move.w  #0x0010,d2              | empty cell
        tst.w   d0
        beq     3f
        subq.w  #1,d0
        move.w  #0x0011,d2              | filled cell
3:      move.w  d2,VRAM_RW
        dbra    d1,2b
        rts

load_screen_anim:
        movem.l d0-d2/a0,-(sp)
        move.w  PV_ANIM,d0
        addq.w  #1,d0
        move.w  d0,PV_ANIM
        lsr.w   #4,d0
        and.w   #3,d0                   | 0..3 dots after the text
        move.w  #0x20,VRAM_MOD
        move.w  #0x7000+22*32+LS_ROW,VRAM_ADDR
        moveq   #2,d1
1:      move.w  #0x0020,d2
        tst.w   d0
        beq     2f
        subq.w  #1,d0
        move.w  #0x002E,d2
2:      move.w  d2,VRAM_RW
        dbra    d1,1b
        movem.l (sp)+,d0-d2/a0
        rts

ls_text:
        .asciz  "LOADING"
ls_name:
        .asciz  "OPENNCD BIOS"
        .balign 2

|===========================================================================
| CARD : save data management on the internal battery RAM
|   layout: block 0 header, blocks 1-8 directory, 9-10 FAT, 11-12 FAT copy,
|           blocks 13.. data.  64 bytes per block.
|   directory entry: sub number, NGH (2 bytes), first block.  0xFF = free
|   FAT: 0 free, 1 last block, 2 reserved, other = next block
|===========================================================================
| a4 = card base (odd addresses carry the data)
        .macro  CARD_RD idx,dst         | idx: data register (word), trashed
        add.w   \idx,\idx
        move.b  (a4,\idx\().w),\dst
        .endm
        .macro  CARD_WR src,idx
        add.w   \idx,\idx
        move.b  \src,(a4,\idx\().w)
        .endm

card_magic:
        .byte   'N','E','O','-','G','E','O',0x80

| Z set when the card carries a valid format
card_valid:
        lea     MEMCARD+1,a4
        lea     card_magic(pc),a0
        moveq   #0x20,d1
        moveq   #7,d2
1:      move.w  d1,d0
        CARD_RD d0,d0
        cmp.b   (a0)+,d0
        bne     2f
        addq.w  #2,d1
        dbra    d2,1b
        moveq   #0,d0
2:      rts

card_boot_check:
        bsr     card_valid
        beq     1f
        bsr     card_format
1:      rts

card_format:
        lea     MEMCARD+1,a4
        moveq   #0,d1
1:      move.w  d1,d0                   | header block
        CARD_WR #0,d0
        addq.w  #1,d1
        cmp.w   #0x40,d1
        bne     1b
        moveq   #0x01,d0
        CARD_WR #0x05,d0
        moveq   #0x0A,d0
        CARD_WR #0x40,d0                | 0x4000 address units
        moveq   #0x0C,d0
        CARD_WR #0x02,d0
        moveq   #0x10,d1
2:      move.w  d1,d0                   | blank user name
        CARD_WR #0x20,d0
        addq.w  #1,d1
        cmp.w   #0x20,d1
        bne     2b
        lea     card_magic(pc),a0
        moveq   #0x20,d1
        moveq   #7,d2
3:      move.w  d1,d0
        move.b  (a0)+,d3
        CARD_WR d3,d0
        addq.w  #2,d1
        dbra    d2,3b
        moveq   #0x30,d0
        move.b  BIOS_COUNTRY_CODE,d3
        CARD_WR d3,d0
        move.w  #CARD_DIR,d1            | empty directory
4:      move.w  d1,d0
        CARD_WR #0xFF,d0
        addq.w  #1,d1
        cmp.w   #CARD_FAT1,d1
        bne     4b
        moveq   #0,d1                   | allocation table
5:      moveq   #2,d3
        cmp.w   #CARD_FIRSTBLK,d1
        bcs     6f
        moveq   #0,d3
6:      move.w  d1,d0
        add.w   #CARD_FAT1,d0
        CARD_WR d3,d0
        addq.w  #1,d1
        cmp.w   #CARD_NBLK,d1
        bne     5b
        | fall through

| copy FAT1 to FAT2 and refresh both checksums
card_sync_fat:
        moveq   #0,d1
        moveq   #0,d2
1:      move.w  d1,d0
        add.w   #CARD_FAT1,d0
        CARD_RD d0,d3
        add.b   d3,d2
        move.w  d1,d0
        add.w   #CARD_FAT2,d0
        CARD_WR d3,d0
        addq.w  #1,d1
        cmp.w   #CARD_NBLK,d1
        bne     1b
        moveq   #0x0D,d0
        CARD_WR d2,d0
        moveq   #0x0E,d0
        CARD_WR d2,d0
        rts

| find directory entry for BIOS_CARD_FCB / BIOS_CARD_SUB
| out: d5 = card index of the entry, Z set when found
card_find:
        move.w  #CARD_DIR,d5
        moveq   #CARD_DIR_N-1,d6
1:      move.w  d5,d0
        CARD_RD d0,d1
        cmp.b   BIOS_CARD_SUB,d1
        bne     2f
        move.w  d5,d0
        addq.w  #1,d0
        CARD_RD d0,d1
        cmp.b   BIOS_CARD_FCB,d1
        bne     2f
        move.w  d5,d0
        addq.w  #2,d0
        CARD_RD d0,d1
        cmp.b   BIOS_CARD_FCB+1,d1
        beq     3f
2:      addq.w  #4,d5
        dbra    d6,1b
        moveq   #1,d0                   | not found (Z clear)
3:      rts

| release the block chain starting at d4 and the entry d5
card_release:
        moveq   #CARD_NBLK-1,d6
1:      cmp.w   #CARD_FIRSTBLK,d4
        bcs     2f
        cmp.w   #CARD_NBLK,d4
        bcc     2f
        move.w  d4,d0
        add.w   #CARD_FAT1,d0
        moveq   #0,d3
        CARD_RD d0,d3
        move.w  d4,d0
        add.w   #CARD_FAT1,d0
        CARD_WR #0,d0
        move.w  d3,d4
        dbra    d6,1b
2:      move.w  d5,d0
        CARD_WR #0xFF,d0
        rts

| d4 = first free block at or after d4, C set if none
card_next_free:
1:      cmp.w   #CARD_NBLK,d4
        bcc     2f
        move.w  d4,d0
        add.w   #CARD_FAT1,d0
        CARD_RD d0,d1
        tst.b   d1
        beq     3f
        addq.w  #1,d4
        bra     1b
2:      ori     #1,ccr
        rts
3:      andi    #0xFE,ccr
        rts

card:
        movem.l d0-d7/a0-a6,-(sp)
        lea     MEMCARD+1,a4
        moveq   #0,d0
        move.b  BIOS_CARD_COMMAND,d0
        beq     card_cmd_format
        cmp.w   #7,d0
        bhi     card_ok
        move.w  d0,-(sp)
        bsr     card_valid
        movem.w (sp)+,d0                | keeps the flags
        beq     1f
        moveq   #0x81-0x100,d0          | not formatted
        bra     card_done
1:      add.w   d0,d0
        move.w  card_jt(pc,d0.w),d0
        jmp     card_jt(pc,d0.w)
card_jt:
        .word   card_cmd_format-card_jt
        .word   card_cmd_search-card_jt
        .word   card_cmd_load-card_jt
        .word   card_cmd_save-card_jt
        .word   card_cmd_delete-card_jt
        .word   card_cmd_title-card_jt
        .word   card_cmd_setname-card_jt
        .word   card_cmd_getname-card_jt

card_ok:
        moveq   #0,d0
card_done:
        move.b  d0,BIOS_CARD_ANSWER
        movem.l (sp)+,d0-d7/a0-a6
        rts
card_nodata:
        moveq   #0x82-0x100,d0
        bra     card_done
card_faterr:
        moveq   #0x83-0x100,d0
        bra     card_done
card_full:
        moveq   #0x84-0x100,d0
        bra     card_done

card_cmd_format:
        bsr     card_format
        bra     card_ok

| 1: which save numbers exist for this game -> bit mask in BIOS_CARD_SUB
card_cmd_search:
        moveq   #0,d7
        move.w  #CARD_DIR,d5
        moveq   #CARD_DIR_N-1,d6
1:      move.w  d5,d0
        addq.w  #1,d0
        CARD_RD d0,d1
        cmp.b   BIOS_CARD_FCB,d1
        bne     2f
        move.w  d5,d0
        addq.w  #2,d0
        CARD_RD d0,d1
        cmp.b   BIOS_CARD_FCB+1,d1
        bne     2f
        move.w  d5,d0
        moveq   #0,d1
        CARD_RD d0,d1
        cmp.w   #15,d1
        bhi     2f
        bset    d1,d7
2:      addq.w  #4,d5
        dbra    d6,1b
        move.w  d7,BIOS_CARD_SUB
        bra     card_ok

| 2: load BIOS_CARD_SIZE bytes to BIOS_CARD_START
card_cmd_load:
        bsr     card_find
        bne     card_nodata
        move.w  d5,d0
        addq.w  #3,d0
        moveq   #0,d4
        CARD_RD d0,d4                   | first block
        movea.l BIOS_CARD_START,a1
        move.w  BIOS_CARD_SIZE,d7
        beq     card_ok
1:      cmp.w   #CARD_FIRSTBLK,d4
        bcs     card_faterr
        cmp.w   #CARD_NBLK,d4
        bcc     card_faterr
        move.w  d4,d2
        lsl.w   #6,d2                   | card index of the block
        moveq   #63,d6
2:      move.w  d2,d0
        CARD_RD d0,d1
        move.b  d1,(a1)+
        addq.w  #1,d2
        subq.w  #1,d7
        beq     card_ok
        dbra    d6,2b
        move.w  d4,d0
        add.w   #CARD_FAT1,d0
        moveq   #0,d4
        CARD_RD d0,d4
        bra     1b

| 3: save BIOS_CARD_SIZE bytes from BIOS_CARD_START
card_cmd_save:
        | blocks needed
        moveq   #0,d7
        move.w  BIOS_CARD_SIZE,d7
        add.l   #63,d7
        lsr.l   #6,d7
        bne     2f
        moveq   #1,d7
2:      | free blocks
        moveq   #0,d2
        moveq   #CARD_FIRSTBLK,d4
3:      bsr     card_next_free
        bcs     4f
        addq.w  #1,d2
        addq.w  #1,d4
        bra     3b
4:      move.w  d2,-(sp)
        bsr     card_find               | an existing save gives its blocks back
        movem.w (sp)+,d2
        bne     7f
        move.w  d5,d0
        addq.w  #3,d0
        moveq   #0,d4
        CARD_RD d0,d4
        move.w  d4,d3                   | length of the old chain
        moveq   #CARD_NBLK-1,d6
5:      cmp.w   #CARD_FIRSTBLK,d3
        bcs     6f
        cmp.w   #CARD_NBLK,d3
        bcc     6f
        addq.w  #1,d2
        move.w  d3,d0
        add.w   #CARD_FAT1,d0
        moveq   #0,d3
        CARD_RD d0,d3
        dbra    d6,5b
6:      cmp.w   d7,d2
        bcs     card_full               | does not fit: the old save stays
        bsr     card_release
        bra     8f
7:      cmp.w   d7,d2
        bcs     card_full
8:
        | free directory entry
        move.w  #CARD_DIR,d5
        moveq   #CARD_DIR_N-1,d6
5:      move.w  d5,d0
        CARD_RD d0,d1
        cmp.b   #0xFF,d1
        beq     6f
        addq.w  #4,d5
        dbra    d6,5b
        bra     card_save_full
6:      | write entry
        moveq   #CARD_FIRSTBLK,d4
        bsr     card_next_free
        move.w  d5,d0
        move.b  BIOS_CARD_SUB,d1
        CARD_WR d1,d0
        move.w  d5,d0
        addq.w  #1,d0
        move.b  BIOS_CARD_FCB,d1
        CARD_WR d1,d0
        move.w  d5,d0
        addq.w  #2,d0
        move.b  BIOS_CARD_FCB+1,d1
        CARD_WR d1,d0
        move.w  d5,d0
        addq.w  #3,d0
        CARD_WR d4,d0
        | write the data, chaining blocks
        movea.l BIOS_CARD_START,a1
        moveq   #0,d5
        move.w  BIOS_CARD_SIZE,d5       | bytes left
7:      move.w  d4,d2
        lsl.w   #6,d2
        moveq   #63,d6
8:      moveq   #0,d1
        tst.w   d5
        beq     10f
        move.b  (a1)+,d1
        subq.w  #1,d5
10:     move.w  d2,d0
        CARD_WR d1,d0
        addq.w  #1,d2
        dbra    d6,8b
        move.w  d4,d3                   | current block
        subq.w  #1,d7
        beq     11f
        move.w  d3,d0                   | mark as used so the search skips it
        add.w   #CARD_FAT1,d0
        CARD_WR #1,d0
        addq.w  #1,d4
        bsr     card_next_free
        move.w  d3,d0
        add.w   #CARD_FAT1,d0
        CARD_WR d4,d0                   | link to the next block
        bra     7b
11:     move.w  d3,d0
        add.w   #CARD_FAT1,d0
        CARD_WR #1,d0                   | end of chain
        bsr     card_sync_fat
        bra     card_ok
card_save_full:
        bsr     card_sync_fat
        bra     card_full

| 4: delete
card_cmd_delete:
        bsr     card_find
        bne     card_nodata
        move.w  d5,d0
        addq.w  #3,d0
        moveq   #0,d4
        CARD_RD d0,d4
        bsr     card_release
        bsr     card_sync_fat
        bra     card_ok

| 5: copy the 20 byte title of a save to BIOS_CARD_START
card_cmd_title:
        bsr     card_find
        bne     card_nodata
        move.w  d5,d0
        addq.w  #3,d0
        moveq   #0,d4
        CARD_RD d0,d4
        lsl.w   #6,d4
        movea.l BIOS_CARD_START,a1
        moveq   #19,d6
1:      move.w  d4,d0
        CARD_RD d0,d1
        move.b  d1,(a1)+
        addq.w  #1,d4
        dbra    d6,1b
        bra     card_ok

| 6 / 7: owner name (16 bytes)
card_cmd_setname:
        movea.l BIOS_CARD_START,a1
        moveq   #0x10,d2
1:      move.w  d2,d0
        move.b  (a1)+,d1
        CARD_WR d1,d0
        addq.w  #1,d2
        cmp.w   #0x20,d2
        bne     1b
        moveq   #0x0F,d0
        CARD_WR #0xFF,d0
        bra     card_ok

card_cmd_getname:
        moveq   #0x0F,d0
        CARD_RD d0,d1
        tst.b   d1
        beq     card_nodata
        movea.l BIOS_CARD_START,a1
        moveq   #0x10,d2
1:      move.w  d2,d0
        CARD_RD d0,d1
        move.b  d1,(a1)+
        addq.w  #1,d2
        cmp.w   #0x20,d2
        bne     1b
        bra     card_ok

| CARD_ERROR : the battery RAM is formatted at boot, so the only automatic
| recovery left is formatting after a failed write on an unformatted card.
card_error:
        movem.l d0-d7/a0-a6,-(sp)
        cmp.b   #0x81,BIOS_CARD_ANSWER
        bne     1f
        bsr     card_format
1:      movem.l (sp)+,d0-d7/a0-a6
        rts

|===========================================================================
| Exception report
|===========================================================================
exc_bus:    moveq   #2,d7
            bra     exc_show
exc_addr:   moveq   #3,d7
            bra     exc_show
exc_ill:    moveq   #4,d7
            bra     exc_show
exc_gen1:   moveq   #8,d7
            bra     exc_show
exc_trace:  moveq   #9,d7
            bra     exc_show
exc_uninit: moveq   #15,d7
            bra     exc_show
exc_gen2:   moveq   #0,d7

exc_show:
        cmp.l   #sup_gate,2(sp)         | user mode program asked for a reset
        beq     sup_gate
        move.w  #0x2700,sr
        movea.l sp,a6                   | exception frame
        lea     SYS_STACK,sp
        clr.b   REG_DISBLFIX
        move.b  #1,REG_DISBLSPR
        move.b  #1,REG_ENVIDEO
        move.w  #0x8000,PALETTES
        move.w  #0x7FFF,PALETTES+2
        move.w  #0x0008,PAL_BACKDROP
        bsr     fix_clear
        lea     exc_text(pc),a0
        move.w  #0x7000+6*32+10,d0
        bsr     ls_print
        move.w  d7,d0                   | vector number
        move.w  #0x7000+26*32+10,d1
        moveq   #1,d2
        bsr     exc_hex
        moveq   #5,d6                   | six stack words
        move.w  #0x7000+6*32+12,d5
1:      move.w  (a6)+,d0
        move.w  d5,d1
        moveq   #3,d2
        bsr     exc_hex
        add.w   #5*32,d5
        dbra    d6,1b
2:      move.b  d0,REG_WATCHDOG
        bra     2b

| print d2+1 hex digits of d0 at VRAM address d1
exc_hex:
        move.w  #0x20,VRAM_MOD
        move.w  d1,VRAM_ADDR
        move.w  d2,d3
        addq.w  #1,d3
        lsl.w   #2,d3
        ror.l   d3,d0                   | wanted digits now at the top
1:      rol.l   #4,d0
        move.w  d0,d3
        and.w   #0x000F,d3
        move.b  exc_digits(pc,d3.w),d3
        move.w  d3,VRAM_RW
        dbra    d2,1b
        rts
exc_digits:
        .ascii  "0123456789ABCDEF"
exc_text:
        .asciz  "SYSTEM HALT - EXCEPTION"
        .balign 2


|===========================================================================
| 0x2000-0x42FF is reserved: the build script places the math and random
| tables there (games read them straight from the ROM, see tables.py)
|===========================================================================
        .org    0x2000                  | (assembly fails if the code above grows past this)
        .org    0x4300
        .include "cdsys.s"
        .balign 2

|===========================================================================
| Fixed entry points expected by the emulator
|===========================================================================
        .org    0xA822
boot_entry:
        lea     (PV_BASE).l,a5          | the emulator starts execution here
        jmp     (hle_boot).l

        .org    0xA87A
hle_patch:
        nop                             | six bytes the emulator overwrites
        nop
        nop

|---------------------------------------------------------------------------
| Landmarks.  Newer versions of one emulator do not use fixed addresses but
| look for particular byte sequences to find the loading screen routines,
| its palette and its tiles.  Nothing here is executed except the jumps.
|---------------------------------------------------------------------------
        .org    0xB000
        .long   0x0011C817
        .long   0x0011C817
        rts
        jmp     (load_screen_init).l
        rts
        rts
        jmp     (load_screen_progress).l
        rts
        jmp     (load_screen_anim).l
        nop
        nop
        .word   0x4A39
        .long   0x0011C817
        rts
        .long   0x7E7F22D8
        .word   0x2B7C
        .long   0x00004000
        .word   0x0000
        .word   0x41F9
        .long   rom_start+0x7C000
        .word   0x41F9
        .long   ls_palette
        .word   0x43F9
        .long   PALETTES
        .long   0x7E7F22D8
        rts
        .word   0x23FC
        .long   0x4E754E75
        .long   0x0011C810
        rts

        .org    0xC760
        jmp     (load_screen_init).l    | loading screen: set up

        .org    0xC814
        jmp     (load_screen_progress).l | loading screen: progress update

        .org    0xC8B2
        jmp     (load_screen_anim).l    | loading screen: once per frame

        .org    0xE602
park:   bra     park                    | emulator returns to its menu here

|---------------------------------------------------------------------------
| Palette used by the loading screen (16 palettes of 16 colours)
|---------------------------------------------------------------------------
        .org    0x1701C
ls_palette:
        .word   0x8000,0x7FFF,0x0555,0x4F90,0x0AAA,0x0000,0x0000,0x0000
        .word   0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000,0x0000
        .rept   15*16
        .word   0x0000
        .endr

        .org    0x1A000
rom_code_end:
