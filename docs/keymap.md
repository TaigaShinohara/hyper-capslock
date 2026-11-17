# ハイパーCapsLock 割り当て表

> CapsLockを、AI開発のコックピットにする

## ループで見る

```
指示 (Hyper+C → 打つ → Hyper+Enter)
  → 生成 (待つ / ダメなら Esc で止める)
    → 確認 (Hyper+2 でプレビュー / Hyper+T でエラー)
      → 修正 (Hyper+1 でエディタへ戻る)
```

## 全割り当て

| キー | 動作 | 区分 | 実装先 |
|---|---|---|---|
| Caps 単押し | Esc | コア | Karabiner / Kanata / AHK |
| Caps 長押し | Hyper | コア | Karabiner / Kanata / AHK |
| Hyper + C | AIチャット欄へ | スターター | Karabiner / AHK (Cmd/Ctrl+Shift+L) |
| Hyper + Enter | AIへ送信 | スターター | Karabiner / AHK (Cmd/Ctrl+Enter) |
| Hyper + 1 | エディタを前面 | スターター | Raycast / AHK |
| Hyper + 2 | ブラウザを前面 | スターター | Raycast / AHK |
| Hyper + 3 | ターミナルを前面 | スターター | Raycast / AHK |
| Hyper + Q | ウィンドウ左半分 | スターター | Raycast / AHK |
| Hyper + W | ウィンドウ右半分 | スターター | Raycast / AHK |
| Hyper + T | ターミナル開閉 | スターター | Karabiner / AHK (Ctrl+`) |
| Hyper + Space | ランチャー | スターター | Raycast / AHK |
| Hyper + V | クリップボード履歴 | スターター | Raycast / AHK |
| Hyper + H/J/K/L | ←↓↑→ | 第2弾 | Karabiner / AHK |
| Hyper + A/E | 行頭 / 行末 | 第2弾 | Karabiner / AHK |
| Hyper + B/F | 単語移動 | 第2弾 | Karabiner / AHK |
| Hyper + R | 再読み込み / 再実行 | 第2弾 | AHK / アプリ側 |
| Hyper + S | スクリーンショット | 第2弾 | AHK / アプリ側 |

## カスタマイズの考え方

- エディタを変えたら `Hyper+1` と `Hyper+C` の送り先だけ変える。
- よくやる動作が増えたら、空いている Hyper+キーに1個ずつ足す。一度に足さない。
