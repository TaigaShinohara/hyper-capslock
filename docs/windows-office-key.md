# Office キーを自分で止める（任意）

この keymap の推奨設定は、`Ctrl+Alt+Shift+Win` を送らない。
だから、通常はこのページの操作は要らない。

Mac と Windows の実機では、まだ押して確認していない。

ほかのツールが同じ4つのキーを送ってしまい、Office や Office.com が開くときだけ、自分で行う。
このリポジトリに、レジストリを書き換えるスクリプトは置いていない。下のコマンドを自動では実行しない。

> [!WARNING]
> Microsoft Q&A の回答は、レジストリを誤って変えると Windows が不安定になる、と注意している。実行する前に、レジストリ エディターの「ファイル」→「エクスポート」で、今の状態をファイルに保存する。製品マニュアルの専用ページではない。

## 分かっていること

Microsoft の説明: https://support.microsoft.com/en-us/office/using-the-office-key

- Office キーを押すと、Office アプリが開く。インストールが無ければ Office.com が開く。
- Office キー+W は Word、+T は Teams、+L は LinkedIn。ほかに `P` / `X` / `O` / `D` / `N` / `Y`。
- 対象は Windows 10 の 2019年5月の更新（バージョン 1903）以降、とページに書いてある。

物理的な Office キーが無いキーボードでも、`Ctrl+Alt+Shift+Win` が同じ働きをすることがある。これは利用報告と、Microsoft Q&A の回答でそう書かれている。製品の「Using the Office Key」ページの本文が、その4キーをそのまま列挙しているわけではない。

## 止める

https://learn.microsoft.com/en-us/answers/questions/4331341/disabling-the-office-hotkey-in-windows-10

コマンドプロンプトで、自分で次を入力する。

```bat
REG ADD HKCU\Software\Classes\ms-officeapp\Shell\Open\Command /t REG_SZ /d rundll32
```

効いたかどうかは、`Ctrl+Alt+Shift+Win` を押して Office が開かないことで見る。この確認も実機任せで、ここでは未確認。

## 戻す

自分で次を入力する。

```bat
REG DELETE HKCU\Software\Classes\ms-officeapp\Shell\Open\Command
```
