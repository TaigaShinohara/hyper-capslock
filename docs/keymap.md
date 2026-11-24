# 割り当て表

このファイルが割り当て表の正本。確認の手順は [確認の手順](TESTING.md)。
macOS で迷わないため、まずネイティブアプリの権限→Esc確認→往復の順で進める。Karabiner、WindowsのKanata・AutoHotkeyは代替導線。

Mac と Windows の実機では、まだ押して確認していない。

## 往復

`Hyper+1` エディタ → `Hyper+C` チャット → `Enter` で送る → `Hyper+2` プレビュー（または `Hyper+T` パネル）→ `Hyper+1` エディタ

`Hyper+C` と `Hyper+T` は開閉である。開いていると閉じる。

## 最初に入れるキー

| 操作 | 役割 | macOS | Windows（Kanata・推奨） | Windows（AutoHotkey） |
| --- | --- | --- | --- | --- |
| `CapsLock` をすぐ離す | 入力欄から出る。生成は止まらない | `Esc` | `Esc` | `Esc` |
| `CapsLock` を押したまま | 次のキーの意味を変える | `Command+Control+Option+Shift` を押したままにする | 別の意味の一覧に切り替える。4つの修飾は送らない | 押している印だけを付ける。4つの修飾は送らない |
| `Hyper+C` | チャットを呼ぶ | Cursor が前面なら `Command+L`。違うアプリなら Cursor を前面にするだけで、`Command+L` は送らない | 常に `Ctrl+L`。前面のアプリに届く | Cursor が前面なら `Ctrl+L`。違うときはタスクバーの1番（`Win+1`） |
| `Hyper+1` | エディタを前面に | `/usr/bin/open -a Cursor` | `Win+1` | `Win+1` |
| `Hyper+2` | プレビューを前面に | `/usr/bin/open -a "Google Chrome"`（例。名前は変える） | `Win+2` | `Win+2` |
| `Hyper+3` | ターミナルアプリを前面に | `/usr/bin/open -a Terminal`（例。名前は変える） | `Win+3` | `Win+3` |
| `Hyper+T` | エディタ下のパネルを開閉 | Cursor か VS Code が前面のときだけ `Command+J`。それ以外は何もしない | 常に `Ctrl+J`。前面のアプリに届く | Cursor か VS Code が前面のときだけ `Ctrl+J` |
| `Hyper+Q` | ウィンドウを左半分 | 最初は割り当てない。押さない | `Win+←` | `Win+←` |
| `Hyper+W` | ウィンドウを右半分 | 最初は割り当てない。押さない | `Win+→` | `Win+→` |

Windows の `Hyper+1` / `Hyper+2` / `Hyper+3` は、タスクバーの左からその位置にピンしたアプリ。Cursor を1番、プレビュー用のブラウザを2番、ターミナルを3番にピンする。

> [!WARNING]
> macOS では、割り当てるまで Q、W、H を押さない。`Command+Q` は終了、`Command+W` は閉じる、`Command+H` は隠す、という動作をアプリが持つことがある。ほかの修飾が付いていてもそうなるかは未確認。

## 第2弾と、入れないキー

| 操作 | 扱い |
| --- | --- |
| `Hyper+Enter` | 送らない。Cursor では、変更の提案があるときの `Command+Enter` は全部承認になる。送信は普通の `Enter`。 |
| `Hyper+S` | 無い。スクリーンショットを AI に渡す機能は実装していない。 |
| `Hyper+R` | 無い。 |
| `Hyper+Space` | 無い。ランチャーが入っていないときに別のメニューが開くのを避ける。 |
| `Hyper+V` | 無い。あとから1個足すときの候補（クリップボード履歴）。 |
| `Hyper+H` / `J` / `K` / `L` | 第2弾。矢印。最初は無効。 |
| `Hyper+A` / `E` | 第2弾。行頭 / 行末。最初は無効。 |
| `Hyper+B` / `F` | 第2弾。単語ごと。最初は無効。 |
| `Hyper+ピリオド` | macOS の安全ルールを有効にすると、何も送らない。 |

第2弾の移動は、押しながら選択範囲を広げられない。macOS の Hyper は Shift を含む。Windows は Shift を付けて送らない。

## OS で違うところ

macOS の長押しは、`Command+Control+Option+Shift` を本当に押したままにする。割り当てていないキーは、その4つと一緒にアプリへ届く。

Windows の長押しは修飾キーを押さない。割り当てていないキーは、普通の文字として届く。Office キーにはならない。

Kanata は前面のアプリを見分けられない。`Ctrl+L` と `Ctrl+J` は、今開いているアプリに届く。チャットとパネルは、先に `Hyper+1` で Cursor を前面にしてから押す。右 Alt だけは、長押しの判定の対象外。

AutoHotkey は Cursor が前面かどうかを見てから送る。Kanata と AutoHotkey は同時に動かさない。

## 公式の資料との対応

ここに書いた「公式ではこうなっている」は、次のページの記述。今の Cursor の版で同じキーが同じ動作かは、実機の確認がまだ。

<details>
<summary>出典を開く</summary>

- Cursor のキーボードショートカット: https://cursor.com/docs/reference/keyboard-shortcuts
  - `Escape` は Unfocus field（入力欄からフォーカスを外す）。
  - 生成の取り消しは `Command+Shift+Backspace`。変更の提案があるときは、同じキーが全部却下。
  - `Command+L` または `Command+K` はサイドパネルの開閉。選択中は、同じページに「新しいチャットへ選択を追加」とも書いてある。
  - `Command+Shift+L` は選択をチャットに追加。これは送らない。
  - 変更の提案があるときの `Command+Enter` は全部承認。これは送らない。
  - チャット欄で打っているときの `Command+Enter` は強制送信。普通の `Enter` はキューへ入れる。
  - 同じページに、Cursor のキーは VS Code のキー割り当てを基準にし、Keyboard Shortcuts で変えられる、とある。
- VS Code の既定キー: https://code.visualstudio.com/docs/reference/default-keybindings
  - `Command+Shift+L` / `Ctrl+Shift+L` は、選択中の文字の出現をすべて選択する。これは送らない。
  - `Command+L` / `Ctrl+L` は現在の行を選択する。チャットを開くキーではない。
  - `Command+Enter` / `Ctrl+Enter` は下に行を挿入する。
- VS Code のパネル: https://code.visualstudio.com/docs/editing/getting-started/tips-and-tricks
  - Toggle Panel は `Command+J` / `Ctrl+J`。開閉なので、開いていると閉じる。
- VS Code のターミナル: https://code.visualstudio.com/docs/terminal/basics/
  - 既定の開閉は `Control+バッククォート`。JIS ではこの文字の位置が違うので、`Hyper+T` はバッククォートを送らない。
- Windows のタスクバー: https://support.microsoft.com/en-us/accessibility/windows/keyboard-shortcuts-in-windows
  - `Win+数字` は、その位置にピンしたアプリを開く。すでに起動していれば、そのアプリに切り替える。
- ウィンドウを半分に: https://learn.microsoft.com/en-us/windows/configuration/keyboard-filter/predefined-key-combinations
  - `Win+←` は左半分、`Win+→` は右半分。
- Office キー: https://support.microsoft.com/en-us/office/using-the-office-key
  - Office キー単体で Office アプリ（無ければ Office.com）。`+W` は Word、`+T` は Teams、`+L` は LinkedIn。ほかに `P` / `X` / `O` / `D` / `N` / `Y`。
  - `Ctrl+Alt+Shift+Win` が Office キーと同じ、という文は Microsoft Q&A の回答にある。製品ページの本文が4つのキーをそのまま列挙しているわけではない。https://learn.microsoft.com/en-us/answers/questions/4331341/disabling-the-office-hotkey-in-windows-10
  - この設定はその4つを送らない。
- macOS の診断収集: https://podcasters.apple.com/assets/Mac-sysdiagnose-logging-instructions.pdf
  - Finder が前面のとき、`Command+Option+Shift+Control+ピリオド` で sysdiagnose が始まる、と Apple の手順にある。macOS の安全ルールは、そのピリオドを捨てる。

</details>
