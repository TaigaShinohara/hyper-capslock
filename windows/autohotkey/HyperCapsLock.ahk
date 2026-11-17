#Requires AutoHotkey v2.0
#SingleInstance Force

; ハイパーCapsLock — Windows 用 AutoHotkey v2
; 割り当て表の正本は docs/keymap.md。Kanata と同時には使わない。
;
; CapsLock の位置（スキャンコード 03A）を押しているあいだだけ、
; 下のキーが別のショートカットを送る。
; Ctrl+Alt+Shift+Win は押した瞬間にも、離したときにも送らない。
;
; ドキュメント:
;   https://www.autohotkey.com/docs/v2/KeyList.htm
;   https://www.autohotkey.com/docs/v2/lib/KeyWait.htm
;   https://www.autohotkey.com/docs/v2/FAQ.htm

InstallKeybdHook
SetCapsLockState "AlwaysOff"

; 200 と 60 秒はこちらの選択。OS が決めた秒数ではない。
; 60 秒は、キーを離した通知が来ない配列で Hyper が戻らなくなるのを防ぐ上限。
global TapMs := 200
global HoldCapMs := 60000
global Phase2 := false
global hyperDown := false
global hyperUsed := false

kanataHit := ""
; v1.12.0 の Windows x64 zip で確認した名前。arm64 や、名前を変えた exe は検出できない。
for name in ["kanata_windows_gui_winIOv2_x64.exe", "kanata_windows_tty_winIOv2_x64.exe", "kanata_windows_gui_winIOv2_cmd_allowed_x64.exe", "kanata_windows_tty_winIOv2_cmd_allowed_x64.exe", "kanata_windows_gui_wintercept_x64.exe", "kanata_windows_tty_wintercept_x64.exe", "kanata_windows_gui_wintercept_cmd_allowed_x64.exe", "kanata_windows_tty_wintercept_cmd_allowed_x64.exe"] {
    if ProcessExist(name) {
        kanataHit := name
        break
    }
}
if (kanataHit != "") {
    MsgBox "Kanata（" kanataHit "）が動いています。`nCapsLock はどちらか一方だけにしてください。このスクリプトは終了します。"
    ExitApp
}

*sc03A::HyperCapsDown()

#HotIf hyperDown
*1:: {
    HyperSend("#1")
}
*2:: {
    HyperSend("#2")
}
*3:: {
    HyperSend("#3")
}
*q:: {
    HyperSend("#{Left}")
}
*w:: {
    HyperSend("#{Right}")
}
*c:: {
    HyperChat()
}
*t:: {
    HyperPanel()
}
#HotIf

; 第2弾。最初は Phase2 が false なので動かない。
; 足すときは true にして、いらない行をコメントにしてから、スクリプトを読み込み直す。
#HotIf hyperDown && Phase2
*h:: {
    HyperSend("{Left}")
}
*j:: {
    HyperSend("{Down}")
}
*k:: {
    HyperSend("{Up}")
}
*l:: {
    HyperSend("{Right}")
}
*a:: {
    HyperSend("{Home}")
}
*e:: {
    HyperSend("{End}")
}
*b:: {
    HyperSend("^{Left}")
}
*f:: {
    HyperSend("^{Right}")
}
#HotIf

HyperCapsDown() {
    global hyperDown, hyperUsed, TapMs, HoldCapMs
    hyperDown := true
    hyperUsed := false
    start := A_TickCount
    released := KeyWait("sc03A", "T" . (HoldCapMs // 1000))
    hyperDown := false
    if (released && !hyperUsed && (A_TickCount - start) < TapMs)
        Send "{Esc}"
}

HyperSend(keys) {
    global hyperUsed := true
    Send keys
}

HyperChat() {
    global hyperUsed := true
    if WinActive("ahk_exe Cursor.exe")
        Send "^{l}"
    else
        Send "#1"
}

HyperPanel() {
    global hyperUsed := true
    if WinActive("ahk_exe Cursor.exe") || WinActive("ahk_exe Code.exe")
        Send "^{j}"
}
