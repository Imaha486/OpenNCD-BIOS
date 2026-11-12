# Test record

[日本語は下にあります](#検証記録)

This is what was actually checked for version 2.0, and what was not. All tests were scripted: the emulator ran headless, button presses were injected at fixed times and screenshots were taken at intervals.

## Results

| Game | MAME 0.264 `neocdz` | NeoCD libretro core | NeoRaine 1.4.3 |
|---|---|---|---|
| Viewpoint | Stage played to game over | Stage played to game over | Stage played |
| The King of Fighters '94 | Team select, in-game load, fight | Team select, in-game load, fight | Team select, in-game load, fight |
| Flying Power Disc | Player select, match | Attract mode only | Reached player select |
| Quiz King of Fighters | Board and questions | Attract mode only | Reached chapter 1 |
| Twinkle Star Sprites | Story mode match | Title screen only | Reached story mode |

"Attract mode only" and "title screen only" mean the game booted and ran without input; nobody pressed start in that combination.

## CD audio

Nobody listened to it. It was checked indirectly:

- **MAME**: for all five games, a script read the drive status each few seconds. It showed the drive playing, with the position advancing inside the requested track. Looping at the end of a track was confirmed with a Viewpoint test disc whose tracks were cut to 15 seconds.
- **NeoCD libretro core**: a locally added log line in the core showed play commands for the right tracks in Viewpoint, and a repeat command when the 15-second test track ended.
- **NeoRaine 1.4.3**: the emulator was seen to open the audio file of the expected track in The King of Fighters '94.

## Backup RAM (memory card)

- NeoCD libretro core: after boot, the save RAM holds a correctly formatted, empty card.
- NeoRaine 1.4.3: saving options in Twinkle Star Sprites and loading them again was confirmed in version 1.0. It was not repeated for 2.0.
- MAME: not checked.

## One caveat about the final build

After the full test runs, one change was made: the sector interrupt handler now writes a single mode word to the transfer controller instead of nine. With that final build, all five games were booted again on the libretro core, and Viewpoint was booted again on MAME and on NeoRaine. The longer play sessions in the table above were not repeated.

## Version 2.1

The table above was produced with 2.0. For 2.1 the following was run:

- **Self-test disc** (`tests/`) on the NeoCD libretro core: a 40-file load list, a 300-byte and a 100-byte memory card save with read-back, and an 8000-byte save that must fail without destroying the existing one. All pass. The same disc on 2.0 loads 32 of 40 files and loses the save.
- **Large directory**: Viewpoint with 700 extra files in the root directory boots on the libretro core. On 2.0 it does not.
- **Regression, libretro core**: all five games boot; The King of Fighters '94 was played into a fight; play commands for the expected tracks were logged in four games.
- **Regression, MAME**: The King of Fighters '94 boots and its first track plays. The other four were not run again.
- **Regression, NeoRaine 1.4.3**: The King of Fighters '94 was played into a fight with the expected audio tracks opened; Quiz King of Fighters reached the board. The other three were not run again.

The new system work area values, the sound command call and the multi-sector PAT handling have no test of their own: none of the five games depends on them.

## Not tested

- Any game other than the five above
- Any game through to its ending
- Raine versions after NeoRaine 1.4.3
- FinalBurn Neo
- Real hardware
- Two-player input

---

# 検証記録

バージョン 2.0 で実際に確かめたことと、確かめていないことの記録です。テストはすべてスクリプトで行いました。エミュレータを画面なしで動かし、決まった時刻にボタン入力を送り、一定間隔でスクリーンショットを撮っています。

## 結果

| ゲーム | MAME 0.264 `neocdz` | NeoCD libretro コア | NeoRaine 1.4.3 |
|---|---|---|---|
| ビューポイント | ゲームオーバーまでプレイ | ゲームオーバーまでプレイ | ステージをプレイ |
| ザ・キング・オブ・ファイターズ'94 | チーム選択、対戦前ロード、対戦 | チーム選択、対戦前ロード、対戦 | チーム選択、対戦前ロード、対戦 |
| フライングパワーディスク | 選手選択、試合 | デモのみ | 選手選択まで |
| クイズ キング・オブ・ファイターズ | すごろくと出題 | デモのみ | 第一章まで |
| ティンクルスタースプライツ | ストーリーモードの対戦 | タイトル画面のみ | ストーリーモードまで |

「デモのみ」「タイトル画面のみ」は、起動して入力なしで動き続けたという意味です。その組み合わせではスタートボタンを押していません。

## CD-DA

耳で聴いた確認はしていません。次の方法で間接的に確かめました。

- **MAME**: 5 本すべてで、数秒おきにドライブの状態をスクリプトで読みました。ドライブは再生中で、位置が指定トラックの範囲内を進んでいました。曲の終端でのループは、トラックを 15 秒に切り詰めたビューポイントのテスト用ディスクで確認しました。
- **NeoCD libretro コア**: コアに手元でログ出力を 1 行足し、ビューポイントで正しいトラックへの再生命令が出ること、15 秒のテスト用トラックの終端で再生命令が出し直されることを確認しました。
- **NeoRaine 1.4.3**: ザ・キング・オブ・ファイターズ'94 で、エミュレータが想定どおりのトラックの音声ファイルを開くことを確認しました。

## バックアップ RAM（メモリーカード）

- NeoCD libretro コア: 起動後のセーブ RAM に、正しくフォーマットされた空のカードが書かれていることを確認。
- NeoRaine 1.4.3: ティンクルスタースプライツでオプションをセーブし、読み直せることをバージョン 1.0 で確認。2.0 では繰り返していません。
- MAME: 未確認。

## 最終ビルドについての注意

一通りのテストを終えた後で、1 か所だけ変更を入れました。セクタ割り込みの処理が転送コントローラに書き込む値を、9 語から動作モードの 1 語だけに減らしています。この最終ビルドでは、libretro コアで 5 本すべて、MAME と NeoRaine でビューポイントの起動を確かめ直しました。上の表にある長めのプレイは繰り返していません。

## バージョン 2.1

上の表は 2.0 で取ったものです。2.1 では次を実行しました。

- **自己テスト用ディスク**（`tests/`）を NeoCD libretro コアで実行: 40 本のロードリスト、300 バイトと 100 バイトのメモリーカード保存と読み戻し、既存データを壊さずに失敗すべき 8000 バイトの保存。すべて合格。同じディスクを 2.0 で動かすと、40 本中 32 本しか読まれず、セーブも失われます。
- **大きなディレクトリ**: ルートディレクトリに 700 本のファイルを足したビューポイントが libretro コアで起動。2.0 では起動しません。
- **回帰確認（libretro コア）**: 5 本すべて起動。ザ・キング・オブ・ファイターズ'94 は対戦まで。4 本で想定どおりのトラックへの再生命令を確認。
- **回帰確認（MAME）**: ザ・キング・オブ・ファイターズ'94 が起動し、最初のトラックが再生されることを確認。残り 4 本は再実行していません。
- **回帰確認（NeoRaine 1.4.3）**: ザ・キング・オブ・ファイターズ'94 を対戦まで進め、想定どおりの音声トラックが開かれることを確認。クイズ キング・オブ・ファイターズはすごろく画面まで。残り 3 本は再実行していません。

追加したシステムワークエリアの値、サウンドコマンドのコール、複数セクタにまたがる PAT の処理には専用のテストがありません。5 本のどれもこれらに依存していないためです。

## 未検証

- 上の 5 本以外のゲーム
- 各ゲームのエンディングまでの通しプレイ
- NeoRaine 1.4.3 より後の Raine
- FinalBurn Neo
- 実機
- 2 人プレイの入力
