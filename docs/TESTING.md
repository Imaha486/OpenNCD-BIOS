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

## Version 2.2

2.2 answers a report from a MAME-based system (not available here) where 2.0 stopped with an exception in many games. The suspected cause was reproduced by changing a test copy of the NeoCD libretro core so that the vertical blank interrupt cannot be held back by the BIOS (delivered at level 2, mask register ignored):

- With that change, 2.0 hangs at the loading screen in four of the five games. 2.2 boots all five, and The King of Fighters '94 plays into a fight.
- The hang is not the same symptom as the reported exception, so this shows the same kind of fault, not proof that the report is fixed. It has not been confirmed on the reporting system.

Regression with the unmodified emulators: all five games, Blue and Red (a free homebrew game), the self-test disc and the 700-file disc on the libretro core; The King of Fighters '94 into a fight, through two in-game loads, on MAME 0.264; The King of Fighters '94 into a fight with audio on NeoRaine 1.4.3.

## Version 2.3 (Raine 0.98)

Raine 0.98 (64-bit Windows build, run under Wine) with games loaded through its menu:

- With 2.2 the screen stays on LOADING with an empty bar for good. A user reported a crash at this point on Windows; the hang seen here is taken to be the same fault, but the crash itself was not reproduced.
- With 2.3: Viewpoint reaches the title and attract mode. The King of Fighters '94 reaches the title with a correct logo and the start button leads to the game select screen. Flying Power Disc runs its attract match, which needs in-game loads, and start leads to mode select. Quiz King of Fighters runs its attract mode and start leads to mode select. Raine opened the expected audio track in the last two.
- Not done: Twinkle Star Sprites, and anything past the first menu in any game. The test script could not find which key Raine maps to button A, so no game was actually played.

Regression for 2.3: six games and the self-test disc on the libretro core; The King of Fighters '94 on MAME 0.264 (title, logo, in-game load); The King of Fighters '94 to team select on NeoRaine 1.4.3.

## Not tested

- Any game other than the five above
- Any game through to its ending
- Raine versions between NeoRaine 1.4.3 and 0.98
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

## バージョン 2.2

2.2 は、MAME ベースのシステム（こちらでは用意できません）で 2.0 が多くのゲームで例外停止した、という報告への対応です。疑った原因は、NeoCD libretro コアのテスト用コピーを「垂直帰線割り込みを BIOS 側で止められない」ように改造して再現しました（レベル 2 で配送し、マスクレジスタを無視）。

- この改造下では、2.0 は 5 本中 4 本がロード画面で止まります。2.2 は 5 本すべて起動し、ザ・キング・オブ・ファイターズ'94 は対戦まで進みます。
- ロード画面での停止は、報告された例外表示と同じ症状ではありません。同じ種類の不具合を再現したというだけで、報告の件が直った証明ではありません。報告元のシステムでは未確認です。

改造していないエミュレータでの回帰確認: libretro コアで 5 本すべて、Blue and Red（フリーのホームブリュー）、自己テスト用ディスク、700 本ディスク。MAME 0.264 でザ・キング・オブ・ファイターズ'94 をゲーム中のロード 2 回を挟んで対戦まで。NeoRaine 1.4.3 でザ・キング・オブ・ファイターズ'94 を音声付きで対戦まで。

## バージョン 2.3（Raine 0.98）

Raine 0.98（64 ビット Windows 版を Wine 上で実行）で、メニューからゲームを読み込んで確認しました。

- 2.2 では LOADING の画面でバーが空のまま止まり続けます。Windows ではこの時点でクラッシュするという報告があり、こちらで見た停止は同じ不具合だと判断していますが、クラッシュそのものは再現していません。
- 2.3: ビューポイントはタイトルとデモまで。ザ・キング・オブ・ファイターズ'94 はロゴが正しく出たタイトルまで進み、スタートボタンでゲーム選択画面に入ります。フライングパワーディスクはデモの試合（ゲーム中のロードを伴う）が動き、スタートでモード選択へ。クイズ キング・オブ・ファイターズはデモが動き、スタートでモード選択へ。後の 2 本では Raine が想定どおりの音声トラックを開きました。
- 未実施: ティンクルスタースプライツ、および各ゲームの最初のメニューより先。テスト用スクリプトから、Raine が A ボタンに割り当てているキーを特定できなかったため、実際のプレイはしていません。

2.3 の回帰確認: libretro コアで 6 本と自己テスト用ディスク。MAME 0.264 でザ・キング・オブ・ファイターズ'94（タイトル、ロゴ、ゲーム中のロード）。NeoRaine 1.4.3 でザ・キング・オブ・ファイターズ'94 をチーム選択まで。

## 未検証

- 上の 5 本以外のゲーム
- 各ゲームのエンディングまでの通しプレイ
- NeoRaine 1.4.3 と 0.98 の間の Raine
- FinalBurn Neo
- 実機
- 2 人プレイの入力
