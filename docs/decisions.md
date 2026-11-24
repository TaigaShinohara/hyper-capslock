# 判断の記録

2026-11-17 の改善依頼に対する実装判断。

Mac と Windows の実機では、まだ押して確認していない。

## 使う人の環境（確認済み）

- macOS と Windows の両方。
- US 配列と JIS 配列の両方。
- 主エディタは Cursor。VS Code は副次まで。
- Raycast の Hyper Key は使わない。
- 届ける相手は、AI に指示して開発する人。

残すもの: `CapsLock` をすぐ離すと `Esc`、長押しは Hyper。1個ずつ足す。OS ごとのフォルダ。

## 必須の指摘への対応

| ID | 対応 |
| --- | --- |
| M-01 | 上の環境を前提にした。チャットの送り先は Cursor。VS Code の `Command+L`（行選択）には送らない。配列は両方を、手順と確認の手順に入れた。 |
| M-02 | macOS の `CapsLock` は、`Shift` 1つに `Command`・`Control`・`Option` を付けて押したままにする。4つの修飾を別々のイベントに分けない。ピリオドは安全ルールで捨てる。Q、W、H は、割り当てるまで押さない、と手順に書いた。EventViewer での確認は [確認の手順](TESTING.md) の最初。 |
| M-03 | 全部承認（提案があるときの `Command+Enter`）と全部却下（提案があるときの `Command+Shift+Backspace`）は送らない。`Command+Shift+L` も送らない。チャットは `Command+L` / `Ctrl+L` で、開いていると閉じると文書に書いた。生成停止の `Esc` という説明は撤回した。 |
| M-04 | JIS は「対象外」とはしない。macOS は EventViewer の結果で `caps_lock` と `japanese_eisuu` を別ルールにする。Windows はスキャンコード `03A` を見る。離した通知が来ない場合は、そのキーボードでは使わない、と確認の手順に書いた。スキャンコードをレジストリで書き換える手順は置かない。 |
| M-05 | Windows は1つの方針にまとめた。推奨は Kanata のレイヤー。押しているあいだに具体的なショートカットだけを送り、`Ctrl+Alt+Shift+Win` は出さない。離しただけでも Office キーにならない。AutoHotkey も同じ原則。同時には使わない。Office キーをレジストリで止める方法は任意で、設定ファイルはそれを実行しない。 |
| M-06 | 手順の順番は、まずコア（`CapsLock` をすぐ離すと `Esc`、長押しで Office も Command 単独も出ないこと）を見て、そのあとルール `3. スターター` と `4. スターター` を有効にする。以前の「AutoHotkey が常に先なら優先度を下げる」は使わない。Windows は Office キー自体を出さないため。コアの確認が失敗したら、最初に入れるキーは足さない。 |
| M-07 | 文書の整理（表を1か所にする、個数の言い方をやめる）は通常の文書変更。キーの送り先を変えるのも通常。Windows を「4修飾を送る」から「レイヤーで具体的なキーだけ送る」に変えたのは、主要な入れ方を変える大きな変更。 |

## 改善提案への対応

| ID | 対応 |
| --- | --- |
| S-01 | 「再起動なしで安定、Esc の判定が速い」は出典が無いので削除した。Kanata を推奨する理由は、最初に入れるキーが入っていて、Office キーを出さないこと。 |
| S-02 | 「一切衝突しない」は削除した。Office キーと、Cursor / VS Code の既定キーを文書に書いた。 |
| S-03 | 往復の図から `Hyper+Enter` を外し、送信は普通の `Enter` にした。`Hyper+T` は残した。図と表は keymap.md だけ。 |
| S-04 | `Hyper+Space` は最初から割り当てない。 |
| S-05 | 管理者として開いたウィンドウでは効かないことがある、と「うまくいかないとき」と確認の手順に書いた。AutoHotkey は公式 FAQ。Kanata は未確認。 |
| S-06 | Raycast の `Hyper+Space` は Spotlight（`Command+Space`）の置き換えではない、と書いた。 |
| S-07 | OS ごとに、外し方を書いた。 |

## ここで確認できたこと

- Karabiner の JSON は、JSON として読めた。
- Kanata v1.12.0 の Linux 版（`kanata_linux_x64`）で `hyper-capslock.kbd` に `--check` を付け、`config file is valid` と出た。Windows 上でのキーの動きは未確認。
- AutoHotkey は Linux では動かせない。スクリプトは v2 の公式の書き方に沿って読んだだけ。

Mac、Windows、JIS の実機確認は [確認の手順](TESTING.md)。

## アプリアイコン（2026-11-24 決定）

- 正式アイコンは本人が候補から選んだ「CapsLock の中に相棒が入ったコックピット」案。黒いキーキャップの正面にコックピット窓があり、中にヘッドセットを付けた相棒（黒い丸顔、水色の LED の目と口）が両手を上げて座り、窓の下にティールの計器盤、キーの前面に黄色で `CAPS`。
- 経緯: 候補12案 → 6系（ロケット）と11系（ガラス＋LED顔）を展開 → 本人の指定で「11の感じで、コックピットに相棒」→ フラットな絵柄（初期案の4・5・6あたり）→ 3系を展開 → 本人の指定でロケットを外し「もっと CapsLock に入ってる感じ」→ 「コックピット窓」案の1番を本人が採用。手は初期案の大きな人の手から、相棒自身の小さい黒い手に直した。
- 正本は `mac/HyperCapsLockApp/Resources/icon_master_1024.png`。全サイズは `mac/HyperCapsLockApp/Resources/AppIcon.iconset/` に生成済み。`scripts/generate_icon.swift` はマスターがあればそれを使い、無い場合だけ旧デザイン（⇪）を描く。
