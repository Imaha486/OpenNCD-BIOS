# Emulator setup

[日本語は下にあります](#エミュレータごとの設定)

Use `neocd.bin` (512 KB, byte-swapped) in every case. You supply your own game discs.

## MAME (`neocdz`)

1. Copy the file to `roms/neocdz/neocd.bin`.
2. MAME also requires `roms/neocdz/000-lo.lo`, the sprite zoom table. It is not part of this project.
3. Start with `mame neocdz -cdrom game.cue`.

MAME prints a wrong-checksum warning for `neocd.bin` and then runs normally.

MAME cannot read cue sheets whose audio tracks are MP3 files. Use WAV or BIN tracks, or a CHD.

MAME emulates a single-speed drive, so the first load takes about a minute (about 55 seconds for Viewpoint). The progress bar moving means it is working.

The region follows MAME's machine configuration.

## NeoCD libretro core (RetroArch)

1. Copy the file into the `neocd` folder inside RetroArch's system directory.
2. In the core options, choose it as the BIOS. It is listed with the type "Unknown".

Loading is much faster than in MAME because the core speeds up the drive.

## NeoRaine 1.4.3

Select the file under *Neocd options*, or set `neocd_bios = <path>` in `config/raine32_sdl.cfg`.

In NeoRaine the emulator reads the disc and the BIOS only provides services, so loading is instant apart from the animation.

## Raine after NeoRaine 1.4.3 (untested)

Select it the same way. This has not been tried. If it fails, please open an issue with the Raine version and what you saw.

## FinalBurn Neo (untested)

FBNeo identifies BIOS files by CRC and will not load an unknown one without changes to FBNeo itself.

## How the mode is chosen

| | Hardware mode | Assisted mode |
|---|---|---|
| Used by | MAME, NeoCD libretro core | NeoRaine, Raine |
| Entry | Reset vector, `$C00402` | `$C0A822`, called by the emulator |
| Disc reading | The BIOS sends drive commands and receives sectors | Done by the emulator |
| CD audio | The BIOS looks up the track, plays it and restarts it at the end | Done by the emulator |
| Loading screen | Drawn and updated by the BIOS | The emulator calls the BIOS drawing routines |

The BIOS selects assisted mode if it was entered at `$C0A822`, or if the emulator has patched the bytes at `$C0A87A`. Otherwise it uses hardware mode.

## Error messages

In hardware mode the BIOS stops with one of these if it cannot start a disc:

- `NOT A GAME DISC`: sector 16 is not an ISO 9660 volume descriptor.
- `IPL.TXT NOT FOUND`: the root directory has no `IPL.TXT`.
- `DISC READ ERROR`: a sector did not arrive after several attempts.

`SYSTEM HALT - EXCEPTION` followed by numbers is a CPU exception; the numbers are the vector and the top of the stack. Please include them in a bug report.

---

# エミュレータごとの設定

どの場合も `neocd.bin`（512KB、バイトスワップ形式）を使います。ゲームディスクはご自身のものを用意してください。

## MAME（`neocdz`）

1. `roms/neocdz/neocd.bin` として置きます。
2. MAME は `roms/neocdz/000-lo.lo`（スプライト拡大縮小用の表）も要求します。このプロジェクトには含まれません。
3. `mame neocdz -cdrom game.cue` で起動します。

`neocd.bin` についてチェックサム不一致の警告が出ますが、そのまま動きます。

MAME は音声トラックが MP3 の cue シートを読めません。WAV か BIN のトラック、または CHD を使ってください。

MAME は等速ドライブを再現するので、最初のロードに 1 分前後かかります（ビューポイントで約 55 秒）。進捗バーが進んでいれば正常です。

リージョンは MAME の本体設定に従います。

## NeoCD libretro コア（RetroArch）

1. RetroArch の system ディレクトリにある `neocd` フォルダに置きます。
2. コアオプションの BIOS 選択でこのファイルを選びます。種類は "Unknown" と表示されます。

コア側がドライブを高速化しているので、ロードは MAME よりずっと速く終わります。

## NeoRaine 1.4.3

*Neocd options* でファイルを指定するか、`config/raine32_sdl.cfg` に `neocd_bios = <パス>` を書きます。

NeoRaine ではエミュレータがディスクを読み、BIOS はサービスを提供するだけなので、ロードはアニメーションを除けば一瞬です。

## NeoRaine 1.4.3 より後の Raine（未検証）

同じ方法で指定します。実際に試してはいません。動かなかった場合は、Raine のバージョンと症状を添えて issue を立ててください。

## FinalBurn Neo（未検証）

FBNeo は BIOS を CRC で識別するため、FBNeo 側を変更しない限り未知の BIOS は読み込めません。

## モードの判定

| | ハードウェアモード | 代行モード |
|---|---|---|
| 使うエミュレータ | MAME、NeoCD libretro コア | NeoRaine、Raine |
| 入口 | リセットベクタ `$C00402` | `$C0A822`（エミュレータが呼ぶ） |
| ディスク読み込み | BIOS がドライブに命令を送りセクタを受け取る | エミュレータが行う |
| CD-DA | BIOS がトラック位置を調べて再生し、終端で頭出しする | エミュレータが行う |
| ロード画面 | BIOS が描画・更新する | エミュレータが BIOS の描画ルーチンを呼ぶ |

`$C0A822` から入った場合、またはエミュレータが `$C0A87A` のバイトを書き換えている場合は代行モード、それ以外はハードウェアモードになります。

## エラー表示

ハードウェアモードでは、ディスクを起動できないとき次のいずれかを表示して止まります。

- `NOT A GAME DISC`: セクタ 16 が ISO 9660 のボリューム記述子ではない。
- `IPL.TXT NOT FOUND`: ルートディレクトリに `IPL.TXT` がない。
- `DISC READ ERROR`: 何度か試してもセクタが届かなかった。

`SYSTEM HALT - EXCEPTION` と数字が出た場合は CPU 例外です。数字はベクタ番号とスタックの先頭です。不具合報告に書き添えてください。
