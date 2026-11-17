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

## Version 2.4 (sound)

Method: the NeoCD libretro core was given a test hook that logs every command sent to the sound CPU and every sample the sound chip is told to play, and dumps the sound program memory and the sample memory at the end of a run. The same game was then run with an original BIOS and with this one.

- Before 2.4, the original sent command 3 to the sound driver twice before the game's first own command; this BIOS sent none. With 2.4 the opening sequence is the same.
- Before 2.4, the original left `08` in every unused byte of sample memory; this BIOS left zero. With 2.4, sound program memory and sample memory are byte-for-byte identical after comparable runs of Viewpoint, The King of Fighters '94, Quiz King of Fighters and Twinkle Star Sprites (the last one compared in the first story-mode match).
- Flying Power Disc was compared in different demo scenes, so its memories differ; the differences are the ones expected from different voice files being loaded.

What this does not show:

- Last Resort was not available. Whether 2.4 makes it sound is unknown.
- A report that the charge shot in Twinkle Star Sprites is silent when fired at "READY GO" was not reproduced: nobody listened, and the comparison above found no difference in that match. It may still be there.
- The comparison was made in hardware mode only. In Raine and NeoRaine the emulator loads the sound data itself.

Regression for 2.4: seven discs and the self-test on the libretro core; The King of Fighters '94 into a fight on MAME 0.264; The King of Fighters '94 with audio on NeoRaine 1.4.3; Twinkle Star Sprites into a match with audio on Raine 0.98.

## Version 2.5 (Samurai Shodown RPG)

Shinsetsu Samurai Spirits Bushidou Retsuden, from a disc image without audio tracks, so nothing here says anything about its music.

| Emulator | 2.4 | 2.5 |
|---|---|---|
| NeoCD libretro core | Never leaves the first loading screen; the machine resets in a loop | Character select, story select, opening battle and the first indoor scene, through several loads |
| MAME 0.264 | not run | Intro, title, character select, opening battle |
| NeoRaine 1.4.3 | Exception screen right after boot | Character select, story select, opening battle |
| Raine 0.98 | not run | Intro and title menu. The run could not get further because the key for the A button was not found; whether a game can be started there is unknown |

- With an original BIOS in the same libretro core, the game boots, and then resets in a loop after the start button. So there was no working reference to compare with, and what is described above is "the game runs", not "the game runs as on a console".
- The game asks for one file (`!OGO0000.PRG`) that is on the disc under another name (`_OGO0000.PRG`). The request ends with nothing read. What a console does in that case is not known.
- Not checked: saving, anything past the first indoor scene, the game's error screen.
- The directory lookup change was checked with the 700-file Viewpoint disc and the self-test disc.

Regression for 2.5: six games, Blue and Red, the 700-file disc and the self-test on the libretro core; The King of Fighters '94 to team select on MAME 0.264; The King of Fighters '94 to order select on NeoRaine 1.4.3. The other games were not run again on Raine 0.98.

## Version 2.6 (stray progress bar, blank variant)

- Samurai Shodown RPG on the libretro core, 9000 frames with the same input: with 2.5 a grey bar is drawn across the middle of the picture during a later load and stays for about a second after the loading screen has gone; with 2.6 it does not appear. The report came from a MAME-based system where the bar stayed for good; that system was not available, so the fix is confirmed only on the core.
- `neocd_blank.bin`: the first load and the in-game loads of the same run show a black picture and take the same number of frames as the standard image (measured in 5-frame steps: Samurai Shodown RPG, The King of Fighters '94, Viewpoint).
- Regression, both images: six games, Blue and Red, the 700-file disc and the self-test on the libretro core; The King of Fighters '94 to order select on NeoRaine 1.4.3. Standard image only: The King of Fighters '94 to team select on MAME 0.264. Raine 0.98 was not run.

## Not tested

- Any game other than the six above
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

## バージョン 2.4（サウンド）

方法: NeoCD libretro コアにテスト用の仕掛けを入れ、サウンド CPU に送られるコマンドと、サウンドチップが再生を指示されるサンプルをすべて記録し、実行の最後にサウンドプログラム用メモリとサンプル用メモリを書き出すようにしました。そのうえで、同じゲームを純正 BIOS とこの BIOS で動かして比べています。

- 2.4 より前: 純正はゲーム自身の最初のコマンドより前に、サウンドドライバへコマンド 3 を 2 回送っていました。この BIOS は送っていませんでした。2.4 で冒頭の並びが一致しました。
- 2.4 より前: 純正はサンプル用メモリの未使用部分をすべて `08` で埋めていました。この BIOS はゼロのままでした。2.4 では、ビューポイント、ザ・キング・オブ・ファイターズ'94、クイズ キング・オブ・ファイターズ、ティンクルスタースプライツ（ストーリーモード最初の対戦で比較）について、サウンドプログラム用メモリとサンプル用メモリが 1 バイトも違わず一致します。
- フライングパワーディスクは別々のデモ場面で比べたため、メモリの内容は異なります。違いは、読み込まれた音声ファイルが違うことから予想されるとおりのものです。

これで分からないこと:

- ラストリゾートは手元にありません。2.4 で音が出るようになったかは不明です。
- ティンクルスタースプライツで「READY GO」と同時に撃ったチャージショットが無音になる、という報告は再現できていません。耳で聴いた確認はしておらず、上の比較ではその対戦に違いは見つかりませんでした。不具合が残っている可能性はあります。
- 比較はハードウェアモードだけで行いました。Raine と NeoRaine では、サウンドのデータはエミュレータ自身が読み込みます。

2.4 の回帰確認: libretro コアでディスク 7 枚と自己テスト。MAME 0.264 でザ・キング・オブ・ファイターズ'94 を対戦まで。NeoRaine 1.4.3 でザ・キング・オブ・ファイターズ'94 を音声付きで。Raine 0.98 でティンクルスタースプライツを音声付きで対戦まで。

## バージョン 2.5（武士道烈伝）

真説サムライスピリッツ 武士道烈伝。音声トラックを含まないディスクイメージで確認したため、BGM については何も確かめていません。

| エミュレータ | 2.4 | 2.5 |
|---|---|---|
| NeoCD libretro コア | 最初のロード画面から進まず、リセットを繰り返す | キャラクター選択、物語選択、冒頭の戦闘、最初の屋内シーンまで。途中のロードも数回通過 |
| MAME 0.264 | 未実行 | オープニング、タイトル、キャラクター選択、冒頭の戦闘 |
| NeoRaine 1.4.3 | 起動直後に例外画面 | キャラクター選択、物語選択、冒頭の戦闘 |
| Raine 0.98 | 未実行 | オープニングとタイトルメニューまで。A ボタンに当たるキーが分からず、その先は進めていません。ゲームを開始できるかは不明です |

- 同じ libretro コアに純正 BIOS を入れた場合、起動はしますが、スタートボタンの後にリセットを繰り返します。比較できる正常動作の手本がないため、上の結果は「ゲームが動く」であって「実機と同じに動く」ではありません。
- ゲームが要求するファイルのうち 1 つ（`!OGO0000.PRG`）は、ディスク上では別名（`_OGO0000.PRG`）になっています。この要求は何も読まずに終わります。実機がこのときどう動くかは分かっていません。
- 未確認: セーブ、最初の屋内シーンより先、ゲーム自身のエラー画面。
- ディレクトリ検索の変更は、700 ファイル入りのビューポイントと自己テストディスクで確認しました。

2.5 の回帰確認: libretro コアでゲーム 6 本、Blue and Red、700 ファイルのディスク、自己テスト。MAME 0.264 でザ・キング・オブ・ファイターズ'94 をチーム選択まで。NeoRaine 1.4.3 でザ・キング・オブ・ファイターズ'94 を順番選択まで。Raine 0.98 では他のゲームを再実行していません。

## バージョン 2.6（残る進捗バー、ブランク版）

- 武士道烈伝を libretro コアで同じ入力のまま 9000 フレーム実行。2.5 では、途中のロードで画面中央に灰色のバーが描かれ、ロード画面が消えた後も 1 秒ほど残ります。2.6 では出ません。報告は MAME ベースの機器で「バーが出たままになる」というものでしたが、その機器は手元にないため、修正を確認できたのはコア上だけです。
- `neocd_blank.bin`: 同じ実行で、最初のロードもゲーム中のロードも黒い画面になり、かかるフレーム数は通常版と同じでした（5 フレーム刻みで計測。武士道烈伝、ザ・キング・オブ・ファイターズ'94、ビューポイント）。
- 回帰確認（両方のイメージ）: libretro コアでゲーム 6 本、Blue and Red、700 ファイルのディスク、自己テスト。NeoRaine 1.4.3 でザ・キング・オブ・ファイターズ'94 を順番選択まで。通常版のみ: MAME 0.264 でザ・キング・オブ・ファイターズ'94 をチーム選択まで。Raine 0.98 は実行していません。

## 未検証

- 上の 6 本以外のゲーム
- 各ゲームのエンディングまでの通しプレイ
- NeoRaine 1.4.3 と 0.98 の間の Raine
- FinalBurn Neo
- 実機
- 2 人プレイの入力
