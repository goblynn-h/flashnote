#Requires AutoHotkey v2.0
#SingleInstance Force

; ============================================================
; 闪记 - 全局热键极简笔记
; ============================================================

; --- 路径常量 ---
CONFIG_FILE := A_ScriptDir "\config.ini"
STARTUP_LINK := A_Startup "\FlashNote.lnk"

; --- 读取或初始化配置 ---
NoteDir := IniRead(CONFIG_FILE, "Settings", "NoteDir", "")
HotkeyStr := IniRead(CONFIG_FILE, "Settings", "Hotkey", "")

if (NoteDir = "" || !DirExist(NoteDir)) {
    NoteDir := DirSelect(A_MyDocuments "\FlashNotes", 1, "选择笔记存储文件夹")
    if (NoteDir = "") {
        MsgBox("必须选择一个文件夹才能使用闪记。", "闪记", "Icon!")
        ExitApp()
    }
    DirCreate(NoteDir)
    IniWrite(NoteDir, CONFIG_FILE, "Settings", "NoteDir")
}

if (HotkeyStr = "") {
    HotkeyStr := CaptureHotkey("^+j", true)
    if (HotkeyStr = "")
        HotkeyStr := "^+j"
    IniWrite(HotkeyStr, CONFIG_FILE, "Settings", "Hotkey")
}

if (!FileExist(STARTUP_LINK))
    FileCreateShortcut(A_ScriptFullPath, STARTUP_LINK)

SetWorkingDir(NoteDir)

Try Hotkey(HotkeyStr, ShowInput, "On")
Catch {
    MsgBox("快捷键无效，已重置为 Ctrl+Shift+J", "闪记", "Icon!")
    HotkeyStr := "^+j"
    IniWrite(HotkeyStr, CONFIG_FILE, "Settings", "Hotkey")
    Hotkey(HotkeyStr, ShowInput, "On")
}

A_IconTip := "闪记"
RefreshTray()

; ============================================================
; 系统托盘菜单
; ============================================================

RefreshTray() {
    tray := A_TrayMenu
    tray.Delete()
    tray.Add("修改存储文件夹", (*) => ChangeFolder())
    tray.Add("修改快捷键", (*) => ChangeHotkey())
    tray.Add()
    autoOn := FileExist(STARTUP_LINK) ? true : false
    tray.Add("开机自启" (autoOn ? " ✓" : ""), (*) => ToggleAutoStart())
    tray.Add()
    tray.Add("退出", (*) => ExitApp())
}

ToggleAutoStart() {
    global
    if FileExist(STARTUP_LINK)
        FileDelete(STARTUP_LINK)
    else
        FileCreateShortcut(A_ScriptFullPath, STARTUP_LINK)
    RefreshTray()
}

ChangeFolder() {
    global NoteDir
    newDir := DirSelect("", 3, "选择新的笔记存储文件夹")
    if (newDir != "") {
        DirCreate(newDir)
        IniWrite(newDir, CONFIG_FILE, "Settings", "NoteDir")
        NoteDir := newDir
        SetWorkingDir(NoteDir)
    }
}

ChangeHotkey() {
    global HotkeyStr
    newHotkey := CaptureHotkey(HotkeyStr, false)
    if (newHotkey = "" || newHotkey = HotkeyStr)
        return
    Try {
        Hotkey(HotkeyStr, ShowInput, "Off")
        Hotkey(newHotkey, ShowInput, "On")
        HotkeyStr := newHotkey
        IniWrite(HotkeyStr, CONFIG_FILE, "Settings", "Hotkey")
    } Catch {
        MsgBox("快捷键无效，已恢复原快捷键。", "闪记", "Icon!")
        Hotkey(newHotkey, ShowInput, "Off")
        Hotkey(HotkeyStr, ShowInput, "On")
    }
}

; ============================================================
; 快捷键捕获
; ============================================================

CaptureHotkey(defaultKey, isFirstRun) {
    captured := ""
    captureDone := false

    prompt := isFirstRun
        ? "请直接按下你想要的快捷键组合...`n`n默认：Ctrl+Shift+J`n按 Esc 使用默认"
        : "请直接按下新的快捷键组合...`n`n当前：" defaultKey "`n按 Esc 取消"

    capGui := Gui("+AlwaysOnTop +ToolWindow")
    capGui.SetFont("s11", "Microsoft YaHei")
    capGui.AddText("w380 h90 +Center", prompt)
    capGui.OnEvent("Escape", (*) => captureDone := true)
    capGui.Show("w400 h120")

    OnMessage(0x0100, CaptureKeyDown)
    while !captureDone
        Sleep(10)
    OnMessage(0x0100, CaptureKeyDown, 0)
    capGui.Destroy()

    return captured != "" ? captured : defaultKey

    CaptureKeyDown(wParam, lParam, msg, hwnd) {
        vk := wParam
        if (vk = 0x1B)
            return
        if (vk = 0x10 || vk = 0x11 || vk = 0x12 || vk = 0x5B || vk = 0x5C)
            return
        mods := ""
        if GetKeyState("Ctrl", "P")
            mods .= "^"
        if GetKeyState("Alt", "P")
            mods .= "!"
        if GetKeyState("Shift", "P")
            mods .= "+"
        if GetKeyState("LWin", "P") || GetKeyState("RWin", "P")
            mods .= "#"
        keyName := VKToName(vk)
        captured := mods . keyName
        captureDone := true
    }
}

VKToName(vk) {
    if (vk >= 0x41 && vk <= 0x5A)
        return Chr(vk)
    if (vk >= 0x30 && vk <= 0x39)
        return Chr(vk)
    if (vk >= 0x60 && vk <= 0x69)
        return "Numpad" Chr(vk - 0x60 + 48)
    if (vk >= 0x70 && vk <= 0x7B)
        return "F" (vk - 0x6F)

    map := Map(
        0x08, "Backspace", 0x09, "Tab",   0x0D, "Enter",
        0x20, "Space",     0x21, "PgUp",  0x22, "PgDn",
        0x23, "End",       0x24, "Home",  0x25, "Left",
        0x26, "Up",        0x27, "Right", 0x28, "Down",
        0x2D, "Ins",       0x2E, "Del",
        0x6A, "NumpadMult", 0x6B, "NumpadAdd", 0x6D, "NumpadSub",
        0x6E, "NumpadDot", 0x6F, "NumpadDiv",
        0xBA, ";",  0xBB, "=",  0xBC, ",",
        0xBD, "-",  0xBE, ".",  0xBF, "/",
        0xC0, "``", 0xDB, "[",  0xDC, "\",
        0xDD, "]",  0xDE, "'"
    )
    if map.Has(vk)
        return map[vk]
    return "vk" Format("{:X}", vk)
}

; ============================================================
; 输入框
; ============================================================

ShowInput(*) {
    global InputGui, InputEdit

    if (IsSet(InputGui) && WinExist("ahk_id " InputGui.Hwnd)) {
        WinActivate("ahk_id " InputGui.Hwnd)
        InputEdit.Focus()
        return
    }

    editW := 400, editH := 34
    pad := 8                                       ; 浅绿框与 Edit 的间距

    frameW := editW + pad * 2
    frameH := editH + pad * 2

    x := (A_ScreenWidth - frameW) // 2
    y := (A_ScreenHeight - frameH) // 2

    ; 窗口 = 浅绿色圆角方框（背景就是浅绿）
    InputGui := Gui("-Caption +AlwaysOnTop +ToolWindow")
    InputGui.BackColor := "a7dba6"

    ; 白色输入框，加系统细边框充当"深绿内框线"
    InputGui.SetFont("s12 c333333", "Microsoft YaHei")
    InputEdit := InputGui.AddEdit("x" pad " y" pad " w" editW " h" editH " -Border -E0x200")

    ; 纯白背景
    SendMessage(0x0443, 0, 0xFFFFFF, InputEdit.Hwnd)

    ; 内部水平留白：游标不贴左边，左右各 8px
    SendMessage(0xD3, 3, (8 << 16) | 8, InputEdit.Hwnd)

    ; 方向键上下：跳到开头 / 末尾
    OnMessage(0x0100, OnEditKeyDown)

    ; 隐藏默认按钮处理 Enter
    btn := InputGui.AddButton("x-999 y-999 w0 h0 Default")
    btn.OnEvent("Click", (*) => SubmitNote())
    InputGui.OnEvent("Escape", (*) => CleanupInput())

    InputGui.Show("x" x " y" y " w" frameW " h" frameH)

    ; Win11 原生圆角（Win10 上静默无效）
    Try DllCall("Dwmapi\DwmSetWindowAttribute",
        "Ptr", InputGui.Hwnd, "UInt", 33, "UInt*", 2, "UInt", 4)

    InputEdit.Focus()
}

SubmitNote() {
    global InputGui, InputEdit, NoteDir

    text := Trim(InputEdit.Value)
    CleanupInput()

    if (text != "") {
        timestamp := FormatTime(A_Now, "yyyy/M/d HH:mm")
        filename := FormatTime(A_Now, "yyyy-MM-dd") ".md"
        FileAppend(timestamp " " text "`n`n", filename, "UTF-8")
    }
}

CleanupInput() {
    global InputGui, InputEdit

    if IsSet(InputGui)
        InputGui.Destroy()
    InputGui := unset
    InputEdit := unset
}

; 方向键：上→开头，下→末尾
OnEditKeyDown(wParam, lParam, msg, hwnd) {
    global InputEdit
    if (!IsSet(InputEdit) || hwnd != InputEdit.Hwnd)
        return

    if (wParam = 0x26) {                     ; VK_UP → 跳到开头
        SendMessage(0xB1, 0, 0, InputEdit.Hwnd)
        return 0
    }
    if (wParam = 0x28) {                     ; VK_DOWN → 跳到末尾
        len := SendMessage(0x000E, 0, 0, InputEdit.Hwnd)
        SendMessage(0xB1, len, len, InputEdit.Hwnd)
        return 0
    }
}
