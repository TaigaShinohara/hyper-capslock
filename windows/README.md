# Windows セットアップ

どちらか1つを選ぶ。**推奨は Kanata**（再起動なしで安定、Esc 判定が速い）。

## A. Kanata（推奨）— コアだけ

1. https://github.com/jtroo/kanata/releases から `kanata.exe` を取得
2. このフォルダで実行:

```powershell
kanata.exe --cfg windows\kanata\hyper-capslock.kbd
```

3. これで CapsLock 単押し=Esc / 長押し=Hyper が効く。
   Hyper+1/2/3 などのアプリ切替は PowerToys Keyboard Manager や
   下記 AutoHotkey 側のホットキー定義を併用する。

## B. AutoHotkey v2 — フルセット

1. https://www.autohotkey.com/ から AutoHotkey v2 をインストール
2. `windows/autohotkey/HyperCapsLock.ahk` をダブルクリックで起動
3. スタートアップに入れたい場合は `Win+R` → `shell:startup` のフォルダへショートカットを置く

スクリプト内の `Hyper + 1/2/3` の対象アプリ（Code / Cursor / Chrome / Terminal）は
自分の環境に合わせて書き換えること。

## 注意

- Kanata と AutoHotkey の CapsLock 定義を**同時には使わない**（二重に効く）。
- ゲーム等で Hyper が邪魔なときは、使っているツールをトレイから一時停止する。
