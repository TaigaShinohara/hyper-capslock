# macOS

Karabiner-Elements を使う。Raycast の Hyper Key はオンにしない。公式の説明では、Karabiner などが同じキーを先に取ると Hyper Key は効かない。

https://manual.raycast.com/hyper-key

割り当て表は [docs/keymap.md](../docs/keymap.md)。確認手順は [docs/TESTING.md](../docs/TESTING.md)。実機ではまだ確認していない。

## 1. Karabiner-Elements を入れる

```bash
brew install --cask karabiner-elements
```

または https://karabiner-elements.pqrs.org/ から入れる。
初回に「入力監視」と「ドライバ拡張」の許可を求められる。システム設定で許可する。

## 2. ファイルを置いてから、画面で有効にする

これはどちらか一方ではない。公式のファイルの場所にコピーし、そのあと設定画面でルールを有効にする。

https://karabiner-elements.pqrs.org/docs/json/location/

リポジトリのフォルダで:

```bash
mkdir -p ~/.config/karabiner/assets/complex_modifications
cp mac/karabiner/hyper-capslock.json ~/.config/karabiner/assets/complex_modifications/
```

Karabiner-Elements の設定を開き、Complex Modifications → Add predefined rule を開く。
「Hyper CapsLock」の中から、次の2つだけを Enable する。

1. `1. コア`
2. `2. 安全`

`3` 以降は、次の確認が終わるまで Enable しない。`5. 第2弾`、`6. 任意・JIS`、`7. 任意` は、自分で足すときまで Enable しない。

## 3. 最初の成功

Karabiner-EventViewer を開く。

1. CapsLock をすぐ離す。`escape` が出る。大文字のままにならない。
2. CapsLock を1秒押したままにする。`left_shift`、`left_command`、`left_control`、`left_option` の4つが同時に押されたままになる。Command だけ、にはならない。
3. この確認では Q、W、H を押さない。Command と一緒に届くと、アプリが終了したり、ウィンドウが閉じたり、隠れたりすることがある。ほかの修飾が付いていてもそうなるかは未確認。

200ミリ秒より長く押してから離すと、Esc にはならない。これは単押しと長押しの境界で、200という数字はこちらの選択。

ここまで期待どおりなら、ルール `3` と `4` を Enable する。
ルール `4` のブラウザとターミナルは例なので、JSON の `open -a` の名前を自分のアプリに変えてから、ファイルをコピーし直す。変えたあとは、一度ルールを外して、もう一度 Enable する。外さずに反映されるかは未確認。

アプリ名が違うと、macOS がエラーを出す。

## 4. あとから1個足す

- 矢印などはルール `5. 第2弾`。1個だけ欲しいときは、JSON からいらないキーを消してから Enable する。ルール `7` を有効にしたままルール `5` も有効にすると、H の扱いが重なる。両方有効なときにどちらが勝つかは未確認なので、第2弾を入れるときはルール `7` を外す。
- JIS で英数キーが `japanese_eisuu` として出るときだけ、ルール `6` を Enable する。EventViewer で、押したキーが `caps_lock` か `japanese_eisuu` かを見てから決める。両方 Enable すると、両方のキーが Hyper になる。
- ウィンドウの左半分と右半分は、macOS の最初の一式には入れていない。Raycast で足す場合は [raycast/README.md](raycast/README.md)。足すまでは Q と W を押さない。終了が怖いあいだは、ルール `7` を Enable すると Q / W / H を捨てる。そのあいだは Raycast からそのキーは見えない。

## 5. 外し方

1. Complex Modifications の一覧で、入れたルールを外す。
2. コピーしたファイルを消す。

```bash
rm ~/.config/karabiner/assets/complex_modifications/hyper-capslock.json
```

ルールを外すと、CapsLock は macOS の元の動作に戻る。
Karabiner-Elements 自体を終了すると、ほかの Karabiner のルールも止まる。Hyper だけをやめるときは、アプリは終了せず、ルールだけを外す。

## うまくいかないとき

- 大文字のままになる: ルール `1` が Enable されていない。
- 長押しで Command しか点かない: 古い設定が残っている。この JSON は、4つの修飾を別々のイベントにしていない。EventViewer で4つ同時かを見る。
- チャットが開かない: Cursor の bundle id が違う。EventViewer の Frontmost Application に出る名前を、ルール `3` の `bundle_identifiers` に入れる。今の値 `com.todesktop.230313mzl4w4u92` は、Cursor のフォーラムで開発元が「変えない」と書いたもの。https://forum.cursor.com/t/cursor-bundle-identifier/779
- 管理者やパスワード欄で効かないことがある。Raycast の Hyper Key とは別問題で、こちらは未確認。
