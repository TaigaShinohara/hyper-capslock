# AGENT_GUIDE — ハイパーCapsLock

AI エージェント向けの使い方メモ。このファイルが、このツールを機械から使うときの正本である。

## アプリの目的（1行）

CapsLock を単押し=Esc／長押し=Hyper に変え、AIチャット⇄エディタ⇄プレビューの往復を速くするキー配置一式。

## 到達レベル

- レベル: **L2（操作可能）** / 読み取り: 可 / 操作: 可（install/uninstall） / 検証: `verify` あり（L3の土台。実機のキー効き確認は人間専用のため L3 到達とは宣言しない）
- スキーマ版数: 1 / アプリ版数: 0.2.0
- 目録: `docs/agent-manifest.json` / 操作カタログ: `docs/AGENT_OPERATIONS.md` / 監査: `docs/AGENT_AUDIT.md`

## コマンド一覧

入口: `python3 cli/hypercapslock.py <command>`（Python 3.10+、標準ライブラリのみ）
共通フラグ: `--json` `--dry-run` `--yes` `--idempotency-key <key>` `--timeout <sec>`（timeout は受理のみ＝同梱処理は即時完了。未対応とは扱わない旨をここに明示）

| コマンド | 種別 | 例 |
|---|---|---|
| `status --json` | 読み取り | 状態・版数・導入状態 |
| `list [--phase starter] --json` | 読み取り | 割り当て一覧（安定ID） |
| `get binding:hyper-c --json` | 読み取り | 1件詳細。無いIDは終了コード4 |
| `history --json` | 読み取り | install/uninstall/verify の履歴 |
| `doctor [--platform mac] --json` | 読み取り | 未導入・不足の一覧 |
| `verify --json` | 検証 | 設定整合性。合格/不合格と理由 |
| `export --json` | 読み取り | ファイル目録＋SHA-256 |
| `install --platform mac\|windows [--dry-run] [--idempotency-key k]` | 書き込み | 設定ファイルを導入先へコピー |
| `uninstall --platform … --yes` | 書き込み（破壊的） | 導入済みコピーを削除。`--yes` なしは実行しない |

導入先は環境変数 `HYPERCAPSLOCK_HOME` で差し替え可能（テスト用。未指定時はホームディレクトリ）。

## 典型フロー

### 1. 状態を確認してから使う
```
python3 cli/hypercapslock.py status --json
python3 cli/hypercapslock.py list --phase starter --json
python3 cli/hypercapslock.py doctor --platform mac --json
```
### 2. 変更する（必ずドライラン first）
```
python3 cli/hypercapslock.py install --platform mac --dry-run --json
python3 cli/hypercapslock.py install --platform mac --idempotency-key 2026-11-24-mac-1 --json
python3 cli/hypercapslock.py verify --json
```
### 3. 失敗したときに調べる
```
python3 cli/hypercapslock.py history --json
python3 cli/hypercapslock.py doctor --json
```

## 入出力スキーマ

- 成功: `{"ok": true, "data": ..., "meta": {"schema_version": 1, "request_id": "..."}}`
- 失敗: `{"ok": false, "error": {"code": "...", "message": "...", "retryable": false}}`
- 終了コード: 0 成功 / 1 入力誤り / 2 アプリ側失敗 / 3 権限不足 / 4 対象なし
- ID: `binding:<key>` 形式で安定。再読み込みで変わらない。秘密情報は出力しない（そもそも保持しない）。

## エラーコード表

| コード | 意味 | 再試行 | 対処 |
|---|---|---|---|
| `not_found` | 対象が無い (4) | 不可 | `list` でID確認 |
| `invalid_input` | 入力誤り (1) | 不可 | 引数を直す |
| `confirmation_required` | `--yes` なしの破壊的操作 (1) | 不可 | `--dry-run` で確認後に `--yes` |
| `config_missing` | 設定ファイル欠落 (2) | 不可 | リポジトリから復元 |
| `verify_failed` | 検証不合格 (2) | 不可 | checks の理由を直す |

## MCP / SDK

- **MCP: 未対応。CLI を使うこと。** L2/L3 が安定した後の最終段階で、CLIコマンドを同名ツール化する設計のみ将来候補（今回は作らない）。
- **SDK: 未対応。JSON スキーマと CLI を使うこと。** 需要（他アプリからの芯の再利用等）が出たら主言語1つで別作業とする。

## 人間専用操作

| 操作 | 理由 | 人間が行う手順 |
|---|---|---|
| OS権限の許可 (os-permission-grant) | OSの権限ダイアログ（Karabinerのドライバ拡張・入力監視、WindowsのUAC/ドライバ）は本人操作が必須 (C) | mac/README.md・windows/README.md の手順でシステム設定から許可 |
| 物理キーの実押し確認 (physical-key-test) | 物理キー入力と体感（効き・押し心地）の判定は人間のみ (C) | 導入後、実際に CapsLock を単押し/長押しして確認 |
| Raycastホットキー登録 | 登録UIの Record Hotkey は画面操作が前提 (B: 案内まで機械) | mac/raycast/README.md の割当表どおりに記録 |

## やってはいけない操作

- 実ホームへ向けた `uninstall` を `--dry-run` なし・確認なしで実行しない。
- `HYPERCAPSLOCK_HOME` を本番ホームに向けてテストを流さない（テストは temp を使う）。
- プラットフォーム設定ファイル（Karabiner/Kanata/AHK）を bindings.json と無関係に書き換えない。割り当ての正本は `config/bindings.json`。
