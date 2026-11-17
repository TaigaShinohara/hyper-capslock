# ハイパーCapsLock

> **CapsLockを、AI開発のコックピットにする**

CapsLock を捨てるな。最強のキーに変えろ。

単押しは `Esc`、長押しは `Hyper`（`Ctrl + Alt + Shift + Cmd / Win` 同時押し）。
左手小指の真下に、既存ショートカットと一切衝突しない「自分専用のボタン」が生まれます。

バイブコーディング — コードを手書きするのではなく、AI に指示して・確認して・直させる開発 — に特化したキー配置です。
速くなるのはタイピングではなく、**AIチャット ⇄ エディタ ⇄ プレビュー** の往復です。

## コア仕様

| 操作 | 動作 |
|---|---|
| CapsLock をポンッと押す | `Esc` — AI生成を止める / ダイアログを閉じる / ポップアップを抜ける |
| CapsLock を長押し | `Hyper` — 下の表すべての入口 |

## スターター8点（まずこれだけ）

| キー | 動作 | 狙い |
|---|---|---|
| `Hyper + C` | AIチャット欄へジャンプ | 「こう直して」がすぐ打てる |
| `Hyper + Enter` | AIへ送信 (`Cmd+Enter` 相当) | 送信ボタンを探さない |
| `Hyper + 1 / 2 / 3` | 固定席切替: 1=エディタ 2=ブラウザ 3=ターミナル | 生成 → 即確認 → 即修正 |
| `Hyper + Q / W` | ウィンドウを左半分 / 右半分 | 左エディタ・右プレビューを一瞬で |
| `Hyper + T` | ターミナル開閉 | エラー確認・ビルドをすぐ見る |
| `Hyper + Space` | ランチャー (Raycast / Spotlight / Flow Launcher) | 何でも召喚 |
| `Hyper + V` | クリップボード履歴 | よく使うプロンプトの使い回し |

## 第2弾（1週間後に足す）

| キー | 動作 |
|---|---|
| `Hyper + H / J / K / L` | `← / ↓ / ↑ / →` — ホームポジションでカーソル移動 |
| `Hyper + A / E` | 行頭 / 行末 |
| `Hyper + B / F` | 単語ごと移動 |
| `Hyper + R` | プレビュー再読み込み / 再実行 |
| `Hyper + S` | スクリーンショット → そのまま AI に渡す |

詳しい割り当て表は [docs/keymap.md](docs/keymap.md) を参照。

## セットアップ

### macOS

Karabiner-Elements を使います。手順は [mac/README.md](mac/README.md)。

- コア設定: [`mac/karabiner/hyper-capslock.json`](mac/karabiner/hyper-capslock.json)
  - CapsLock の Tap=Esc / Hold=Hyper と、Hyper+HJKL などの移動レイヤーを含みます
  - アプリ切替・ウィンドウ配置は Raycast 側に Hyper ショートカットとして割り当てます（[mac/raycast/README.md](mac/raycast/README.md)）

### Windows

Kanata（推奨）または AutoHotkey v2 を使います。手順は [windows/README.md](windows/README.md)。

- Kanata: [`windows/kanata/hyper-capslock.kbd`](windows/kanata/hyper-capslock.kbd) — Tap=Esc / Hold=Hyper のコア
- AutoHotkey: [`windows/autohotkey/HyperCapsLock.ahk`](windows/autohotkey/HyperCapsLock.ahk) — コア＋バイブコーディング用ホットキー一式

## 設計原則

1. **最初から全部入れない。** スターター8点だけ。指が覚えたら第2弾を足す。
2. **Hyper は衝突しない。** 通常のアプリは Hyper を使わないので、既存ショートカットを壊さない。
3. **割り当ては自分の作業に寄せる。** エディタが Cursor ではなく VS Code なら、`Hyper + 1` の先を変えるだけ。

## ライセンス

MIT
