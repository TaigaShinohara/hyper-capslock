#Requires AutoHotkey v2.0
; ============================================================
; ハイパーCapsLock — AI開発のコックピットにする
; CapsLock: tap = Esc, hold = Hyper (Ctrl+Alt+Shift+Win)
; AutoHotkey v2 用。Kanata を使わない場合のフルセット版。
; ============================================================

SetCapsLockState "AlwaysOff"

; --- Core: CapsLock -> Hyper / Esc -------------------------
*CapsLock::
{
    Send "{Ctrl down}{Alt down}{Shift down}{Win down}"
    KeyWait "CapsLock"
    Send "{Ctrl up}{Alt up}{Shift up}{Win up}"
    if (A_PriorKey = "CapsLock")
        Send "{Esc}"
}

; Hyper = ^!+#  (Ctrl + Alt + Shift + Win)

; --- A. AIとの往復 ------------------------------------------
; Hyper + C : AIチャット欄へ (Cursor / VS Code: Ctrl+Shift+L 相当)
^!+#c::Send "^+l"

; Hyper + Enter : AIへ送信 (Ctrl+Enter 相当に寄せる。アプリにより調整可)
^!+#Enter::Send "^{Enter}"

; Hyper + V : クリップボード履歴 (Win+V を Hyper 経由で)
^!+#v::Send "#v"

; --- B. 確認への移動 ----------------------------------------
; アプリ固定席は環境に合わせてパス/タイトルを書き換えること。
; 例は「すでに起動しているウィンドウを前面化」する形。
^!+#1::
{
    if WinExist("ahk_exe Code.exe") || WinExist("ahk_exe Cursor.exe")
        WinActivate
}
^!+#2::
{
    if WinExist("ahk_exe chrome.exe")
        WinActivate
}
^!+#3::
{
    if WinExist("ahk_exe WindowsTerminal.exe")
        WinActivate
}

; Hyper + Q / W : ウィンドウを左半分 / 右半分 (Win+矢印で代用)
^!+#q::Send "#{Left}"
^!+#w::Send "#{Right}"

; Hyper + R : 再読み込み
^!+#r::Send "^{F5}"

; --- C. 補助 -------------------------------------------------
; Hyper + T : ターミナル開閉 (VS Code: Ctrl+`)
^!+#t::Send "^``"

; Hyper + Space : ランチャー (PowerToys Run / Flow Launcher を想定し Win+S ではない)
; 使っているランチャーの起動キーに合わせて変更すること。デフォルトは Alt+Space を送る。
^!+#Space::Send "!{Space}"

; Hyper + S : スクリーンショット (Win+Shift+S)
^!+#s::Send "#+s"

; --- 移動レイヤー (第2弾) ------------------------------------
^!+#h::Send "{Left}"
^!+#j::Send "{Down}"
^!+#k::Send "{Up}"
^!+#l::Send "{Right}"
^!+#a::Send "{Home}"
^!+#e::Send "{End}"
^!+#b::Send "^{Left}"
^!+#f::Send "^{Right}"
