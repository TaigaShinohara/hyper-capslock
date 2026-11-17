# ハイパーCapsLock

CapsLock を、AI に指示して開発するときの起点にする。

単押しは `Esc`。長押ししているあいだだけ、次に押すキーの意味が変わる（これを Hyper と呼ぶ）。

速くしたいのはタイピングではなく、**AIチャット ⇄ エディタ ⇄ プレビュー** の往復。

主に使うエディタは Cursor。VS Code は副次。macOS と Windows、US 配列と JIS 配列の両方を対象にする。この説明は、公式の資料と設定ファイルから書いた。

Mac と Windows の実機では、まだ押して確認していない。
押して確かめるときは [確認の手順](docs/TESTING.md)。

## 押したときに起きること

| 操作 | 起きること |
| --- | --- |
| `CapsLock` をすぐ離す | `Esc`。Cursor では入力欄からフォーカスが外れる。生成は止まらない。 |
| `CapsLock` を押したまま別のキー | そのキーだけが、[割り当て表](docs/keymap.md) の動作になる。 |

生成を止めるキー、変更の全部承認、変更の全部却下は、最初に入れるキーには含めていない。
チャットへ送るのは、チャット欄にいるときの普通の `Enter`。

割り当て表の正本は [割り当て表](docs/keymap.md)。ほかの文書はそこへリンクする。

## 入れ方

1個ずつ足す。最初から全部は入れない。

- [macOS の手順](mac/README.md)
- [Windows の手順](windows/README.md)。Kanata か AutoHotkey の、どちらか一方。

最初の成功は、`CapsLock` をすぐ離して `Esc` になること。そこを確認してから、次のキーを足す。

## 壊さないために

Hyper は、どのアプリともぶつからない、とは言えない。

- Windows の `Ctrl+Alt+Shift+Win` は Office キーとして予約されている。この設定は、その4つをまとめて送らない。
- Cursor の `Command+L` / `Ctrl+L` はサイドパネルの開閉で、開いていると閉じることがある。
- 変更があるときの `Command+Enter` は全部承認、`Command+Shift+Backspace` は全部却下でもある。どちらも送らない。

判断の記録は [判断の記録](docs/decisions.md)。

ライセンスは MIT。
