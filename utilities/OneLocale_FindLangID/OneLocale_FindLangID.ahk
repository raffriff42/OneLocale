;*****************************************************************
; OneLocale_FindLangID
;; Find language tags matching a partial Name
;
;@version 1.0 2025-11-23
;*****************************************************************
S_TITLE   := "OneLocale_FindLangID"
S_DESC    := "Find language tags matching a partial Name"
S_VERSION := "1.0"
;@Ahk2Exe-SetVersion 1.0.0.2
;@Ahk2Exe-SetName OneLocale_FindLangID
;@Ahk2Exe-SetDescription Find language tags matching a partial Name
;@Ahk2Exe-SetCopyright (c) 2025 raffriff42 (LGPL)
;@Ahk2Exe-SetMainIcon OneLocale.ico

;************************************************
; Credits - I believe that unless otherwise attributed,
; this AutoHotkey code is original
; (other than sample code from the documentation)
;
; Icon adapted from 'Earth_icon_2.png'
; https://commons.wikimedia.org/wiki/File:Earth_icon_2.png
; https://creativecommons.org/publicdomain/zero/1.0/
;************************************************

;************************************************
; OneLocale(tm) is free software; you can redistribute it and/or
; modify it under the terms of the GNU Lesser General Public
; License as published by the Free Software Foundation; either
; version 2.1 of the License, or (at your option) any later version.
;
; This and all sample code is public domain, marked CC0 1.0
; https://creativecommons.org/publicdomain/zero/1.0/
;
; This library is distributed in the hope that it will be useful,
; but WITHOUT ANY WARRANTY; without even the implied warranty of
; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
; Lesser General Public License for more details.
;************************************************

#Requires AutoHotkey v2.0
#SingleInstance Off

#Warn All, MsgBox
;#Warn LocalSameAsGlobal, Off
;#Warn Unreachable, Off

;/////////////////////////////////////////////////
;; INCLUDES
;/////////////////////////////////////////////////

#Include "..\..\lib\OneLocale.ahk"
#Include "..\..\lib\OneLocale_LangIDs.ahk"
#Include "..\lib\ToolTips.ahk"

;/////////////////////////////////////////////////
;; INIT
;/////////////////////////////////////////////////

g_ini_path := SubStr(A_ScriptFullPath, 1, -4) ".ini"
if (!StrLen(FileExist(g_ini_path)))
    FileAppend "", g_ini_path

g_arLangs := OneLocale_ListLangs()

locale_info := OneLocale_Init({noLangFile:true})
if (!locale_info.success) {
    MsgBox(locale_info.errmsg, S_TITLE, "icon!")
    ExitApp
}

if (!A_IsCompiled) {
    icon_path := A_ScriptDir "\images\OneLocale.ico"
    TraySetIcon icon_path
}

;/////////////////////////////////////////////////
;; GUI
;/////////////////////////////////////////////////

Gmain := BuildGui()
return

BuildGui()
{
    global S_TITLE

    local G := Gui()
    G.SetFont("s10")

    local ctl
    ctl := G.Add("Text", "x16 y13 w340", sT("gui", "description"
        , "Find language tags matching a partial Name"))
    ctl.SetFont("w700 q2")

    G.Add("Text", "x16 yp+26 w340", sT("gui", "prompt"
        , "Enter a Language Name (eg, 'Deutsch', 'German')"))

    ctl := G.Add("Edit", "xp yp+26 section w340 vctName")
    ctl.OnEvent("Change", NamedChanged.Bind("Normal"))
    ctl.ToolTip := sT("tooltips", "name"
        , "Enter a partial Language Name")

    ctl := G.Add("Radio", "x386 ys-16 w160 vctOpt Checked", sT("gui", "opt_start"
        , "&Starts with"))
    ctl.OnEvent("Click", OptionClicked)
    ctl.ToolTip := sT("tooltips", "opt_start"
        , "Finds Languages starting with your input")
    ctl := G.Add("Radio", "xp ys+6 w160", sT("gui", "opt_has"
        , "&Contains"))
    ctl.ToolTip := sT("tooltips", "opt_has"
        , "Finds languages containing your input anywhere")

    ctl := G.Add("ListBox", "vMyListBox x16 ys+32 w530 h190 AltSubmit")
    ctl.OnEvent("Change", ListClick.Bind("Normal"))
    ctl.OnEvent("DoubleClick", ListDblClick.Bind("Normal"))
    local HLB := ctl.hwnd

    ;LB_SETTABSTOPS
    ;credit to: "LBEX - some functions for ListBoxes" by "just_me"
    ;https://www.autohotkey.com/boards/viewtopic.php?p=66865#p66865
    local ColUnits := [50, 150, 150]
    local TabCount := 3
    local TabArray := Buffer(TabCount * 4, 0)
    local TabAddr  := TabArray.Ptr
    local TabPos   := 0

    local index, units
    for index, units in ColUnits {
        TabAddr := NumPut("UInt", TabPos += units, TabAddr + 0)
    }

    ; 0x0192 == LB_SETTABSTOPS
    DllCall("SendMessage"
            , "Ptr" , HLB
            , "UInt", 0x0192
            , "Ptr" , TabCount
            , "Ptr" , TabArray.Ptr
            , "UInt")

    ctl := G.Add("Button", "Disabled Default x16 y293 w210 h30 vBtn_Copy", sT("gui", "btn_copy"
        , "Copy Language Tag"))
    ctl.OnEvent("Click", BtnCopy.Bind("Normal"))

    ctl := G.Add("Button", "x336 y293 w210 h30", sT("gui", "btn_close"
        , "Close"))
    ctl.OnEvent("Click", BtnClose.Bind("Normal"))

    global SB := G.Add("StatusBar")
    SB.SetText("")
    SB.SetIcon("imageres.dll", 222) ; blank

    G.OnEvent("Close" , BtnClose)
    G.OnEvent("Escape", BtnClose)

    G.Title := S_TITLE
    G.Show("Center h354 w572")

    OnMessage(0x200, On_WM_MOUSEMOVE)
    OnMessage(0x2A3, On_WM_MOUSELEAVE)
    return G
}

;/////////////////////////////////////////////////
;; EVENTS
;/////////////////////////////////////////////////

/**************************************************
 */
ListClick(*)
{
    global Gmain, SB
    if (Gmain["MyListBox"].Value)
        Gmain["Btn_Copy"].Enabled := true
    SB.SetText("")
    SB.SetIcon("imageres.dll", 222) ; blank
    return
}

/**************************************************
 */
ListDblClick(*)
{
    ListClick()
    BtnCopy()
    return
}

/**************************************************
 */
NamedChanged(*)
{
    global g_arLangs, Gmain, SB
    Gmain.Submit(0)
    local optStart := Gmain["ctOpt"].Value
    local sName    := Gmain["ctName"].Value
    local lb1      := Gmain["MyListBox"]
    local Btn_Copy := Gmain["Btn_Copy"]

    local arLangs := OneLocale_FindLangsByName(g_arLangs
                        , sName, (optStart==1))

    ; transform array-of-arrays to array-of-TSV-strings:

    local n, arLang, m, v, arList := []
    for n, arLang in arLangs {
        local s := ""
        for m, v in arLang {
            s .= v "`t"
        }
        s := SubStr(s, 1, -1)
        arList.Push(s)
    }

    ;lb1.Opt("-Redraw")
    lb1.Delete
    lb1.Add(arList)
    ;lb1.Opt("+Redraw")

    Btn_Copy.Enabled := false
    SB.SetText("")
    SB.SetIcon("imageres.dll", 222) ; blank
    return
}

/**************************************************
 */
BtnCopy(*)
{
    global g_arLangs, Gmain, SB, S_TITLE
    Gmain.Submit(0)

    local MyListBox := Gmain["MyListBox"]
    if (!MyListBox.Value) {
        SB.SetText(sT("errors", "bad_sel", "No selection!"))
        SB.SetIcon("imageres.dll", 231) ; yellow caution
        return
    }

    local sTag := StrSplit(MyListBox.Text, "`t", " ")[1]
    A_Clipboard  := sTag

    local msg    := " " sT("messages", "msg_copied", "Copied language tag < %tag% >", {tag:sTag})
    local arLang := OneLocale_FindLangByID(g_arLangs, sTag)
    if (arLang)
        msg .= "  |  " arLang[2]

    SB.SetText(msg)
    SB.SetIcon("imageres.dll", 233) ; green check
    return
}

/**************************************************
 */
BtnClose(*)
{
    ExitApp
    return
}

/**************************************************
 */
Gui_Close(*)
{
    Gmain.Destroy()
    ExitApp
}

/**************************************************
 */
OptionClicked(*)
{
    global Gmain, SB
    Gmain.Submit(0)
    local optStart := Gmain["ctOpt"].Value
    local Btn_Copy := Gmain["Btn_Copy"]

    Btn_Copy.Enabled := false
    SB.SetText("")
    SB.SetIcon("imageres.dll", 222) ; blank
    return
}

; (end)
