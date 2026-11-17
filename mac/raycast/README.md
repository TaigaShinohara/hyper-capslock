# Raycast は任意（macOS）

ウィンドウを左右に分けるときだけ使う。チャット、パネル、アプリの切り替えは Karabiner 側で行う。
Raycast の Hyper Key はオンにしない。オンにすると `CapsLock` の扱いが Karabiner と重なる。公式のトラブルシューティングでも、Karabiner が同じキーを取ると Hyper Key は効かない、とある。

https://manual.raycast.com/hyper-key

`Hyper+Space` を Raycast に登録しても、Spotlight（`Command+Space`）はそのまま残る。置き換えではない。

Mac と Windows の実機では、まだ押して確認していない。

## 登録してよいキー

Karabiner のルール `1. コア` が有効で、EventViewer の確認が終わってから登録する。
ルール `7. 任意`（Q、W、H を捨てる）が有効だと、Raycast からは見えない。登録する前にルール `7. 任意` は外す。

| 操作 | 登録先 |
| --- | --- |
| `Hyper+Q` | 「Window Management」→「Left Half」 |
| `Hyper+W` | 「Window Management」→「Right Half」 |

登録は、「Raycast Settings」で対象を選び、「Record Hotkey」のあいだに `CapsLock` を押したまま Q または W を押す。

> [!WARNING]
> macOS では、割り当てるまで Q、W、H を押さない。`Command+Q` は終了、`Command+W` は閉じる、`Command+H` は隠す、という動作をアプリが持つことがある。ほかの修飾が付いていてもそうなるかは未確認。

クリップボード履歴やランチャーを足すときも、1個ずつ、同じ手順で足す。最初に入れるキーには含めていない。
