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
| `CapsLock` を押したまま別のキー | [割り当て表](docs/keymap.md) にあるキーは、その動作になる。macOS で表に無いキーは、4つの修飾と一緒に届く。 |

生成を止めるキー、変更の全部承認、変更の全部却下は、最初に入れるキーには含めていない。
チャットへ送るのは、チャット欄にいるときの普通の `Enter`。

割り当て表の正本は [割り当て表](docs/keymap.md)。ほかの文書はそこへリンクする。

## 入れ方（macOS）

macOS は、まずネイティブアプリを使う。最初に入れるキーはアプリ内で確認できる。

1. [macOSアプリを入れる手順](mac/README.md) でアプリを起動する。
2. 画面の手順で、アクセシビリティ権限を許可する。
3. `CapsLock` をすぐ離して `Esc` になることを確認する。
4. 確認が成功してから、往復ショートカットを有効にする。

ネイティブアプリを使わず、外部ツールで動作させる方法は代替導線とする。

- Karabiner-Elements を使う場合は [macOSの代替手順](mac/README.md) の「代替: Karabiner-Elements」へ進む。
- Windows は [Windowsの代替手順](windows/README.md)。Kanata か AutoHotkey のどちらか一方だけを使う。

最初の成功は、`CapsLock` をすぐ離して `Esc` になること。失敗したまま次へ進まない。

## 壊さないために

Hyper は、どのアプリともぶつからない、とは言えない。

- Windows の `Ctrl+Alt+Shift+Win` は Office キーとして予約されている。この設定は、その4つをまとめて送らない。
- Cursor の `Command+L` / `Ctrl+L` はサイドパネルの開閉で、開いていると閉じることがある。
- 変更があるときの `Command+Enter` は全部承認、`Command+Shift+Backspace` は全部却下でもある。どちらも送らない。

判断の記録は [判断の記録](docs/decisions.md)。


## AIエージェントから使う（L2）

CLI が共有芯を通して、設定ファイルの状態取得・導入・検証を実行できる。割り当ての正本は上の割り当て表（docs/keymap.md）で、機械可読版は config/bindings.json。
正本ガイドは [docs/AGENT_GUIDE.md](docs/AGENT_GUIDE.md)、目録は [docs/agent-manifest.json](docs/agent-manifest.json)、操作カタログは [docs/AGENT_OPERATIONS.md](docs/AGENT_OPERATIONS.md)。

```bash
python3 cli/hypercapslock.py status --json
python3 cli/hypercapslock.py install --platform mac --dry-run --json
python3 cli/hypercapslock.py verify --json
```

ライセンスは MIT。
