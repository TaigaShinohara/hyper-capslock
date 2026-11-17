# Raycast は任意（macOS）

ウィンドウを左右に分けるときだけ使う。チャット、パネル、アプリの切替は Karabiner 側で行う。
Raycast の Hyper Key はオンにしない。オンにすると CapsLock の扱いが Karabiner と重なる。公式のトラブルシューティングでも、Karabiner が同じキーを取ると Hyper Key は効かない、とある。

https://manual.raycast.com/hyper-key

Hyper+Space を Raycast に登録しても、Spotlight（`Command+Space`）はそのまま残る。置き換えではない。

## 登録してよいキー

Karabiner のルール `1` が有効で、EventViewer の確認が終わってから登録する。
ルール `7`（Q / W / H を捨てる）が有効だと、Raycast からは見えない。登録する前にルール `7` は外す。

| キー | 登録先の例 |
|---|---|
| Hyper+Q | Window Management → Left Half |
| Hyper+W | Window Management → Right Half |

登録は、Raycast Settings で対象を選び、Record Hotkey のあいだに CapsLock を押したまま Q または W を押す。

登録が終わるまで、普段の操作で Q と W は押さない。
割り当てが無いあいだは、Command を含むキーとしてアプリに届く。終了や「閉じる」になる可能性がある。ほかの修飾が付いたままでも終了するかは未確認。

クリップボード履歴やランチャーを足すときも、1個ずつ、同じ手順で足す。最初の一式には入っていない。
