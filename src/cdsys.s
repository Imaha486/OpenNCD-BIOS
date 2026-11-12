|============================================================================
| OpenNCD BIOS - CD subsystem for emulators that model the real hardware
|
| SPDX-License-Identifier: Zlib
| Copyright (c) 2026 Imaha486
|
| (drive command link, sector decoder, transfer window).
|
| Register behaviour was taken from the documentation contained in the
| open-source emulators MAME, FinalBurn Neo and NeoCD (libretro) and from the
| NeoGeo Development Wiki.  Only operations that all three implement the same
| way are used.
|============================================================================

        .equ    REG_CDMASK,     0xFF0002        | 0x500 decoder irq, 0x050 link irq
        .equ    REG_VBLMASK,    0xFF0004        | 0x030 vblank, 0x300 timer
        .equ    REG_CDIRQACK,   0xFF000F        | 0x20 decoder, 0x10 link, 0x08 spare
        .equ    REG_DMA_GO,     0xFF0061
        .equ    REG_DMA_DEST,   0xFF0064
        .equ    REG_DMA_COUNT,  0xFF0070
        .equ    REG_DMA_PROG,   0xFF007E
        .equ    REG_LC_PTR,     0xFF0101
        .equ    REG_LC_DATA,    0xFF0103
        .equ    REG_BUSREQ_SPR, 0xFF0121
        .equ    REG_BUSREQ_PCM, 0xFF0123
        .equ    REG_BUSREQ_Z80, 0xFF0127
        .equ    REG_BUSREQ_FIX, 0xFF0129
        .equ    REG_BUSREL_SPR, 0xFF0141
        .equ    REG_BUSREL_PCM, 0xFF0143
        .equ    REG_BUSREL_Z80, 0xFF0147
        .equ    REG_BUSREL_FIX, 0xFF0149
        .equ    REG_CDD_IN,     0xFF0161
        .equ    REG_CDD_OUT,    0xFF0163
        .equ    REG_CDD_CTRL,   0xFF0165
        .equ    REG_VECTSEL,    0xFF016D        | 0x00 system table, 0xFF RAM table
        .equ    REG_CDD_ENABLE, 0xFF0181
        .equ    REG_SPRBANK,    0xFF01A1
        .equ    REG_PCMBANK,    0xFF01A3
        .equ    REG_SWPROM,     0x3A0013

| work buffers (only used in this mode)
        .equ    SECBUF,         0x112000        | one 2048 byte sector
        .equ    DIRCACHE,       0x116000        | 20 bytes per file
        .equ    DIRMAX,         600
        .equ    LS_SAVE,        0x119000        | saved screen state
        .equ    LS_TILES,       0x60            | text tiles replaced by the loading screen

| private variables (continued from bios.s)
        .equ    CD_TICK,        PV_BASE+0x80
        .equ    CD_CMDF,        PV_BASE+0x81
        .equ    CD_TXN,         PV_BASE+0x82    | 10 nibbles to send
        .equ    CD_RX,          PV_BASE+0x8C    | 10 nibbles received
        .equ    RD_ACTIVE,      PV_BASE+0x96
        .equ    RD_READY,       PV_BASE+0x97
        .equ    RD_MISS,        PV_BASE+0x98
        .equ    RD_MSF,         PV_BASE+0x9C
        .equ    RD_LBA,         PV_BASE+0xA0
        .equ    SINK_TYPE,      PV_BASE+0xA4
        .equ    SINK_POS,       PV_BASE+0xA8
        .equ    DIR_COUNT,      PV_BASE+0xAC
        .equ    LD_TOTAL,       PV_BASE+0xB0
        .equ    LD_DONE,        PV_BASE+0xB4
        .equ    CDA_STATE,      PV_BASE+0xB8
        .equ    CDA_TRACK,      PV_BASE+0xB9
        .equ    CDA_ONCE,       PV_BASE+0xBA
        .equ    CDA_TMR,        PV_BASE+0xBB
        .equ    CDA_START,      PV_BASE+0xBC
        .equ    CDA_END,        PV_BASE+0xC0
        .equ    CDA_RETRY,      PV_BASE+0xC4
        .equ    PV_HLE,         PV_BASE+0xC5    | non-zero: emulator loads files itself
        .equ    LS_ACTIVE,      PV_BASE+0xC6
        .equ    LS_TICK,        PV_BASE+0xC7
        .equ    LD_Z80,         PV_BASE+0xC8    | a sound program was loaded
        .equ    WIN_BUSY,       PV_BASE+0xC9    | transfer window in use
        .equ    CDA_REQF,       PV_BASE+0xCA
        .equ    CDA_REQ,        PV_BASE+0xCC
        .equ    DIR_LBA,        PV_BASE+0xE0    | root directory extent
        .equ    DIR_SECTORS,    PV_BASE+0xE4
        .equ    DIR_MORE,       PV_BASE+0xE8    | directory did not fit in the cache
        .equ    PAT_FILL,       PV_BASE+0xE9    | bytes in PAT_REC
        .equ    PAT_REC,        PV_BASE+0xEA    | one 10 byte record (..0xF3)
        .equ    DEFER_N,        PV_BASE+0xCF
        .equ    DEFER_LIST,     PV_BASE+0xD0    | up to 8 entry pointers

| file table entry (32 bytes, shared with the emulator-assisted loader)
        .equ    FE_NAME,        0
        .equ    FE_BANK,        16
        .equ    FE_OFFSET,      18
        .equ    FE_LBA,         22
        .equ    FE_SIZE,        26
        .equ    FE_TYPE,        30

        .equ    FT_PRG, 0
        .equ    FT_FIX, 1
        .equ    FT_SPR, 2
        .equ    FT_Z80, 3
        .equ    FT_PCM, 4
        .equ    FT_PAT, 5
        .equ    FT_NONE, 0xFF

| sector decoder registers
        .macro  LCW reg,val
        move.b  #\reg,REG_LC_PTR
        move.b  \val,REG_LC_DATA
        .endm
        .macro  LCR reg,dst
        move.b  #\reg,REG_LC_PTR
        move.b  REG_LC_DATA,\dst
        .endm

|===========================================================================
| Interrupts (level 2, vectored)
|===========================================================================
| vector 23: not used, just acknowledge
irq_cd_spare:
        move.b  #0x08,REG_CDIRQACK
        rte

| vector 22: drive link, 64-75 times per second.
| Each service reads the 10 nibble status packet and writes a 10 nibble
| command packet (the queued command, or a status request).
irq_cd_link:
        movem.l d0-d4/a0-a1,-(sp)
        move.b  #0x10,REG_CDIRQACK
        lea     CD_RX,a0
        moveq   #9,d1
1:      move.b  #2,REG_CDD_CTRL         | clock low, drive talks
        move.b  REG_CDD_IN,d0
        and.b   #0x0F,d0
        move.b  d0,(a0)+
        move.b  #3,REG_CDD_CTRL         | clock high
        dbra    d1,1b

        lea     cd_status_packet(pc),a0
        tst.b   CD_CMDF
        beq     2f
        lea     CD_TXN,a0
2:      moveq   #9,d1
3:      move.b  #0,REG_CDD_CTRL         | clock low, host talks
        move.b  (a0)+,REG_CDD_OUT
        move.b  #1,REG_CDD_CTRL         | clock high
        dbra    d1,3b
        clr.b   CD_CMDF
        addq.b  #1,CD_TICK
        tst.b   RD_ACTIVE               | drive busy: keep the heartbeat going
        bne     4f
        cmp.b   #CDS_PLAY,CDA_STATE
        beq     4f
        cmp.b   #CDS_WPOS,CDA_STATE
        bne     5f
4:      bsr     cd_heartbeat
5:      bsr     cda_service
        movem.l (sp)+,d0-d4/a0-a1
        rte

cd_status_packet:
        .byte   0,0,0,0,0,0,0,0,0,0x0A

| vector 21: a sector has been decoded
irq_cd_sector:
        movem.l d0-d1,-(sp)
        move.b  #0x20,REG_CDIRQACK
        LCR     0x0C,d0                 | reading the status registers
        LCR     0x0D,d0                 | releases the decoder interrupt
        LCR     0x0E,d0
        LCR     0x0F,d0
        tst.b   RD_ACTIVE
        beq     9f
        tst.b   RD_READY                | previous sector not collected yet
        bne     9f
        moveq   #0,d1
        LCR     0x04,d1                 | header: minute, second, frame (BCD)
        lsl.l   #8,d1
        LCR     0x05,d1
        lsl.l   #8,d1
        LCR     0x06,d1
        cmp.l   RD_MSF,d1
        beq     2f
        bcs     9f                      | still before the wanted sector
        st      RD_MISS                 | already past it
        bra     9f
2:      LCR     0x08,d0                 | buffer pointer of this sector
        LCR     0x09,d1
        addq.b  #4,d0                   | skip the 4 byte header
        bcc     3f
        addq.b  #1,d1
3:      LCW     0x04,d0                 | data address counter
        LCW     0x05,d1
        LCW     0x02,#0xFF              | byte counter = 0x7FF
        LCW     0x03,#0x07
        LCW     0x06,d0                 | trigger the transfer
        move.l  #SECBUF,REG_DMA_DEST
        move.l  #0x400,REG_DMA_COUNT    | words
        move.w  #0xFFC5,REG_DMA_PROG    | mode: decoder buffer -> memory
        move.b  #0x40,REG_DMA_GO
        LCW     0x07,d0                 | acknowledge
        st      RD_READY
9:      movem.l (sp)+,d0-d1
        rte

|===========================================================================
| Drive commands
|===========================================================================
| d0.l = four command bytes, d1.b = ninth nibble.  Waits for a free slot.
cd_command:
        movem.l d2-d4/a0,-(sp)
        move.b  CD_TICK,d3
1:      tst.b   CD_CMDF                 | previous command still waiting
        beq     2f
        move.b  d0,REG_WATCHDOG
        move.b  CD_TICK,d4
        sub.b   d3,d4
        cmp.b   #40,d4
        bcs     1b
2:      bsr     cd_pack
        movem.l (sp)+,d2-d4/a0
        rts

| same, from interrupt context (no waiting)
cd_pack:
        lea     CD_TXN,a0
        moveq   #5,d2                   | checksum seed
        moveq   #7,d3
1:      rol.l   #4,d0
        move.b  d0,d4
        and.b   #0x0F,d4
        move.b  d4,(a0)+
        add.b   d4,d2
        dbra    d3,1b
        and.b   #0x0F,d1
        move.b  d1,(a0)+
        add.b   d1,d2
        not.b   d2
        and.b   #0x0F,d2
        move.b  d2,(a0)+
        st      CD_CMDF
        rts

| d0 = 0..99 -> BCD
to_bcd:
        and.l   #0xFF,d0
        divu    #10,d0
        move.w  d0,-(sp)
        swap    d0
        move.w  (sp)+,d1
        lsl.w   #4,d1
        or.w    d1,d0
        and.l   #0xFF,d0
        rts

| d0 = logical block -> d0 = 00MMSSFF (BCD) of the disc position
lba_to_msf:
        movem.l d1-d3,-(sp)
        add.l   #150,d0
        divu    #75,d0                  | quotient: seconds total, remainder: frame
        move.l  d0,d2
        swap    d2
        and.l   #0xFFFF,d0
        divu    #60,d0                  | quotient: minute, remainder: second
        move.l  d0,d3
        swap    d3
        bsr     to_bcd                  | minute
        move.l  d0,-(sp)
        move.w  d3,d0
        bsr     to_bcd                  | second
        move.l  (sp)+,d3
        lsl.l   #8,d3
        or.b    d0,d3
        move.w  d2,d0
        bsr     to_bcd                  | frame
        lsl.l   #8,d3
        or.b    d0,d3
        move.l  d3,d0
        movem.l (sp)+,d1-d3
        rts

|---------------------------------------------------------------------------
| Sector reading
|---------------------------------------------------------------------------
| start delivering sectors from logical block d0
cd_read_begin:
        movem.l d0-d1,-(sp)
        clr.b   RD_ACTIVE               | the interrupt keeps its hands off
        move.l  d0,RD_LBA
        bsr     lba_to_msf
        move.l  d0,RD_MSF
        clr.b   RD_READY
        clr.b   RD_MISS
        LCW     0x01,#0x22              | decoder interrupt + data output
        LCW     0x0B,#0x00              | header registers show the address
        LCW     0x0A,#0x84              | decoder on, write to buffer
        st      RD_ACTIVE
        move.l  RD_LBA,d0               | begin a little early, the drive
        subq.l  #3,d0                   | needs a moment to settle
        bcc     1f
        moveq   #0,d0
1:      bsr     lba_to_msf
        or.l    #0x30000000,d0          | "play from position"
        moveq   #0,d1
        bsr     cd_command
        movem.l (sp)+,d0-d1
        rts

| wait until the wanted sector is in SECBUF
cd_read_wait:
        movem.l d0-d3,-(sp)
        moveq   #5,d3                   | attempts
1:      move.b  CD_TICK,d2
2:      move.b  d0,REG_WATCHDOG
        bsr     ls_tick
        tst.b   RD_READY
        bne     9f
        tst.b   RD_MISS
        bne     3f
        move.b  CD_TICK,d1
        sub.b   d2,d1
        cmp.b   #200,d1                 | about three seconds
        bcs     2b
3:      subq.w  #1,d3
        beq     cd_read_failed
        move.l  RD_LBA,d0               | seek again
        bsr     cd_read_begin
        bra     1b
9:      movem.l (sp)+,d0-d3
        rts

cd_read_failed:
        lea     msg_read_error(pc),a0
        bra     cd_fatal

| the sector in SECBUF has been used, ask for the following one
cd_read_next:
        move.l  d0,-(sp)
        addq.l  #1,RD_LBA               | (the interrupt waits while READY is set)
        move.l  RD_LBA,d0
        bsr     lba_to_msf
        move.l  d0,RD_MSF
        clr.b   RD_READY
        move.l  (sp)+,d0
        rts

cd_read_end:
        movem.l d0-d1,-(sp)
        clr.b   RD_ACTIVE
        LCW     0x0A,#0x00              | decoder off
        LCW     0x01,#0x02
        move.l  #0x60000000,d0          | pause
        moveq   #0,d1
        bsr     cd_command
        movem.l (sp)+,d0-d1
        rts

| unrecoverable problem: a0 = message
cd_fatal:
        move.w  #0x2700,sr
        lea     SYS_STACK,sp
        move.l  a0,-(sp)
        tst.b   LS_ACTIVE
        bne     1f
        bsr     ls_begin
1:      movea.l (sp)+,a0
        move.w  #0x7000+10*32+20,d0
        bsr     ls_print
2:      move.b  d0,REG_WATCHDOG
        bra     2b

msg_read_error: .asciz  "DISC READ ERROR"
msg_no_disc:    .asciz  "NOT A GAME DISC"
msg_no_ipl:     .asciz  "IPL.TXT NOT FOUND"
        .balign 2

|===========================================================================
| ISO 9660 : root directory cache and lookup
|===========================================================================
| little endian long at (a0) -> d0  (a0 advances by 4)
get_le32:
        moveq   #0,d0
        move.b  3(a0),d0
        lsl.l   #8,d0
        move.b  2(a0),d0
        lsl.l   #8,d0
        move.b  1(a0),d0
        lsl.l   #8,d0
        move.b  (a0),d0
        addq.l  #4,a0
        rts

iso_mount:
        movem.l d0-d7/a0-a4,-(sp)
        clr.w   DIR_COUNT
        moveq   #16,d0                  | primary volume descriptor
        bsr     cd_read_begin
        bsr     cd_read_wait
        bsr     cd_read_end
        lea     SECBUF,a0
        cmp.b   #1,(a0)
        bne     iso_bad
        cmp.b   #'C',1(a0)
        bne     iso_bad
        cmp.b   #'D',2(a0)
        bne     iso_bad
        lea     SECBUF+156+2,a0         | root directory record: extent
        bsr     get_le32
        move.l  d0,d6
        lea     SECBUF+156+10,a0        | and length
        bsr     get_le32
        add.l   #2047,d0
        moveq   #11,d1
        lsr.l   d1,d0
        move.l  d0,d7                   | sectors
        move.l  d6,DIR_LBA
        move.l  d7,DIR_SECTORS
        clr.b   DIR_MORE
        tst.l   d7
        beq     iso_done
        lea     DIRCACHE,a3
        move.l  d6,d0
        bsr     cd_read_begin
1:      bsr     cd_read_wait
        lea     SECBUF,a2
2:      moveq   #0,d5
        move.b  (a2),d5                 | record length
        beq     5f                      | rest of the sector is empty
        btst    #1,25(a2)               | directory?
        bne     4f
        cmp.w   #DIRMAX,DIR_COUNT
        bcs     30f
        st      DIR_MORE                | the rest is looked up on the disc
        bra     4f
30:     moveq   #0,d4
        move.b  32(a2),d4               | name length
        beq     4f
        lea     33(a2),a0
        movea.l a3,a1
        moveq   #11,d3
3:      moveq   #0,d0
        tst.w   d4
        beq     31f
        move.b  (a0)+,d0
        subq.w  #1,d4
        cmp.b   #';',d0
        bne     31f
        moveq   #0,d0
        moveq   #0,d4
31:     move.b  d0,(a1)+
        dbra    d3,3b
        lea     2(a2),a0
        bsr     get_le32
        move.l  d0,12(a3)
        lea     10(a2),a0
        bsr     get_le32
        move.l  d0,16(a3)
        lea     20(a3),a3
        addq.w  #1,DIR_COUNT
4:      adda.w  d5,a2
        cmpa.l  #SECBUF+2048,a2
        bcs     2b
5:      subq.l  #1,d7
        beq     6f
        bsr     cd_read_next
        bra     1b
6:      bsr     cd_read_end
iso_done:
        movem.l (sp)+,d0-d7/a0-a4
        rts
iso_bad:
        lea     msg_no_disc(pc),a0
        bra     cd_fatal

| a0 -> file name (ends with 0 or ';').  Returns d0 = block, d1 = size,
| Z clear when the file does not exist.
dir_find:
        movem.l d2-d5/a1-a3,-(sp)
        lea     DIRCACHE,a3
        move.w  DIR_COUNT,d5
        beq     8f
        subq.w  #1,d5
1:      movea.l a0,a1
        movea.l a3,a2
        moveq   #11,d4
2:      move.b  (a1)+,d2
        cmp.b   #';',d2
        bne     3f
        moveq   #0,d2
3:      cmp.b   #'a',d2
        bcs     4f
        cmp.b   #'z',d2
        bhi     4f
        sub.b   #0x20,d2
4:      cmp.b   (a2)+,d2
        bne     6f
        tst.b   d2
        beq     5f
        dbra    d4,2b
5:      move.l  12(a3),d0
        move.l  16(a3),d1
        moveq   #0,d2                   | found
        bra     9f
6:      lea     20(a3),a3
        dbra    d5,1b
8:      tst.b   DIR_MORE
        beq     81f
        movem.l (sp)+,d2-d5/a1-a3
        bra     dir_find_disc
81:     moveq   #1,d2
9:      movem.l (sp)+,d2-d5/a1-a3
        rts

| The same search, reading the directory from the disc (used for the
| entries that did not fit in the cache).
dir_find_disc:
        movem.l d2-d7/a1-a3,-(sp)
        move.l  DIR_SECTORS,d7
        beq     8f
        move.l  DIR_LBA,d0
        bsr     cd_read_begin
1:      bsr     cd_read_wait
        lea     SECBUF,a2
2:      moveq   #0,d5
        move.b  (a2),d5                 | record length
        beq     6f
        btst    #1,25(a2)
        bne     5f
        moveq   #0,d4
        move.b  32(a2),d4               | name length
        beq     5f
        lea     33(a2),a3
        movea.l a0,a1
3:      move.b  (a1)+,d2                | wanted name, upper case
        cmp.b   #';',d2
        bne     31f
        moveq   #0,d2
31:     cmp.b   #'a',d2
        bcs     32f
        cmp.b   #'z',d2
        bhi     32f
        sub.b   #0x20,d2
32:     moveq   #0,d3                   | name on the disc
        tst.w   d4
        beq     33f
        move.b  (a3)+,d3
        subq.w  #1,d4
        cmp.b   #';',d3
        bne     33f
        moveq   #0,d3
        moveq   #0,d4
33:     cmp.b   d2,d3
        bne     5f
        tst.b   d2
        bne     3b
        lea     2(a2),a3                | found
        exg     a0,a3
        bsr     get_le32
        move.l  d0,d6
        lea     10(a2),a0
        bsr     get_le32
        move.l  d0,d1
        move.l  d6,d0
        movea.l a3,a0
        bsr     cd_read_end
        moveq   #0,d2
        bra     9f
5:      adda.w  d5,a2
        cmpa.l  #SECBUF+2048,a2
        bcs     2b
6:      subq.l  #1,d7
        beq     7f
        bsr     cd_read_next
        bra     1b
7:      bsr     cd_read_end
8:      moveq   #1,d2
9:      movem.l (sp)+,d2-d7/a1-a3
        rts

| a0 -> file name.  Returns d0 = type derived from the extension
file_type:
        movem.l d1-d3/a0-a2,-(sp)
        suba.l  a1,a1
1:      move.b  (a0)+,d0
        beq     2f
        cmp.b   #';',d0
        beq     2f
        cmp.b   #'.',d0
        bne     1b
        movea.l a0,a1                   | character after the last dot
        bra     1b
2:      moveq   #FT_NONE-0x100,d0
        cmpa.l  #0,a1
        beq     9f
        moveq   #0,d3                   | pack three upper case characters
        moveq   #2,d2
3:      move.b  (a1)+,d1
        cmp.b   #'a',d1
        bcs     4f
        cmp.b   #'z',d1
        bhi     4f
        sub.b   #0x20,d1
4:      lsl.l   #8,d3
        move.b  d1,d3
        dbra    d2,3b
        lea     ext_table(pc),a2
        moveq   #0,d0
5:      move.l  (a2)+,d1
        beq     6f
        cmp.l   d1,d3
        beq     9f
        addq.w  #1,d0
        bra     5b
6:      moveq   #FT_NONE-0x100,d0
9:      movem.l (sp)+,d1-d3/a0-a2
        rts
ext_table:
        .long   0x00505247              | PRG
        .long   0x00464958              | FIX
        .long   0x00535052              | SPR
        .long   0x005A3830              | Z80
        .long   0x0050434D              | PCM
        .long   0x00504154              | PAT
        .long   0

|===========================================================================
| Destinations ("sinks") : program RAM or one of the memories behind the
| transfer window.  Byte accesses are used throughout because every
| emulator agrees on them.
|===========================================================================
| d0 = type, d1 = position inside that memory
sink_open:
        st      WIN_BUSY
        move.b  d0,SINK_TYPE
        move.l  d1,SINK_POS
        cmp.b   #FT_FIX,d0
        bne     1f
        move.b  #5,REG_TRANSAREA
        move.b  d0,REG_BUSREQ_FIX
        rts
1:      cmp.b   #FT_SPR,d0
        bne     2f
        move.b  #0,REG_TRANSAREA
        move.b  d0,REG_BUSREQ_SPR
        rts
2:      cmp.b   #FT_Z80,d0
        bne     3f
        move.b  #4,REG_TRANSAREA
        move.b  d0,REG_BUSREQ_Z80
        rts
3:      cmp.b   #FT_PCM,d0
        bne     4f
        move.b  #1,REG_TRANSAREA
        move.b  d0,REG_BUSREQ_PCM
4:      rts

sink_close:
        clr.b   WIN_BUSY
        move.b  SINK_TYPE,d0
        cmp.b   #FT_FIX,d0
        bne     1f
        move.b  d0,REG_BUSREL_FIX
        rts
1:      cmp.b   #FT_SPR,d0
        bne     2f
        move.b  d0,REG_BUSREL_SPR
        rts
2:      cmp.b   #FT_Z80,d0
        bne     3f
        move.b  d0,REG_BUSREL_Z80
        rts
3:      cmp.b   #FT_PCM,d0
        bne     4f
        move.b  d0,REG_BUSREL_PCM
4:      rts

| a0 = source, d0.l = number of bytes
sink_write:
        movem.l d0-d5/a0-a1,-(sp)
        move.l  d0,d5                   | bytes left
sw_loop:
        tst.l   d5
        beq     sw_done
        move.b  d0,REG_WATCHDOG
        move.l  SINK_POS,d1
        moveq   #0,d0
        move.b  SINK_TYPE,d0
        add.w   d0,d0
        move.w  sw_jt(pc,d0.w),d0
        jmp     sw_jt(pc,d0.w)
sw_jt:  .word   sw_prg-sw_jt
        .word   sw_fix-sw_jt
        .word   sw_spr-sw_jt
        .word   sw_z80-sw_jt
        .word   sw_pcm-sw_jt
sw_done:
        movem.l (sp)+,d0-d5/a0-a1
        rts

| program RAM, 2 MiB
sw_prg: move.l  #0x200000,d2
        sub.l   d1,d2                   | room left
        bls     sw_done
        movea.l d1,a1
        moveq   #0,d4                   | step 1
        bra     sw_copy
| text tiles, 128 KiB, one byte per word
sw_fix: move.l  #0x20000,d2
        bra     sw_bytearea
| sound program, 64 KiB
sw_z80: move.l  #0x10000,d2
sw_bytearea:
        sub.l   d1,d2
        bls     sw_done
        move.l  d1,d3
        add.l   d3,d3
        add.l   #UPLOAD_ZONE+1,d3
        movea.l d3,a1
        moveq   #1,d4                   | step 2
        bra     sw_copy
| sprite tiles, four banks of 1 MiB
sw_spr: and.l   #0x3FFFFF,d1            | the bank register has two bits
        move.l  d1,SINK_POS
        move.l  d1,d3
        swap    d3
        lsr.w   #4,d3
        move.b  d3,REG_SPRBANK
        move.l  d1,d3
        and.l   #0x0FFFFF,d3
        move.l  #0x100000,d2
        sub.l   d3,d2                   | up to the end of this bank
        add.l   #UPLOAD_ZONE,d3
        movea.l d3,a1
        moveq   #0,d4
        bra     sw_copy
| sample memory, two banks of 512 KiB, one byte per word
sw_pcm: cmp.l   #0x100000,d1
        bcc     sw_done
        move.l  d1,d3
        swap    d3
        lsr.w   #3,d3
        move.b  d3,REG_PCMBANK
        move.l  d1,d3
        and.l   #0x07FFFF,d3
        move.l  #0x80000,d2
        sub.l   d3,d2
        add.l   d3,d3
        add.l   #UPLOAD_ZONE+1,d3
        movea.l d3,a1
        moveq   #1,d4

| copy min(d5, d2, 0x8000) bytes from a0 to a1 (d4: 0 = dense, 1 = every other byte)
sw_copy:
        cmp.l   d5,d2
        bls     1f
        move.l  d5,d2
1:      cmp.l   #0x8000,d2
        bls     2f
        move.l  #0x8000,d2
2:      sub.l   d2,d5
        add.l   d2,SINK_POS
        subq.w  #1,d2
        tst.b   d4
        bne     4f
3:      move.b  (a0)+,(a1)+
        dbra    d2,3b
        bra     5f
4:      move.b  (a0)+,(a1)
        addq.l  #2,a1
        dbra    d2,4b
5:      tst.b   SINK_TYPE               | program data over the vector table:
        bne     sw_loop                 | keep the CD interrupts alive
        cmp.l   #0x80,d1
        bcc     sw_loop
        bsr     vectors_guard
        bra     sw_loop

vectors_guard:
        move.l  #jt_cdirq21,(0x54).w
        move.l  #jt_cdirq22,(0x58).w
        move.l  #jt_cdirq23,(0x5C).w
        rts

| Sample table patch.  a0 = data, d0.l = number of bytes, d6.w = offset
| added to every value.  The sound program memory must be the open sink.
| The file is a run of 10 byte records: address, start, end, start2, end2
| (big endian words).  A record whose address is 0x0000 or 0xFFFF only
| separates sections.  Records may straddle sectors, so they are gathered
| byte by byte in PAT_REC.
pat_feed:
        movem.l d0-d5/a0-a2,-(sp)
        move.l  d0,d5
        beq     9f
1:      moveq   #0,d0
        move.b  PAT_FILL,d0
        lea     PAT_REC,a2
        move.b  (a0)+,(a2,d0.w)
        addq.b  #1,d0
        move.b  d0,PAT_FILL
        cmp.b   #10,d0
        bne     2f
        clr.b   PAT_FILL
        bsr     pat_record
2:      subq.l  #1,d5
        bne     1b
9:      movem.l (sp)+,d0-d5/a0-a2
        rts

pat_record:
        lea     PAT_REC,a2
        move.w  (a2),d3
        beq     9f
        cmp.w   #0xFFFF,d3
        beq     9f
        move.w  2(a2),d2
        add.w   d6,d2
        lsr.w   #1,d2
        bsr     pat_poke
        addq.w  #2,d3
        move.w  4(a2),d2
        add.w   d6,d2
        lsr.w   #1,d2
        subq.w  #1,d2
        bsr     pat_poke
        move.w  6(a2),d0
        or.w    8(a2),d0
        beq     9f
        addq.w  #3,d3
        move.w  6(a2),d2
        add.w   d6,d2
        lsr.w   #1,d2
        bsr     pat_poke
        addq.w  #2,d3
        move.w  8(a2),d2
        add.w   d6,d2
        lsr.w   #1,d2
        subq.w  #1,d2
        bsr     pat_poke
9:      rts
| store word d2 (low byte first) at sound memory address d3
pat_poke:
        moveq   #0,d0
        move.w  d3,d0
        add.l   d0,d0
        add.l   #UPLOAD_ZONE+1,d0
        movea.l d0,a1
        move.b  d2,(a1)
        move.w  d2,d0
        lsr.w   #8,d0
        move.b  d0,2(a1)
        rts

|===========================================================================
| Loading the files of the table at CD_FILE_TABLE
|   d7 = non-zero: show the loading screen
|===========================================================================
lle_load_table:
        movem.l d0-d7/a0-a4,-(sp)
        move.w  sr,d6                   | (not privileged on this CPU)
        btst    #13,d6
        beq     14f                     | user mode: interrupts are open anyway
        move.w  #0x2100,sr              | drive interrupts on, vblank held back
14:     move.w  #0x0301,REG_VBLMASK
        clr.b   CDA_REQF
        clr.b   CDA_STATE               | music stops while the drive seeks
        clr.b   DEFER_N
        clr.b   LD_Z80
        clr.l   LD_TOTAL
        clr.l   LD_DONE

        | pass 1: locate every file
        lea     CD_FILE_TABLE,a2
1:      tst.b   (a2)
        beq     3f
        movea.l a2,a0
        bsr     file_type
        move.b  d0,FE_TYPE(a2)
        bmi     2f
        movea.l a2,a0
        bsr     dir_find
        beq     11f
        move.b  #FT_NONE,FE_TYPE(a2)    | not on the disc
        bra     2f
11:     move.l  d0,FE_LBA(a2)
        move.l  d1,FE_SIZE(a2)
        add.l   #2047,d1
        moveq   #11,d0
        lsr.l   d0,d1
        add.l   d1,LD_TOTAL
2:      lea     32(a2),a2
        cmpa.l  #CD_FILE_TABLE+32*32,a2
        bcs     1b
3:
        tst.b   d7
        beq     4f
        tst.b   LS_ACTIVE               | already up during the first boot
        bne     4f
        bsr     ls_begin
        moveq   #2,d7                   | remember to take it down again
4:
        | pass 2: load
        lea     CD_FILE_TABLE,a2
5:      tst.b   (a2)
        beq     8f
        move.b  FE_TYPE(a2),d0
        bmi     7f
        cmp.b   #FT_FIX,d0              | the loading screen borrows the text
        bne     6f                      | tiles: load those when it is gone
        tst.b   LS_ACTIVE
        beq     6f
        moveq   #0,d0
        move.b  DEFER_N,d0
        cmp.w   #8,d0
        bcc     6f
        lsl.w   #2,d0
        lea     DEFER_LIST,a0
        move.l  a2,(a0,d0.w)
        addq.b  #1,DEFER_N
        bra     7f
6:      bsr     load_entry
7:      lea     32(a2),a2
        cmpa.l  #CD_FILE_TABLE+32*32,a2
        bcs     5b
8:
        cmp.b   #2,d7
        bne     9f
        bsr     ls_end
9:      tst.b   LS_ACTIVE               | still up (first boot): the caller
        bne     12f                     | loads the deferred files later
        bsr     load_deferred
12:     tst.b   LD_Z80
        beq     13f
        tst.b   PV_BOOTED               | not during the first boot
        beq     13f
        clr.b   REG_Z80RST              | restart the sound CPU
        move.b  #0xFF,REG_Z80RST
13:     move.w  #0x0331,REG_VBLMASK
        btst    #13,d6
        beq     15f
        move.w  d6,sr
15:     movem.l (sp)+,d0-d7/a0-a4
        rts

load_deferred:
        movem.l d0/d6/a0/a2,-(sp)
        moveq   #0,d6
1:      cmp.b   DEFER_N,d6
        bcc     2f
        move.w  d6,d0
        lsl.w   #2,d0
        lea     DEFER_LIST,a0
        movea.l (a0,d0.w),a2
        bsr     load_entry
        addq.w  #1,d6
        bra     1b
2:      clr.b   DEFER_N
        movem.l (sp)+,d0/d6/a0/a2
        rts

| a2 -> table entry
load_entry:
        movem.l d0-d7/a0-a1,-(sp)
        moveq   #0,d0
        move.b  FE_TYPE(a2),d0
        moveq   #0,d2
        move.b  FE_BANK(a2),d2
        and.w   #3,d2
        move.l  FE_OFFSET(a2),d1
        cmp.b   #FT_PRG,d0
        beq     le_open
        cmp.b   #FT_SPR,d0
        bne     1f
        swap    d2
        lsl.l   #4,d2                   | bank * 1 MiB
        add.l   d2,d1
        bra     le_open
1:      cmp.b   #FT_PCM,d0
        bne     2f
        lsr.l   #1,d1
        swap    d2
        lsl.l   #3,d2                   | bank * 512 KiB
        add.l   d2,d1
        bra     le_open
2:      cmp.b   #FT_PAT,d0
        bne     3f
        swap    d2
        lsl.l   #4,d2
        add.l   d2,d1
        lsr.l   #8,d1                   | offset applied to the patch values
        move.w  d1,d6
        moveq   #FT_Z80,d0
        moveq   #0,d1
        bra     le_open
3:      lsr.l   #1,d1                   | FIX and Z80: one byte per word
        cmp.b   #FT_Z80,d0
        bne     le_open
        st      LD_Z80
le_open:
        clr.b   PAT_FILL
        bsr     sink_open
        move.l  FE_SIZE(a2),d5          | bytes left
        beq     le_done
        move.l  FE_LBA(a2),d0
        bsr     cd_read_begin
le_sector:
        bsr     cd_read_wait
        move.l  #2048,d0
        cmp.l   d5,d0
        bls     1f
        move.l  d5,d0
1:      sub.l   d0,d5
        lea     SECBUF,a0
        cmp.b   #FT_PAT,FE_TYPE(a2)
        bne     2f
        bsr     pat_feed
        bra     3f
2:      bsr     sink_write
3:      addq.l  #1,LD_DONE
        bsr     ls_progress
        tst.l   d5
        beq     4f
        bsr     cd_read_next
        bra     le_sector
4:      bsr     cd_read_end
le_done:
        bsr     sink_close
        cmp.b   #FT_PRG,FE_TYPE(a2)     | remember the game's vblank handler
        bne     5f
        cmp.l   #0x68,FE_OFFSET(a2)
        bhi     5f
        move.l  (0x68).w,CD_GAME_VBL
5:      movem.l (sp)+,d0-d7/a0-a1
        rts

|===========================================================================
| Loading screen management in this mode
|===========================================================================
| saved: backdrop, palette 0, text map, the text tiles we overwrite
ls_begin:
        movem.l d0-d3/a0-a2,-(sp)
        st      LS_ACTIVE
        move.b  CD_TICK,LS_TICK
        move.b  #1,REG_DISBLSPR
        clr.b   REG_DISBLFIX
        move.b  #1,REG_ENVIDEO
        lea     LS_SAVE,a1
        move.w  PAL_BACKDROP,(a1)+
        lea     PALETTES,a0
        moveq   #15,d0
1:      move.w  (a0)+,(a1)+
        dbra    d0,1b
        move.w  VRAM_MOD,(a1)+
        move.w  #0x7000,d1              | text map
        move.w  #40*32-1,d0
2:      move.w  d1,VRAM_ADDR
        move.w  VRAM_RW,(a1)+
        addq.w  #1,d1
        dbra    d0,2b
        st      WIN_BUSY
        move.b  #5,REG_TRANSAREA        | text tiles
        move.b  d0,REG_BUSREQ_FIX
        lea     UPLOAD_ZONE+1,a0
        move.w  #LS_TILES*32-1,d0
3:      move.b  (a0),(a1)+
        addq.l  #2,a0
        dbra    d0,3b
        lea     UPLOAD_ZONE+1,a0        | our own tiles
        lea     rom_start+0x7C000,a2
        move.w  #LS_TILES*16-1,d0
4:      move.w  (a2)+,d1                | ROM word = second byte : first byte
        move.b  d1,(a0)
        lsr.w   #8,d1
        move.b  d1,2(a0)
        addq.l  #4,a0
        dbra    d0,4b
        move.b  d0,REG_BUSREL_FIX
        clr.b   WIN_BUSY
        lea     ls_palette,a0
        lea     PALETTES,a1
        moveq   #15,d0
5:      move.w  (a0)+,(a1)+
        dbra    d0,5b
        bsr     load_screen_init
        movem.l (sp)+,d0-d3/a0-a2
        rts

ls_end:
        movem.l d0-d3/a0-a2,-(sp)
        clr.b   LS_ACTIVE
        lea     LS_SAVE,a1
        move.w  (a1)+,PAL_BACKDROP
        lea     PALETTES,a0
        moveq   #15,d0
1:      move.w  (a1)+,(a0)+
        dbra    d0,1b
        move.w  (a1)+,d2                | modulo, restored last
        move.w  #1,VRAM_MOD
        move.w  #0x7000,VRAM_ADDR
        move.w  #40*32-1,d0
2:      move.w  (a1)+,VRAM_RW
        dbra    d0,2b
        move.w  d2,VRAM_MOD
        st      WIN_BUSY
        move.b  #5,REG_TRANSAREA
        move.b  d0,REG_BUSREQ_FIX
        lea     UPLOAD_ZONE+1,a0
        move.w  #LS_TILES*32-1,d0
3:      move.b  (a1)+,(a0)
        addq.l  #2,a0
        dbra    d0,3b
        move.b  d0,REG_BUSREL_FIX
        clr.b   WIN_BUSY
        clr.b   REG_DISBLSPR
        movem.l (sp)+,d0-d3/a0-a2
        rts

| progress bar from LD_DONE / LD_TOTAL
ls_progress:
        tst.b   LS_ACTIVE
        beq     9f
        movem.l d0-d1,-(sp)
        move.l  LD_DONE,d0
        lsl.l   #7,d0                   | * 128
        move.l  LD_TOTAL,d1
        beq     1f
        cmp.l   #0xFFFF,d1
        bhi     1f
        divu    d1,d0
        bvs     1f
        cmp.w   #0x80,d0
        bls     2f
1:      move.w  #0x80,d0
2:      move.w  d0,CD_PROGRESS
        bsr     load_screen_progress
        movem.l (sp)+,d0-d1
9:      rts

| animate once per drive tick
ls_tick:
        tst.b   LS_ACTIVE
        beq     9f
        move.l  d0,-(sp)
        move.b  CD_TICK,d0
        cmp.b   LS_TICK,d0
        beq     1f
        move.b  d0,LS_TICK
        bsr     load_screen_anim
1:      move.l  (sp)+,d0
9:      rts

|===========================================================================
| First boot in this mode: bring up the drive, read IPL.TXT, load the game
|===========================================================================
lle_boot:
        | interrupt vectors live in RAM from now on; start with our table
        move.b  d0,REG_SWPROM
        move.b  #0xFF,REG_VECTSEL
        lea     rom_start,a0
        suba.l  a1,a1
        moveq   #31,d0
1:      move.l  (a0)+,(a1)+
        dbra    d0,1b

        clr.w   REG_CDMASK
        clr.b   REG_CDD_ENABLE
        LCW     0x0F,#0x00              | decoder reset
        LCW     0x01,#0x02
        LCW     0x0A,#0x00
        move.w  #7,REG_IRQACK
        move.b  #0x38,REG_CDIRQACK
        move.w  #0x0331,REG_VBLMASK
        move.b  #1,REG_CDD_ENABLE
        move.w  #0x0550,REG_CDMASK
        move.b  d0,REG_BUSREL_Z80
        move.w  #0x2100,sr

        bsr     ls_begin
        move.b  CD_TICK,d1              | let the drive spin up
2:      move.b  d0,REG_WATCHDOG
        bsr     ls_tick
        move.b  CD_TICK,d0
        sub.b   d1,d0
        cmp.b   #30,d0
        bcs     2b

        bsr     iso_mount
        lea     ipl_name(pc),a0
        bsr     dir_find
        beq     3f
        lea     msg_no_ipl(pc),a0
        bra     cd_fatal
3:      bsr     cd_read_begin           | IPL.TXT fits in one sector
        bsr     cd_read_wait
        bsr     cd_read_end
        cmp.l   #2047,d1
        bls     4f
        move.l  #2047,d1
4:      lea     SECBUF,a0
        clr.b   (a0,d1.l)               | terminate the text
        bsr     ipl_parse

        moveq   #1,d7
        bsr     lle_load_table
        bsr     ls_end
        bsr     load_deferred
        move.w  #0x2700,sr
        bsr     vectors_guard
        rts

ipl_name:
        .asciz  "IPL.TXT"
        .balign 2

| IPL.TXT at a0: lines "NAME.EXT,bank,hex offset" -> CD_FILE_TABLE
ipl_parse:
        movem.l d0-d4/a0-a2,-(sp)
        lea     CD_FILE_TABLE,a1
        move.w  #33*32/4-1,d0
1:      clr.l   (a1)+
        dbra    d0,1b
        lea     CD_FILE_TABLE,a1
        moveq   #31,d4
ip_line:
        move.b  (a0),d0                 | skip line ends and blanks
        beq     ip_done
        cmp.b   #0x1A,d0
        beq     ip_done
        cmp.b   #0x20,d0
        bhi     1f
        addq.l  #1,a0
        bra     ip_line
1:      clr.l   (a1)
        clr.l   4(a1)
        clr.l   8(a1)
        clr.l   12(a1)
        movea.l a1,a2                   | name
        moveq   #14,d1
2:      move.b  (a0)+,d0
        beq     ip_done
        cmp.b   #',',d0
        beq     3f
        cmp.b   #0x20,d0
        bcs     ip_skip                 | malformed line
        tst.w   d1
        bmi     2b
        move.b  d0,(a2)+
        subq.w  #1,d1
        bra     2b
3:      moveq   #0,d2                   | bank, decimal
4:      move.b  (a0)+,d0
        beq     ip_done
        cmp.b   #',',d0
        beq     5f
        sub.b   #'0',d0
        cmp.b   #9,d0
        bhi     ip_skip
        mulu    #10,d2
        and.w   #0xFF,d0
        add.w   d0,d2
        bra     4b
5:      move.b  d2,FE_BANK(a1)
        moveq   #0,d2                   | offset, hexadecimal
6:      move.b  (a0),d0
        cmp.b   #'a',d0
        bcs     7f
        sub.b   #0x20,d0
7:      sub.b   #'0',d0
        cmp.b   #9,d0
        bls     8f
        sub.b   #7,d0
        cmp.b   #10,d0
        bcs     9f
        cmp.b   #15,d0
        bhi     9f
8:      lsl.l   #4,d2
        and.l   #0x0F,d0
        or.l    d0,d2
        addq.l  #1,a0
        bra     6b
9:      move.l  d2,FE_OFFSET(a1)
        lea     32(a1),a1
        subq.w  #1,d4
        bmi     ip_done
ip_skip:
        move.b  (a0),d0                 | to the end of the line
        beq     ip_done
        cmp.b   #0x0A,d0
        beq     ip_line
        cmp.b   #0x0D,d0
        beq     ip_line
        addq.l  #1,a0
        bra     ip_skip
ip_done:
        tst.w   d4                      | a half filled last entry is dropped
        bmi     1f
        clr.b   (a1)
1:      movem.l (sp)+,d0-d4/a0-a2
        rts

|===========================================================================
| BIOSF_UPLOAD in this mode
|===========================================================================
lle_upload:
        movem.l d0-d3/a0,-(sp)
        moveq   #0,d2
        move.b  BIOS_UPZONE,d2
        and.w   #0x0F,d2
        cmp.w   #8,d2
        bne     1f
        moveq   #0,d2
1:      move.l  BIOS_UPDEST,d1
        moveq   #0,d3
        move.b  BIOS_UPBANK,d3
        movea.l BIOS_UPSRC,a0
        cmp.w   #FT_PRG,d2
        bne     2f
        moveq   #FT_PRG,d0
        bsr     up_run
        move.l  BIOS_UPSIZE,d0
        add.l   d0,BIOS_UPDEST
        bra     up_end
2:      cmp.w   #FT_FIX,d2
        beq     21f
        cmp.w   #FT_Z80,d2
        bne     3f
21:     lsr.l   #1,d1
        move.w  d2,d0
        bsr     up_run
        move.l  BIOS_UPSIZE,d0
        add.l   d0,d0
        add.l   d0,BIOS_UPDEST
        bra     up_end
3:      cmp.w   #FT_SPR,d2
        bne     4f
        and.w   #3,d3
        swap    d3
        lsl.l   #4,d3
        add.l   d3,d1
        moveq   #FT_SPR,d0
        bsr     up_run
        move.l  SINK_POS,d0             | continue where this one ended
        move.l  d0,d1
        and.l   #0x0FFFFF,d1
        move.l  d1,BIOS_UPDEST
        swap    d0
        lsr.w   #4,d0
        move.b  d0,BIOS_UPBANK
        bra     up_end
4:      cmp.w   #FT_PCM,d2
        bne     5f
        lsr.l   #1,d1
        and.w   #1,d3
        swap    d3
        lsl.l   #3,d3
        add.l   d3,d1
        moveq   #FT_PCM,d0
        bsr     up_run
        move.l  SINK_POS,d0
        move.l  d0,d1
        and.l   #0x07FFFF,d1
        add.l   d1,d1
        move.l  d1,BIOS_UPDEST
        swap    d0
        lsr.w   #3,d0
        move.b  d0,BIOS_UPBANK
        bra     up_end
5:      cmp.w   #FT_PAT,d2
        bne     up_end
        and.w   #3,d3
        swap    d3
        lsl.l   #4,d3
        add.l   d3,d1
        lsr.l   #8,d1
        move.l  d6,-(sp)
        move.w  d1,d6
        moveq   #FT_Z80,d0
        moveq   #0,d1
        bsr     sink_open
        clr.b   PAT_FILL
        move.l  BIOS_UPSIZE,d0
        bsr     pat_feed
        bsr     sink_close
        move.l  (sp)+,d6
up_end: clr.l   BIOS_UPSIZE
        movem.l (sp)+,d0-d3/a0
        rts
| d0 = sink type, d1 = position, a0 = source, size from BIOS_UPSIZE
up_run: bsr     sink_open
        move.l  BIOS_UPSIZE,d0
        bsr     sink_write
        bra     sink_close

|===========================================================================
| CD-DA in this mode.  Requests are executed step by step from the drive
| link interrupt: look up the track, find where it ends, play, and watch
| the position so that the track can repeat (or stop) at its end.
|===========================================================================
        .equ    CDS_IDLE,   0
        .equ    CDS_LOOKUP, 1           | ask where the track starts
        .equ    CDS_WSTART, 2
        .equ    CDS_WEND,   3           | waiting for the start of the next track
        .equ    CDS_WLEAD,  4           | waiting for the lead-out position
        .equ    CDS_PLAY,   5
        .equ    CDS_WPOS,   6           | waiting for the current position
        .equ    CDS_PAUSED, 7

| d0.w = command.b : track.b (BCD)   (called from anywhere)
cda_request:
        move.w  d0,CDA_REQ              | picked up by the link interrupt
        st      CDA_REQF
        rts

| interrupt context: act on a posted request
cda_accept:
        clr.b   CDA_REQF
        move.w  CDA_REQ,d0
        move.w  d0,d1
        lsr.w   #8,d1
        cmp.b   #7,d1
        bhi     9f
        and.b   #3,d1
        cmp.b   #2,d1
        beq     2f
        cmp.b   #3,d1
        beq     3f
        tst.b   d0                      | play: track 00 is not valid
        beq     9f
        cmp.b   CDA_TRACK,d0            | already playing this track:
        bne     1f                      | leave it alone
        tst.b   CDA_STATE
        beq     1f
        cmp.b   #CDS_PAUSED,CDA_STATE
        bne     9f
1:      move.b  d0,CDA_TRACK
        move.b  d1,CDA_ONCE             | 1: stop at the end, 0: repeat
        move.b  #5,CDA_RETRY
        move.b  #CDS_LOOKUP,CDA_STATE
        rts
2:      tst.b   CDA_STATE               | pause
        beq     9f
        move.b  #CDS_PAUSED,CDA_STATE
        move.l  #0x60000000,d0
        moveq   #0,d1
        bra     cd_pack
3:      cmp.b   #CDS_PAUSED,CDA_STATE   | resume
        bne     9f
        move.b  #CDS_PLAY,CDA_STATE
        move.b  #60,CDA_TMR
        move.l  #0x70000000,d0
        moveq   #0,d1
        bra     cd_pack
9:      rts

| position (minute, second, frame) from the status packet -> d0
cda_rx_msf:
        lea     CD_RX+2,a0
        moveq   #0,d0
        moveq   #5,d1
1:      lsl.l   #4,d0
        or.b    (a0)+,d0
        dbra    d1,1b
        rts

| one step per drive tick (interrupt context; d0-d3/a0-a1 are free)
cda_service:
        tst.b   RD_ACTIVE               | never while data is being read
        bne     9f
        tst.b   CDA_REQF
        bne     cda_accept
        moveq   #0,d0
        move.b  CDA_STATE,d0
        beq     9f
        tst.b   CD_CMDF
        bne     9f
        add.w   d0,d0
        move.w  cda_jt(pc,d0.w),d0
        jmp     cda_jt(pc,d0.w)
cda_jt: .word   cda_none-cda_jt
        .word   cda_lookup-cda_jt
        .word   cda_wstart-cda_jt
        .word   cda_wend-cda_jt
        .word   cda_wlead-cda_jt
        .word   cda_play-cda_jt
        .word   cda_wpos-cda_jt
        .word   cda_none-cda_jt
cda_none:
9:      rts

cda_fail:
        subq.b  #1,CDA_RETRY
        bne     1f
        clr.b   CDA_STATE
        rts
1:      move.b  #CDS_LOOKUP,CDA_STATE
        rts

| ask for the start address of the track
cda_lookup:
        moveq   #0x20,d0
        lsl.l   #8,d0
        move.b  #0x05,d0
        lsl.l   #8,d0
        move.b  CDA_TRACK,d0
        lsl.l   #8,d0
        move.b  CDA_TRACK,d1            | the answer repeats the low digit
        bsr     cd_pack
        move.b  #CDS_WSTART,CDA_STATE
        move.b  #20,CDA_TMR
        rts

cda_wstart:
        cmp.b   #5,CD_RX+1
        bne     cda_wait
        move.b  CDA_TRACK,d0
        and.b   #0x0F,d0
        cmp.b   CD_RX+8,d0
        bne     cda_wait
        btst    #3,CD_RX+6              | data track: nothing to play
        beq     1f
        clr.b   CDA_STATE
        rts
1:      bsr     cda_rx_msf
        move.l  d0,CDA_START
        moveq   #0,d0                   | next track number (BCD + 1)
        move.b  CDA_TRACK,d0
        addq.b  #1,d0
        move.b  d0,d1
        and.b   #0x0F,d1
        cmp.b   #0x0A,d1
        bne     2f
        addq.b  #6,d0
2:      move.b  d0,d2
        moveq   #0x20,d0
        lsl.l   #8,d0
        move.b  #0x05,d0
        lsl.l   #8,d0
        move.b  d2,d0
        lsl.l   #8,d0
        move.b  d2,d1
        bsr     cd_pack
        move.b  #CDS_WEND,CDA_STATE
        move.b  #20,CDA_TMR
        rts

cda_wait:
        subq.b  #1,CDA_TMR
        bne     9f
        bra     cda_fail
9:      rts

cda_wend:
        cmp.b   #5,CD_RX+1
        bne     cda_wait
        move.b  CDA_TRACK,d0            | answer for the following track?
        addq.b  #1,d0
        and.b   #0x0F,d0
        cmp.b   #0x0A,d0
        bne     1f
        moveq   #0,d0
1:      cmp.b   CD_RX+8,d0
        bne     cda_wait
        bsr     cda_rx_msf
        and.l   #0x00FFFF7F,d0          | drop the data track flag
        cmp.l   CDA_START,d0
        bhi     cda_start
        move.l  #0x20030000,d0          | last track: ask for the lead-out
        moveq   #0,d1
        bsr     cd_pack
        move.b  #CDS_WLEAD,CDA_STATE
        move.b  #20,CDA_TMR
        rts

cda_wlead:
        cmp.b   #3,CD_RX+1
        bne     cda_wait
        bsr     cda_rx_msf
        cmp.l   CDA_START,d0
        bhi     cda_start
        moveq   #-1,d0                  | unknown: never ends
| d0 = end position
cda_start:
        move.l  d0,CDA_END
        move.l  CDA_START,d0
        or.l    #0x30000000,d0          | play from the start of the track
        moveq   #0,d1
        bsr     cd_pack
        move.b  #CDS_PLAY,CDA_STATE
        move.b  #60,CDA_TMR
        rts

| playing: every so often ask where the drive is
cda_play:
        subq.b  #1,CDA_TMR
        bne     9f
        move.l  #0x20000000,d0
        moveq   #0,d1
        bsr     cd_pack
        move.b  #CDS_WPOS,CDA_STATE
        move.b  #20,CDA_TMR
9:      rts

cda_wpos:
        subq.b  #1,CDA_TMR
        beq     2f
        tst.b   CD_RX+1                 | position answer
        bne     9f
        bsr     cda_rx_msf
        tst.l   d0
        beq     9f
        cmp.l   CDA_START,d0            | still on the way there
        bcs     2f
        cmp.l   CDA_END,d0              | reached the end of the track?
        bcc     1f
2:      move.b  #CDS_PLAY,CDA_STATE
        move.b  #16,CDA_TMR
9:      rts
1:      tst.b   CDA_ONCE
        bne     3f
        move.b  #5,CDA_RETRY            | repeat
        move.l  CDA_END,d0
        bra     cda_start
3:      move.l  #0x60000000,d0          | play once: stop here
        moveq   #0,d1
        bsr     cd_pack
        clr.b   CDA_STATE
        rts
