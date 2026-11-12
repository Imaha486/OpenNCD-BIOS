| SPDX-License-Identifier: Zlib
| Copyright (c) 2026 Imaha486
| test program for OpenNCD BIOS: long LOADFILE list and CARD round trips
        .text
        .org 0
        .long 0x10F300, 0xC00402
        .rept 19
        .long 0xC00426
        .endr
        .long 0xC004F2, 0xC004EC, 0xC004E6      | 21-23 CD
        .long 0xC004E0
        .long timer, vbl
        .rept 37
        .long 0xC00426
        .endr
        .org 0x100
        .ascii "NEO-GEO"
        .byte 0
        .word 0x0999
        .long 0x00100000, 0x00100000
        .word 0
        .byte 2,0
        .long dips, dips, dips
        .org 0x122
        jmp user
        jmp ret
        jmp ret
        jmp ret
ret:    rts
dips:   .fill 32,1,0
timer:  move.w #2,0x3C000C
        rte
vbl:    move.w #4,0x3C000C
        move.b d0,0x300001
        rte
user:   tst.b 0x10FDAE
        bne 1f
        jmp 0xC00444
1:      tst.b done
        bne idle
        st done
        | --- 40 files in one list
        lea list,a0
        jsr 0xC00564
        | --- card: save 300 bytes, read back
        lea 0x130100,a0
        move.w #299,d0
        moveq #7,d1
2:      move.b d1,(a0)+
        add.b #13,d1
        dbra d0,2b
        move.w #0x1234,0x10FDCE
        clr.b 0x10FDD0
        move.l #0x130100,0x10FDC8
        move.w #300,0x10FDCC
        move.b #3,0x10FDC4
        jsr 0xC00468
        move.b 0x10FDC6,0x130800
        move.l #0x130400,0x10FDC8
        move.w #300,0x10FDCC
        move.b #2,0x10FDC4
        jsr 0xC00468
        move.b 0x10FDC6,0x130801
        | --- replace with 100 bytes, read back
        move.l #0x130180,0x10FDC8
        move.w #100,0x10FDCC
        move.b #3,0x10FDC4
        jsr 0xC00468
        move.b 0x10FDC6,0x130802
        move.l #0x130600,0x10FDC8
        move.w #100,0x10FDCC
        move.b #2,0x10FDC4
        jsr 0xC00468
        move.b 0x10FDC6,0x130803
        | --- too large: must fail and keep the old save
        move.l #0x130100,0x10FDC8
        move.w #8000,0x10FDCC
        move.b #3,0x10FDC4
        jsr 0xC00468
        move.b 0x10FDC6,0x130804
        move.l #0x130700,0x10FDC8
        move.w #100,0x10FDCC
        move.b #2,0x10FDC4
        jsr 0xC00468
        move.b 0x10FDC6,0x130805
        move.b #1,0x10FDC4              | search
        jsr 0xC00468
        move.w 0x10FDD0,0x130806
        move.l #0x444F4E45,0x130900
idle:   move.b d0,0x300001
        bra idle
done:   .byte 0
        .balign 2
list:
        .irp n,00,01,02,03,04,05,06,07,08,09,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31,32,33,34,35,36,37,38,39
        .ascii "t\n\().prg"
        .byte 0,0
        .balign 2
        .long 0x130000+4*(1\n-100)
        .endr
        .byte 0,0
