# macOS セットアップ

## 1. Karabiner-Elements を入れる

```bash
brew install --cask karabiner-elements
```

または https://karabiner-elements.pqrs.org/ からインストール。
初回起動で「入力監視」と「ドライバ拡張」の許可を求められるので、システム設定で許可する。

## 2. ハイパーCapsLock を取り込む

方法A（ファイルコピー）:

```bash
mkdir -p ~/.config/karabiner/assets/complex_modifications
cp mac/karabiner/hyper-capslock.json ~/.config/karabiner/assets/complex_modifications/
```

方法B（Karabiner の画面から）: Karabiner-Elements を開き、
`Complex Modifications` → `Add predefined rule` → `Hyper CapsLock` をすべて Enable。

これで即座に効くもの:

- CapsLock 単押し = Esc
- CapsLock 長押し = Hyper
- Hyper + H/J/K/L = 矢印キー、Hyper + A/E = 行頭/行末、Hyper + B/F = 単語移動
- Hyper + C = AIチャット (Cmd+Shift+L)、Hyper + Enter = Cmd+Enter、Hyper + T = ターミナル (Ctrl+`)

## 3. アプリ切替とウィンドウ配置は Raycast で

Hyper+1/2/3、Q/W、Space、V は Raycast 側の割り当てです。
手順は [raycast/README.md](raycast/README.md)。

## うまくいかないとき

- CapsLock ランプが点く / 大文字になる → Karabiner のルールが有効になっていない。`Complex Modifications` で Enable 済みか確認。
- Esc が出ない → 単押しの判定は 200ms 以内。ゆっくり押すと Hyper 扱いになる（仕様）。
