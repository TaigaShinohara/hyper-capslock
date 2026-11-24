# 操作カタログ — ハイパーCapsLock

正本。ここに無い操作を CLI へ足さない。機械経路はすべて共有芯 `cli/hypercapslock_core.py` を通る。

| 操作名 | 対象 | 人間の手順 | 機械の経路 | 入力 | 出力 | 副作用 | 破壊的 | 人間専用か |
|---|---|---|---|---|---|---|---|---|---|
| status | 全体 | READMEを読む | `hypercapslock status` | なし | 版数・設定ファイル有無・導入状態 | なし | いいえ | いいえ |
| list-bindings | 割り当て | keymap.md を読む | `hypercapslock list` | `--phase`任意 | bindings一覧（安定ID付き） | なし | いいえ | いいえ |
| get-binding | 割り当て1件 | 表を探す | `hypercapslock get <id>` | 安定ID | 1件の詳細 | なし | いいえ | いいえ |
| history | 実行履歴 | （従来なし） | `hypercapslock history` | `--limit` | install/uninstall/verify の記録 | なし | いいえ | いいえ |
| doctor | 前提条件 | 手順書とにらめっこ | `hypercapslock doctor` | `--platform` | 不足・未導入の一覧 | なし | いいえ | いいえ |
| verify | 設定一式 | JSONを目視 | `hypercapslock verify` | なし | 合格/不合格と理由 | historyへ記録 | いいえ | いいえ |
| export | 設定一式 | ファイルを集める | `hypercapslock export` | なし | ファイル目録＋ハッシュ | なし | いいえ | いいえ |
| install | プラットフォーム設定 | 対象フォルダへコピー | `hypercapslock install --platform mac\|windows` | platform、dry-run可 | 導入先パス | **ファイル書き込み**（対象dirへコピー）、history記録 | いいえ（上書き時は旧版を上書き） | いいえ（導入自体）。ただし導入後のOS権限許可は人間専用 |
| uninstall | 導入済み設定 | 対象フォルダから消す | `hypercapslock uninstall --platform … --yes` | platform | 削除したパス | **ファイル削除** | **はい**（--yes必須） | いいえ |
| os-permission-grant | OS権限 | システム設定でKarabinerのドライバ拡張・入力監視を許可／WindowsのUAC・ドライバ許可 | なし | — | — | OS設定変更 | いいえ | **はい（C）: OS権限ダイアログは本人の操作が必須** |
| physical-key-test | 実機キー | 実際にCapsLockを押してEsc/Hyperが効くか確かめる | なし | — | — | なし | いいえ | **はい（C）: 物理キー入力と体感の判定は人間のみ** |
| raycast-hotkey-bind | Raycast割当 | Raycast設定でRecord Hotkey | 画面まで案内のみ（B） | — | — | Raycast設定変更 | いいえ | **はい（B）:割当先は mac/raycast/README.md に明記、登録操作は人間** |

## 仕分け（GUIしかない機能）

- A（機械化できる）: 導入・削除・検証・目録化 → CLI化済み
- B（画面まで案内）: Raycast のホットキー登録（手順と割当先はガイドに明記）
- C（人間専用）: OS権限ダイアログ、物理キーの実押し確認、キーの押し心地・体感の判定
