# macOS

## ネイティブアプリ

1. アプリを開き、使うキーを選ぶ。CapsLock を選んだら、対象キーボードと予約する F19 または F20 を確認する。JIS の「英数」だけを選ぶと、CapsLock の設定を維持できる。短押しは Esc になり、英数キー本来の入力切替は置き換わる。
2. アクセシビリティを許可し、アプリに戻って「有効にして試す」。設定だけ見たいときは「有効にせず設定を開く」。
3. ガイドを前面にして選んだキーを短く押す。アプリが Esc を受け取れたら表示が変わる。次の数字ショートカットの試用は任意。
4. 停止や終了はメニューバーから行う。ロックやスリープでも停止する。再起動後は設定を確認して有効にする。

### すでにキーを割り当てている場合

- **CapsLock が競合する**場合は、表示された割り当てを残したまま別のキーボードや「英数」を選べる。自動確認は macOS の修飾キー設定と読み取れる HID マッピングが対象。Karabiner、Raycast、キーボード本体での割り当ては、それぞれの設定を確認する。
- **F19／F20 を使っている**場合は、使っていない方を予約する。予約中はそのキーを CapsLock 経由の入力と同じように扱う。F18 と予約していない方のキーは通常どおり使える。両方使う場合は英数または停止を選ぶ。
- **既存の Hyper ショートカットを使う**場合は、競合する機能を設定でオフにする。「未割り当てキーを他アプリへ渡す」をオンにすると、未割り当ての組み合わせを Command＋Control＋Option＋Shift 付きで送る。有効なアプリ内割り当てが先に処理され、ピリオドは遮断される。
- **Cursor／VS Code で独自のショートカットを使う**場合は、C と T を個別にオフにできる。C は Cursor が前面で Command＋L、ほかのアプリが前面なら 1 番のアプリへ移動する。T は Cursor または VS Code が前面で Command＋J を送る。
- **復元に失敗した**場合は、メニューや設定画面で「復元を再試行」する。外部ツールで割り当てを変更する場合は、先にアプリを停止する。macOS のキー割り当てはキーボードごとに配列単位で更新するため、別ツールがまったく同じタイミングで書き込んだ変更までは保護できない。
- **旧版の CapsLock → F18 が残っている**場合は、旧版が変更したキーボードを特定できないため、その状態を案内する。元の設定ツールで対象の割り当てを確認するか、再起動後に再確認する。

## 代替: Karabiner-Elements

ネイティブアプリではなく Karabiner-Elements を使う場合だけ、次の手順を使う。Raycast の Hyper Key はオンにしない。公式の説明では、Karabiner などが同じキーを先に取ると Hyper Key は効かない。

https://manual.raycast.com/hyper-key

割り当て表は [割り当て表](../docs/keymap.md)。確認の手順は [確認の手順](../docs/TESTING.md)。

Mac と Windows の実機では、まだ押して確認していない。

## 1. Karabiner-Elements を入れる

```bash
brew install --cask karabiner-elements
```

または https://karabiner-elements.pqrs.org/ から入れる。
初回に「入力監視」と「ドライバ拡張」の許可を求められる。システム設定で許可する。

## 2. ファイルを置いてから、画面で有効にする

これはどちらか一方ではない。公式のファイルの場所にコピーし、そのあと設定画面でルールを「Enable」する。

https://karabiner-elements.pqrs.org/docs/json/location/

リポジトリのフォルダで:

```bash
mkdir -p ~/.config/karabiner/assets/complex_modifications
cp mac/karabiner/hyper-capslock.json ~/.config/karabiner/assets/complex_modifications/
```

Karabiner-Elements の設定を開き、「Complex Modifications」→「Add predefined rule」を開く。
画面の一覧では「Hyper CapsLock — AI開発のコックピット」と表示される。その中から、次の2つだけを「Enable」する。

1. `1. コア`
2. `2. 安全`

`3` 以降は、次の確認が終わるまで「Enable」しない。`5. 第2弾`、`6. 任意・JIS`、`7. 任意` は、自分で足すときまで「Enable」しない。

## 3. 最初の成功

Karabiner-EventViewer を開く。

1. `CapsLock` をすぐ離す。`escape` が出る。大文字固定にはならない。
2. `CapsLock` を1秒押したままにする。`left_shift`、`left_command`、`left_control`、`left_option` の4つが同時に押されたままになる。`left_command` だけ、にはならない。

> [!WARNING]
> macOS では、割り当てるまで Q、W、H を押さない。`Command+Q` は終了、`Command+W` は閉じる、`Command+H` は隠す、という動作をアプリが持つことがある。ほかの修飾が付いていてもそうなるかは未確認。

200ミリ秒より長く押してから離すと、`Esc` にはならない。これは、すぐ離す操作と長押しの境界で、200という数字はこちらの選択。

ここまで期待どおりなら、ルール `3. スターター` と `4. スターター` を「Enable」する。
ルール `4. スターター` のブラウザとターミナルは例なので、JSON の `/usr/bin/open -a` のアプリ名を自分の環境に変えてから、ファイルをコピーし直す。変えたあとは、一度ルールを外して、もう一度「Enable」する。外さずに反映されるかは未確認。

アプリ名が違うと、macOS がエラーを出す。

## 4. あとから1個足す

- 矢印などはルール `5. 第2弾`。1個だけ欲しいときは、そのルールの中の、いらないキーの定義を消してから「Enable」する。JSON に手順のコメントは無い。ルール `7. 任意` を有効にしたままルール `5. 第2弾` も有効にすると、H の扱いが重なる。両方有効なときにどちらが勝つかは未確認なので、第2弾を入れるときはルール `7. 任意` を外す。
- JIS で英数キーが `japanese_eisuu` として出るときだけ、ルール `6. 任意・JIS` を「Enable」する。EventViewer で、押したキーが `caps_lock` か `japanese_eisuu` かを見てから決める。両方「Enable」すると、両方のキーが Hyper になる。
- ウィンドウの左半分と右半分は、最初に入れるキーには含めていない。[Raycast で足す](raycast/README.md)。足すまでは Q と W を押さない。終了が怖いあいだは、ルール `7. 任意` を「Enable」すると Q、W、H を捨てる。そのあいだは Raycast からそのキーは見えない。

## 5. 外し方

1. 「Complex Modifications」の一覧で、入れたルールを外す。
2. コピーしたファイルを消す。

```bash
rm ~/.config/karabiner/assets/complex_modifications/hyper-capslock.json
```

ルールを外すと、`CapsLock` は macOS の元の動作に戻る。
Karabiner-Elements 自体を終了すると、ほかの Karabiner のルールも止まる。Hyper だけをやめるときは、アプリは終了せず、ルールだけを外す。

## うまくいかないとき

- 大文字固定になる: ルール `1. コア` が「Enable」されていない。
- 長押しで Command しか点かない: 古い設定が残っている。この JSON は、4つの修飾を別々のイベントにしていない。EventViewer で4つ同時かを見る。
- チャットが開かない: Cursor の bundle id が違う。EventViewer の Frontmost Application に出る名前を、ルール `3. スターター` の `bundle_identifiers` に入れる。今の値 `com.todesktop.230313mzl4w4u92` は、Cursor のフォーラムで開発元が「変えない」と書いたもの。https://forum.cursor.com/t/cursor-bundle-identifier/779
- 管理者やパスワード欄で効かないことがある。Raycast の Hyper Key とは別問題で、こちらは未確認。
