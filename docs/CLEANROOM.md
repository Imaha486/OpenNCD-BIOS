# Clean-room statement

[日本語は下にあります](#クリーンルーム方針)

## What was used

OpenNCD BIOS was written from four kinds of source, and nothing else:

1. The public documentation on the [NeoGeo Development Wiki](https://wiki.neogeodev.org/): BIOS calls, BIOS RAM locations, the program header, the memory card format, memory mapped registers, the CD file types.
2. The hardware behaviour written down in open-source emulators: MAME, FinalBurn Neo, the NeoCD libretro core and Raine. These say what a register does when it is written. They do not contain the BIOS.
3. The behaviour of NeoRaine 1.4.3 itself, which expects certain routines at fixed ROM addresses.
4. Observation of how five games call the BIOS and which ROM addresses they read.

## What was not done

The original BIOS images were **never disassembled, traced or copied from**. They were used in two ways only:

- As a black box: run the same game with the same input and compare the picture and the audio track that gets opened.
- After the fact: a byte-by-byte comparison of the finished image against them, to measure similarity.

## Where the image matches an original ROM, and why

Run `tools/similarity_check.py` against your own reference ROM to reproduce this. For version 2.0, against the two reference images available to the author:

| Measure | Result |
|---|---|
| Code bytes in use (tables excluded) | 6,626 |
| Bytes equal at the same offset | 58 at most |
| Runs of 12 or more bytes that also occur anywhere in the reference | 21 at most |

The shared runs fall into these groups:

- **Hardware register sequences.** Writing a value to the decoder's register select port and then to its data port produces the same bytes no matter who writes the code, for example `13FC 000A 00FF 0101 13FC 0000 00FF 0103`. The same goes for the video registers.
- **Accesses dictated by the documented program header**, such as reading the region byte and indexing the per-region pointers at `$116`.
- **The string `0123456789ABCDEF`** used to print hexadecimal numbers.
- **One deliberate landmark** (see below).

Other places that necessarily agree with the original:

- **The exception vector and jump table addresses.** Games call `$C00444`, `$C0056A` and so on directly. The addresses are the interface.
- **The data tables at `$C02000`, `$C03000` and `$C04000`** (direction, distance and sine). Games read them straight from ROM, so they must hold the same mathematical functions. They are produced by the formulas in `tables.py`. The sine table differs from the original in four words where the original is mathematically inexact.
- **The memory card layout**, matched to save files so that existing saves stay readable, including two fixed header bytes.

Everything else is original, including the random table at `$C04200`, the font, the palette and the loading screen.

## The landmark block at `$C0B000`

Versions of Raine newer than NeoRaine 1.4.3 do not use fixed addresses. They scan the BIOS for short instruction sequences to find the loading screen routines, the palette and the tiles. To give that scan something to find, `bios.s` contains a block of 8 to 16 byte sequences built from the search conditions in Raine's source code. They were not copied from an original BIOS, but because Raine's conditions were derived from one, the same sequences also exist there.

Only the jump instructions in that block are ever executed. If you prefer an image without it, delete the block marked "Landmarks" in `src/bios.s` and the matching assertions in `build.py`. MAME, the NeoCD libretro core and NeoRaine 1.4.3 do not use it.

## Not legal advice

This document describes how the software was made. It is not a legal opinion. If you intend to redistribute the ROM commercially, consult a lawyer.

---

# クリーンルーム方針

## 根拠にしたもの

OpenNCD BIOS は、次の 4 種類の情報だけをもとに書いています。

1. [NeoGeo Development Wiki](https://wiki.neogeodev.org/) の公開仕様。BIOS コール、BIOS が使う RAM、プログラムヘッダ、メモリーカード形式、メモリマップトレジスタ、CD のファイル種別など。
2. オープンソースのエミュレータ（MAME、FinalBurn Neo、NeoCD libretro コア、Raine）のソースに書かれたハードウェアの挙動。「このレジスタに書くと何が起きるか」が書かれているもので、BIOS そのものは含まれていません。
3. NeoRaine 1.4.3 本体の挙動。このエミュレータは ROM の決まった番地に特定のルーチンがあることを前提にしています。
4. 5 本のゲームが BIOS をどう呼び、ROM のどの番地を読むかの観察。

## やっていないこと

純正 BIOS のイメージは、**逆アセンブルも、トレースも、流用もしていません**。使い道は次の 2 つだけです。

- ブラックボックスとしての比較。同じゲームに同じ入力を与え、画面と、開かれる音声トラックを見比べる。
- 完成後の検査。出来上がったイメージとバイト単位で比較し、どれだけ似ているかを測る。

## 純正 ROM と一致する箇所とその理由

`tools/similarity_check.py` に手元の参照 ROM を与えれば、同じ検査を再現できます。バージョン 2.0 を、作者の手元にある 2 つの参照イメージと比べた結果は次のとおりです。

| 項目 | 結果 |
|---|---|
| 使用中のコードのバイト数（数表を除く） | 6,626 |
| 同じ番地で一致するバイト数 | 最大 58 |
| 参照側のどこかにも現れる 12 バイト以上の並び | 最大 21 か所 |

共通の並びの内訳は次のとおりです。

- **ハードウェアレジスタへの書き込み列。** デコーダのレジスタ選択ポートに値を書き、続けてデータポートに書く、という操作は、誰が書いても同じバイト列になります（例: `13FC 000A 00FF 0101 13FC 0000 00FF 0103`）。ビデオ系のレジスタも同様です。
- **公開されているプログラムヘッダの仕様から決まるアクセス。** リージョンの値を読んで `$116` のリージョン別ポインタを引く処理など。
- **16 進表示用の文字列 `0123456789ABCDEF`。**
- **意図的に置いた目印 1 か所**（後述）。

このほか、必然的に純正と一致する箇所があります。

- **例外ベクタとジャンプテーブルの番地。** ゲームは `$C00444` や `$C0056A` を直接呼びます。番地そのものがインターフェースです。
- **`$C02000`、`$C03000`、`$C04000` の数表**（方向・距離・正弦）。ゲームが ROM から直接読むので、同じ数学関数の値が入っている必要があります。中身は `tables.py` の数式から生成しています。正弦表は、純正側が数学的に不正確な 4 語だけ値が異なります。
- **メモリーカードの記録形式。** 既存のセーブデータを読めるよう、セーブファイルの並びに合わせています（ヘッダの固定値 2 バイトを含む）。

それ以外はすべて独自です。`$C04200` の乱数表、フォント、パレット、ロード画面も含みます。

## `$C0B000` の目印ブロック

NeoRaine 1.4.3 より後の Raine は固定番地を使わず、BIOS の中から短い命令の並びを検索して、ロード画面のルーチン、パレット、タイルの場所を割り出します。その検索に引っかかるよう、`bios.s` には 8〜16 バイトの並びを集めたブロックを置いています。これは Raine のソースに書かれた検索条件から作ったもので、純正 BIOS から写したものではありません。ただし Raine の検索条件が純正 BIOS をもとに決められているため、結果として純正側にも同じ並びがあります。

このブロックで実際に実行されるのはジャンプ命令だけです。目印のないイメージがよければ、`src/bios.s` の "Landmarks" と書かれたブロックと、`build.py` の対応する検査を削除してください。MAME、NeoCD libretro コア、NeoRaine 1.4.3 はこの目印を使いません。

## 法的助言ではありません

この文書はソフトウェアの作り方を説明するもので、法的な見解ではありません。ROM を商用で再配布する場合は専門家に確認してください。
