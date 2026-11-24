# Windows

ネイティブアプリは macOS 専用。この内容は Windows 用の代替導線です。

Kanata か AutoHotkey v2 の、どちらか一方だけを使う。同時には使わない。
両方とも、`CapsLock` を押した瞬間に `Ctrl+Alt+Shift+Win` を送らない。離しただけでも送らない。

推奨は Kanata。理由は、最初に入れるキー（チャット、アプリの切り替え、左右の半分、パネル）が設定ファイルに入っていて、Office キーの組み合わせを出さないこと。

割り当て表は [割り当て表](../docs/keymap.md)。確認の手順は [確認の手順](../docs/TESTING.md)。

Mac と Windows の実機では、まだ押して確認していない。

Office キーをレジストリで止める方法は任意で、通常は要らない。[Office キーを自分で止める](../docs/windows-office-key.md)

## 先にやること

タスクバーの左から順にピンする。

1. Cursor
2. プレビューに使うブラウザ
3. ターミナル

`Win+数字` は、その位置のアプリを開く。起動済みならそのアプリに切り替える。

https://support.microsoft.com/en-us/accessibility/windows/keyboard-shortcuts-in-windows

## A. Kanata（推奨）

1. https://github.com/jtroo/kanata/releases を開く。案内は v1.12.0 のリリースノートに合わせている。新しい版では zip の名前が変わることがある。
2. CPU が Intel または AMD なら x64、ARM なら arm64 の Windows 用 zip を開く。
3. 中の実行ファイルから、名前に `winIOv2` と `gui` があり、`wintercept` と `cmd_allowed` が無いものを選ぶ。
   - winIOv2 は LLHOOK と SendInput を使う。ドライバは要らない。
   - wintercept は Interception ドライバを使う。リリースノートは、再起動までキーボードとマウスが使えなくなる既知の不具合に注意するよう書いている。この手順では入れない。
   - `cmd_allowed` は外部コマンドを実行できる版。この設定ファイルは外部コマンドを使わない。
4. 選んだ exe と、このフォルダの `hyper-capslock.kbd` を同じ場所に置いても、置かなくてもよい。設定ファイルはフルパスで指定する。
5. コマンドプロンプトで、先に文法だけ見る。

v1.12.0 の Windows x64 の zip では、選ぶファイルの名前は `kanata_windows_gui_winIOv2_x64.exe`。arm64 の zip は、中の名前を見て同じ条件（`gui` と `winIOv2` があり、`wintercept` と `cmd_allowed` が無い）で選ぶ。arm64 のファイル名はこの環境では開いていない。

```bat
kanata_windows_gui_winIOv2_x64.exe --cfg C:\path\to\hyper-capslock\windows\kanata\hyper-capslock.kbd --check
```

`--check` は設定を読んで終了する、と公式の設定ガイドにある。

https://github.com/jtroo/kanata/blob/v1.12.0/docs/config.adoc

6. エラーが無ければ、`--check` を外して起動する。公式の説明では、起動したウィンドウは開いたままにする。トレイ版（gui）ならウィンドウではなくトレイに残る。
7. 自動で起動したいときは、自分でショートカットを作り、`Win+R` に `shell:startup` と入力して開くフォルダへ置く。レジストリは書き換えない。

### 最初の成功

1. Cursor のチャット欄で `CapsLock` をすぐ離す。入力欄からフォーカスが外れる。大文字固定にはならない。
2. `CapsLock` を1秒押して離す。Office もスタートメニューも開かない。
3. `Hyper+1` で Cursor が前面に来る。そのあと `Hyper+C` でチャット欄が開閉する。

> [!WARNING]
> ブラウザが前面のときに `Hyper+C` を押すと、`Ctrl+L` がそのブラウザに届く。先に `Hyper+1` を押す。

第2弾（`Hyper+H` / `J` / `K` / `L` と `Hyper+A` / `E` / `B` / `F`）は、`hyper-capslock.kbd` の `XX` を、ファイル内のコメントの動作に1個ずつ置き換えてから、Kanata を起動し直す。

### 外し方

トレイの終了、または起動したウィンドウを閉じる。スタートアップに置いたショートカットがあれば消す。`CapsLock` は元に戻る。

## B. AutoHotkey v2

Kanata を終了してから使う。スクリプトは、知っている Kanata のプロセスが残っていると、メッセージを出して終了する。exe の名前を変えていると、この検出はできない。そのときは自分で片方を終了する。

1. https://www.autohotkey.com/ から AutoHotkey v2 を入れる。
2. `windows/autohotkey/HyperCapsLock.ahk` をダブルクリックする。
3. スタートアップに入れる場合は、ショートカットを `shell:startup` のフォルダへ置く。

すぐ離す操作と長押しの境界は 200ミリ秒。これはこちらの選択で、Kanata と macOS の数字に合わせた。
押したまま 60秒を超えると、離した通知を待たずに Hyper を解除する。キーを離した通知が来ない配列で、戻らなくなるのを防ぐため。60秒もこちらの選択。

第2弾は、ファイル先頭の `Phase2 := false` を `true` にし、いらない行をコメントにしてから、スクリプトを読み込み直す。

チャットは、Cursor が前面のときだけ `Ctrl+L` を送る。違うアプリのときはタスクバーの1番を前面にする。
パネルは、Cursor か VS Code が前面のときだけ `Ctrl+J`。

### 外し方

トレイアイコンを右クリックして「Exit」。スタートアップのショートカットがあれば消す。

## JIS 配列

Windows の日本語入力では、`CapsLock` の位置が「英数」になり、`Shift` と一緒に押すと `CapsLock`、というキーボードがある。
AutoHotkey の公式キー一覧は、一部の IME が `CapsLock` を飲み込んで、スクリプトから見えなくする、と書いている。例として「英語キーボードでの日本語入力」が挙がっている。

https://www.autohotkey.com/docs/v2/KeyList.htm

離したときの通知が来ない、という話は利用者の報告であり、このリポジトリでは実機で見ていない。
見る手順は [確認の手順](../docs/TESTING.md) の「Windows・JIS」。見えなかったキーボードでは、この設定を使わない。スキャンコードをレジストリで書き換える手順は置かない。

`Hyper+T` は `Ctrl+J` を送る。バッククォートは送らない。J は US でも JIS でも同じ文字キー。

## うまくいかないとき

- 大文字固定になる: Kanata か AutoHotkey が動いていない。または JIS の入力がキーを飲み込んでいる。上の JIS の確認に進む。
- Office が開く: この設定とは別のツールが `Ctrl+Alt+Shift+Win` を送っている。推奨設定はそれを送らない。ほかのツールを止めるか、任意の手順で Office キーを止める。
- 管理者として開いたウィンドウで効かない: AutoHotkey の公式 FAQ では、昇格していないスクリプトは昇格したウィンドウを操作できない。対処は、スクリプトを「Run with UI access」で起動すること。管理者として起動すると、スクリプトが開くアプリまで管理者になる、と書いてある。https://www.autohotkey.com/docs/v2/FAQ.htm
- Kanata の LLHOOK 版が同じウィンドウで効くかは未確認。リリースノートは、wintercept の方がより多くのアプリで効く、と書いている。ドライバの不具合があるので、効かないウィンドウはマウスで操作する、を先にする。
