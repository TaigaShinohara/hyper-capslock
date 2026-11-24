# 監査記録 — ハイパーCapsLock（2026-11-24）

様式: agent_friendly_app_design スキル references/checklist.md §1

## 現状（監査時点＝実装前）

| 項目 | 状態 | 根拠 |
|---|---|---|
| データの保存場所と形式 | 済 | 設定ファイル群がデータそのもの: `mac/karabiner/hyper-capslock.json`（JSON）、`windows/kanata/hyper-capslock.kbd`、`windows/autohotkey/HyperCapsLock.ahk`、割り当て表 `docs/keymap.md`（Markdown表） |
| 業務ロジックとUIの分離 | 対象外（理由） | GUIアプリではない。ただし「割り当て定義」が keymap.md／Karabiner JSON／AHK の3か所に重複し、正本が無い＝芯が分散していた |
| 外部から触れる経路 | 未 | CLI・API・ディープリンクなし。ファイルを人間がコピーするだけ |
| IDの安定性 | 未 | 割り当てにIDなし。キー表記（Hyper+C等）が事実上の識別子だが機械可読でない |
| 履歴 | 未 | 導入・変更の履歴が残らない |
| テスト基盤 | 未 | JSON構文チェックのみ手作業。自動テストなし。スクリーンショットは対象外（画面を持たない） |
| **到達レベル** | **L0** | 状態も結果もファイルと人間の目でしか分からない |

## 目標

- **目標レベル: L2（操作可能）** — 読み取り（status/list/get/history/doctor）＋書き込み（install/uninstall、dry-run/冪等キー付き）を、共有芯を通す CLI で実装する。
- L3（検証可能）は `verify` と決定的テスト（tempホームへの導入再現）で土台を作り、到達宣言はしない（スクリーンショット相当の「実機でキーが効く」確認は人間専用＝物理キー入力のため。設計提案として docs/AGENT_GUIDE.md に残す）。
- MCP: L2/L3 が安定してから最後に検討（今回は作らない）。SDK: 作らない（需要なし、既定どおり）。

## 正本化の方針

割り当ての正本を `config/bindings.json`（安定ID付き）に一本化し、CLI はそれとプラットフォーム設定ファイルを同じ芯（`cli/hypercapslock_core.py`）で読む。既存のプラットフォームファイルは配布物のまま残す（生成し直さない＝既存利用者を壊さない）。

## 追記（マージ時・2026-11-24）

作業中に main が進み、macOS ネイティブアプリ（HyperCapsLockApp、Swift・Coreにテストあり）と判断記録（docs/decisions.md）が追加され、割り当て表（docs/keymap.md）が正本として確定していた。本CLIの対象は『設定ファイル一式（Karabiner/Kanata/AHK の代替導線）＋割り当ての機械可読化』であり、ネイティブアプリ本体のエージェント対応は対象外（未実施）。bindings は keymap.md の現行内容に合わせて修正済み（旧スターターの Hyper+Enter 等は excluded）。
