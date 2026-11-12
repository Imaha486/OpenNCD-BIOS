# Contributing

[日本語は下にあります](#コントリビュートについて)

## The one hard rule

This project only has value if it stays clean. **Do not contribute anything you learned by disassembling, decompiling or tracing an original NEOGEO CD BIOS or a patched copy of one**, and do not paste bytes from one. If you have studied such a disassembly closely, please report the bug and let someone else write the fix.

Acceptable sources are public documentation, the source code of open-source emulators (which describes the hardware, not the BIOS), and what a game can be observed to do: which BIOS calls it makes, with which arguments, and which addresses it reads.

In a pull request, say where the information for the change came from. Contributions are accepted under the zlib License.

## Bug reports

Please include:

- the emulator and its exact version
- the game, and its region if you know it
- what you did and what you saw; a screenshot helps
- for `SYSTEM HALT - EXCEPTION`, the numbers on the screen

Do not attach BIOS files, game files or disc images, and do not link to them.

## Code

- `python3 build.py` must succeed. Its assertions guard the fixed addresses emulators rely on.
- Keep the jump table slots and the entry points at `$C0A822`, `$C0C760`, `$C0C814`, `$C0C8B2` and `$C0E602` where they are.
- In hardware mode, only use register behaviour that MAME, FinalBurn Neo and the NeoCD core all implement the same way.
- BIOS calls can be entered in user mode. Do not write to the status register in them.
- Say which emulators and games you tested with.

---

# コントリビュートについて

## 絶対に守ってほしいこと

このプロジェクトは、クリーンであることに価値があります。**純正の NEOGEO CD BIOS、またはそのパッチ版を逆アセンブル・逆コンパイル・トレースして得た知識は持ち込まないでください。** バイト列の貼り付けも同様です。そうした逆アセンブル結果を詳しく読んだことがある方は、不具合の報告にとどめ、修正は他の人に任せてください。

根拠にしてよいのは、公開されている仕様書、オープンソースのエミュレータのソース（書かれているのはハードウェアの挙動で、BIOS ではありません）、そしてゲームの外から観察できる振る舞い（どの BIOS コールをどんな引数で呼ぶか、どの番地を読むか）です。

プルリクエストには、その変更の根拠にした情報の出どころを書いてください。送っていただいた変更は zlib ライセンスで取り込みます。

## 不具合報告

次の情報を添えてください。

- エミュレータ名と正確なバージョン
- ゲーム名（わかればリージョンも）
- 何をして、何が起きたか。スクリーンショットがあると助かります
- `SYSTEM HALT - EXCEPTION` の場合は、画面に出ている数字

BIOS、ゲームのファイル、ディスクイメージは添付しないでください。リンクも貼らないでください。

## コード

- `python3 build.py` が通ること。中のアサーションは、エミュレータが前提にしている固定番地を守るためのものです。
- ジャンプテーブルの各スロットと、`$C0A822`、`$C0C760`、`$C0C814`、`$C0C8B2`、`$C0E602` の入口は動かさないでください。
- ハードウェアモードでは、MAME、FinalBurn Neo、NeoCD コアの 3 つが同じように再現しているレジスタ動作だけを使ってください。
- BIOS コールはユーザーモードから呼ばれることがあります。その中でステータスレジスタに書き込まないでください。
- どのエミュレータとゲームで試したかを書いてください。
