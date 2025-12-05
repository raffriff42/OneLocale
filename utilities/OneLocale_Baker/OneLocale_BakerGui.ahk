;************************************************
; OneLocale_BakerGui.ahk
;; Load .LANG files, generate .AHKs
;
;@version 0.1 2025-10-27
;@version 0.2 2025-11-23
;************************************************
S_TITLE   := "OneLocale_Baker"
S_VERSION := "0.2 2025-11-23"
;@Ahk2Exe-SetVersion 0.2.0.1
;@Ahk2Exe-SetName OneLocale_Baker
;@Ahk2Exe-SetDescription Load .LANG files, generate .AHKs
;@Ahk2Exe-SetCopyright (c) 2025 raffriff42 (LGPL)
;@Ahk2Exe-SetMainIcon OneLocale_BakerGui.ico

;************************************************
; Credits - I believe that unless otherwise attributed,
; this AutoHotkey code is original
; (other than sample code from the documentation)
;
; Grok AI helped me in places (as noted in the comments), but none of this code is AI-generated.
;
; 'Cupcake' icon is from publicdomainvectors.org, featuring public domain vector artwork.
; https://publicdomainvectors.org/en/free-clipart/Cupcake-vector-clip-art/78550.html
;************************************************

;************************************************
; LEGAL
; This code is free software; you can redistribute it and/or modify it under the
; terms of the GNU Lesser General Public License as published by the Free Software
; Foundation, version 3.0. https://www.gnu.org/licenses/lgpl-3.0.en.html
;
; This and all sample code is public domain, marked CC0 1.0
; https://creativecommons.org/publicdomain/zero/1.0/
;
; This library is distributed in the hope that it will be useful, but WITHOUT ANY
; WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
; PARTICULAR PURPOSE. See the GNU Lesser General Public License for more details.
;************************************************

#Requires Autohotkey v2.0
#SingleInstance Off
#NoTrayIcon
#Warn All, MsgBox
A_StringCaseSense := false
SetTitleMatchMode(2) ; contains

;/////////////////////////////////////////////////
;; INCLUDES
;/////////////////////////////////////////////////

#Include "lib\OneLocale.ahk"
#Include "lib\OneLocale_Baker.ahk"
#Include "lib\ControlEnable.ahk"
#Include "lib\FileUtils.ahk"
#Include "lib\IniFiles.ahk"
#Include "lib\StringUtils.ahk"
#Include "lib\ToolTips.ahk"

;/////////////////////////////////////////////////
;; INIT
;/////////////////////////////////////////////////

ICON_CHECK     := 297  ; green check icon (index into Shell32.dll)
ICON_INFO      := 278  ; blue info icon
ICON_CAUTION   := 78   ; yellow caution icon

locale_info := OneLocale_Init({sDocExt:"txthelp"})
if (!locale_info.success) {
    MsgBox(locale_info.errmsg, S_TITLE, "icon!")
    ExitApp()
}
;g_ini_path   := locale_info.iniPath
;g_lang_path  := locale_info.langPath
;g_docs_path  := locale_info.docsPath

;; GLOBALS requiring initialization

g_WinTitle     := S_TITLE
g_winWid       := 0  ; actual width of this window, determined after Gui Show
g_winID        := 0  ; unique ID of this window
g_tmp_folder   := "" ; FoldersListUpdate

g_StatIcon     := ICON_CHECK

g_InCtxKey     := false

;; RECENT INPUT FOLDERS
g_srcfolders := IniReadSection(g_ini_path, "SrcFolders", "ERROR")
if (!StrLen(g_srcfolders) || g_srcfolders=="ERROR") {
    g_srcfolders := A_ScriptDir "\in"
}
g_arSrcFolders := StrSplit(g_srcfolders, "`n", "`r")

;; RECENT OUTPUT FOLDERS
g_outfolders := IniReadSection(g_ini_path, "OutFolders", "ERROR")
if (!StrLen(g_outfolders) || g_outfolders=="ERROR") {
    g_outfolders := A_ScriptDir "\out"
}
g_arOutFolders := StrSplit(g_outfolders, "`n", "`r")

; FONT
g_nFontSize := Round(IniRead(g_ini_path, "general", "Fontsize", 9))
g_nFontSize := Min(Max(9, g_nFontSize), 12)

g_StatText := sT("status", "ready", "/Ready")

; commandline args override IniRead above
for n, s in A_Args
{
    if (InStr(s, "\\?\")==1)               ; remove long path prefix
        s := SubStr(s, 5)
    if (RegExMatch(s, "[*?]"))             ; skip if 's' contains wildcsrds
        continue
    s := CFileUtils.PrefixLongPath(s)      ; prefix long path
    s := CFileUtils.ResolveShortcut(s)     ; if 's' is a shortcut, get target
    s := CFileUtils.RemoveQuotes(s)        ; remove quotes, if any
    if (!StrLen(s))
        continue
    s := CLocale.PathRelativeTo(s, A_WorkingDir, true) ; resolve relative path
    s := CFileUtils.PrefixLongPath(s)      ; prefix long path
    if (StrLen(DirExist(s)))
    {
        switch (A_Index) {
        case 1:
            FoldersDataUpdate(s, false)
        case 2:
            FoldersDataUpdate(s, true)
        default:
            break
        }
    }
}

if (!A_IsCompiled) {
    TraySetIcon "images\OneLocale_BakerGui.ico"
}

;/////////////////////////////////////////////////
;; GUI
;/////////////////////////////////////////////////

Gmain := BuildGui()
GuiSubmitAndGoTest()
return

BuildGui()
{
    global S_TITLE, S_VERSION
    global g_nFontSize, g_FontScale
    global g_WinTitle, g_winID, g_winWid

    local G := Gui()
    G.Opt("+E0x40000 -MaximizeBox +OwnDialogs -DPIScale")
    ; "+E0x40000" enables a taskbar icon

    local nLangFontSize := CStringUtils.ValueOf(IniRead(g_lang_path, "general", "Fontsize", ""))
    if (nLangFontSize > 0.5) {
        g_nFontSize := Min(Max(8, g_nFontSize * (nLangFontSize / 9.0)), 14)
    }

    local sLangFont := IniRead(g_lang_path, "general", "Font", "")
    if (StrLen(sLangFont))
    {
        G.SetFont("s" g_nFontSize, "sLangFont")
    }
    else {
        G.SetFont("s" g_nFontSize)
    }
    local scx := (g_nFontSize / 9.0)
    g_FontScale := scx

    local cap := StrReplace(sT("general", "Description", "/Description")
                , " & ", " && ", A_StringCaseSense)
    G.Add("Text", "x6", cap)

    ; -------------------
    ;; Row 1 (SOURCE FOLDER)

    local x1 := Round(scx * 90)
    local xr := Round(scx * 506) ; rightmost column of buttons
    local y1 := Round(scx * 32)
    local y2 := y1 + 4
    local y3 := y1 - 4
    local w1 := Round(scx * 400)

    cap := sT("gui", "SrcFolder", "/Input folder:")
    G.Add("Text"
        , "x6 y" y2 " r1", cap)

    ctl := G.Add("ComboBox"
        , "x" x1 " y" y1 " w" w1 " vvSrcFolder"
        , g_arSrcFolders)
    ctl.OnEvent("Change", FolderChanged)
    ctl.isOut := false
    ctl.ToolTip := ""
    ;HFolder := ctl.hwnd

    cap := sT("gui", "btn_SrcFolder", "/Folder...")
    ctl := G.Add("Button"
        , "x" xr " y" y3 " w80 -Wrap vvBtnSrcFolder", cap)
    ctl.OnEvent("Click", ButtonFolder)
    ctl.isOut := false
    ctl.ToolTip := sT("tooltips", "btn_SrcFolder", "")

    ; -------------------
    ;; Row 2 (OUTPUT FOLDER)

    y1 := y1 + Round(scx * 42)
    y2 := y1 + 4
    y3 := y1 - 4

    cap := sT("gui", "OutFolder", "/Output folder:")
    G.Add("Text"
        , "x6 y" y2 " r1", cap)

    ctl := G.Add("ComboBox"
        , "x" x1 " y" y1 " w" w1 " vvOutFolder"
        , g_arOutFolders)
    ctl.OnEvent("Change", FolderChanged)
    ctl.isOut := true
    ctl.ToolTip := ""
    ;HFolder := ctl.hwnd

    cap := sT("gui", "btn_OutFolder", "/Folder...")
    ctl := G.Add("Button"
        , "x" xr " y" y3 " w80 -Wrap vvBtnOutFolder", cap)
    ctl.OnEvent("Click", ButtonFolder)
    ctl.isOut := true
    ctl.ToolTip := sT("tooltips", "btn_OutFolder", "")

    ; -------------------
    ;; Row 3 (LANGUAGE, GO, HELP)

    x1 := Round(scx * 90)
    y1 := y1 + Round(scx * 42)
    y2 := y1 + 4
    w1 := Round(scx * 100)

    ;local x_go := Round(scx * 362)
    w1 := Round(scx * 80)

    cap := sT("gui", "btn_Go", "/Go")
    ctl := G.Add("Button"
        , "x" x1 " y" y1 " w" w1 " -Wrap Default vBtn_Go", cap)
    ctl.OnEvent("Click", ButtonGo.Bind("Normal"))
    ctl.Enabled := false
    ctl.ToolTip := sT("tooltips", "Btn_Go", "")

    cap := sT("gui", "btn_Help", "/Help")
    ctl := G.Add("Button"
        , "x" xr " y" y1 " w80 -Wrap", cap)
    ctl.OnEvent("Click", ButtonHelp.Bind("Normal"))
    ctl.ToolTip := sT("tooltips", "Btn_Help", "")

    ; -------------------
    ;; Row 6 (STATUS)

    G.Add("StatusBar", "vStatus1")

    ; -------------------
    ;; SHOW GUI

    h1 := y1 + Round(scx * 56) ; GUI HEIGHT
    w1 := Round(scx * 600)
    G.Title := S_TITLE
    G.Show("x64 y64 w" w1 " h" h1)

    ; -------------------
    ; GuiControl update statements

    SetTitleMatchMode(3) ; exact
    WinGetPos( , , &g_winWid, , g_WinTitle)
    g_winID := WinGetID(g_WinTitle)
    SetTitleMatchMode(2) ; contains
    ;if (!g_winWid) {
    ;    return
    ;}

    ; folder lists - select first item
    G["vSrcFolder"].Choose(1)
    G["vOutFolder"].Choose(1)

    G["vBtnSrcFolder"].Focus() ; deselect 'vSrcPath' edit control

    G.OnEvent("DropFiles", GuiDropFiles)
    OnMessage(0x200, On_WM_MOUSEMOVE) ; tooltips
    OnMessage(0x2A3, On_WM_MOUSELEAVE)
    OnExit(ExitSub)
    return G
}

;/////////////////////////////////////////////////
;; EVENT HANDLERS
;/////////////////////////////////////////////////

; called @ script termination (eg, ExitApp)
ExitSub(*)
{
    global
    Gmain.Destroy() ; if not called, can leave AutoHotkey instance running (?)
    return
}

/**************************************************
 * #### ButtonFolder: browse for an input or output folder
 */
ButtonFolder(ctl, *)
{
    global
    Gmain.Submit(0)
    local isOut   := ctl.isOut
    local vFolder := Gmain[(isOut ? "vOutFolder" : "vSrcFolder")].Text

    ;start_folder := A_InitialWorkingDir
    local start_folder := "::{20d04fe0-3aea-1069-a2d8-08002b30309d}"
    if (StrLen(vFolder) > 0) {
        start_folder := "*" vFolder
    }

    ToolTip()
    local options := (isOut ? 3 : 0) ; if output: allow "make new folder" button
    local cap := sT("gui", (isOut ? "OutFolder" : "SrcFolder")
                        , "Select Folder")
    local ff  := DirSelect(start_folder, options, cap)
    g_tmp_folder := ""
    if (StrLen(ff)) {
        g_tmp_folder := ff
        FoldersListUpdate(isOut)
    }
    return
}

/*****************************************
 * ##### ButtonGo: read a .LANG file, generate .ahk code
 * <!--
 * @version 2025-10-27
 * @version 2025-11-05 handle extenders
 * -->
 */
ButtonGo(*)
{
    global

    ToolTip()
    local oSaved     := Gmain.Submit(0)
    local vSrcFolder := oSaved.vSrcFolder
    local vOutFolder := oSaved.vOutFolder

    ; FOLDERS

    FoldersListUpdate(false)
    FoldersListUpdate(true)

    local srcfolders := ""
    local k, v
    for k, v in g_arSrcFolders {
        if (StrLen(v))
            srcfolders .= v "`n"
    }
    IniWriteSection(g_ini_path, "SrcFolders", srcfolders)

    local outfolders := ""
    for k, v in g_arOutFolders {
        if (StrLen(v))
            outfolders .= v "`n"
    }
    IniWriteSection(g_ini_path, "OutFolders", outfolders)

    ; EXECUTE

    local beep := IniRead(g_ini_path, "general", "Beep", 0)

    loop files vSrcFolder "\*.lang"
    {
        local vSrcPath := A_LoopFileFullPath
        local errmsg := IniFileDupeCheck(vSrcPath)
        if (StrLen(errmsg)) {
            MsgBox(errmsg, S_TITLE, "icon!")
            return
        }

        ; get the language ID from either file name or 'lang_id' key

        local vSrcFile := CFileUtils.GetBaseName(vSrcPath)
        local vLangIDA := IniRead(vSrcPath, "general", "lang_id", "")
        local vLangIDB := ""
        if (RegExMatch(vSrcFile, "^[^[]+\[([^\]]+)\].*$", &m)) {
            vLangIDB := m[1]
        }
        local infoA   := CLocale.GetLocaleInfoSet(vLangIDA)
        local infoB   := CLocale.GetLocaleInfoSet(vLangIDB)
        local vLangID := ""
        if (IsObject(infoB) && !IsObject(infoA)) {
            vLangID := infoB["IsoTag"]
        }
        else {
            ; 'if both good, 'lang_id' key overrides file name
            vLangID := infoA["IsoTag"]
        }

        if (!StrLen(vLangID)) {
            errmsg := sT("errors", "bad_id"
                        , "Can't determine lang_id for \n%path%"
                        , {path:vSrcPath})
            MsgBox(errmsg, S_TITLE, "icon!")
            return
        }
        ControlEnableALL(Gmain, false)

        ; read .LANG file, return Map tree
        local mlang := Map()
        LoadLangFile(mlang, vSrcPath)

        ; ----------------------------------------
        ; here we have a Map representation of the .LANG file;
        ; now we generate .ahk code to instantiate this Map:
        ; ----------------------------------------

        outname := CFileUtils.GetBaseName(vSrcPath)
        outpath := vOutFolder "\" outname ".ahk"

        ; input a Map tree, generate .ahk code
        BakeLangMap(outpath, mlang, vSrcPath, vLangID)
        ;   out_path - file to be created or overwritten
        ;   src_map  - source Map tree
        ;   src_path - source file (used as a note in the generated comments ONLY)
        ;   lang_id  - identifier (g_lang_data key) for the current map, eg, "en"
        mlang := 0

        ;Sleep 1000
        if (beep) {
            ;SoundPlay "*-1"
            SoundBeep 880, 150
        }
        ControlEnableALL(Gmain, true)
    }
    return
}

/**************************************************
 * #### ButtonHelp: show the help text in a modeless dialog
 *
 * * NOTE save Help text as UTF-16 w/ BOM (Byte Order Mark)
 */
ButtonHelp(*)
{
    global
    local s_usage, msg, e

    ToolTip()
    try {
        s_Usage := FileRead(g_docs_path)
    }
    Catch Error as e {
        msg := "Error loading help file `n'" g_docs_path "' `n" e.Message
        MsgBox(msg, S_TITLE, "icon!")
        return
    }
    if (StrLen(s_Usage) < 24) {
        ;throw Error("Unknown error", -1)
        return
    }
    s_Usage := StrReplace(s_Usage, "%version%", S_VERSION)

    SetTitleMatchMode(3) ; exact

    local x1, y1, w1, h1
    WinGetPos(&x1, &y1, &w1, &h1, "ahk_id " g_winID)

    HlpWnd := Gui()
    HlpWnd.Opt("+OwnDialogs +Owner -SysMenu -DPIScale")

    sFont      := IniRead(g_lang_path, "general", "Helptext-font", "")
    nFontSize  := IniRead(g_lang_path, "general", "Helptext-fontsize", "10")
    nFontSize2 := Min(Max(8, Round((CStringUtils.ValueOf(nFontSize) / 9.0) * g_nFontSize)), 14)
    HlpWnd.SetFont("s" . nFontSize2, sFont)

    local scx, w2, h2
    scx := (nFontSize2 / 9.0)
    w2  := Round(scx * 540) ; sets width of the text box and the entire window
    h2  := Round(scx * 290)

    HelpText := HlpWnd.Add("Edit"
                , "x16 y20 w" w2 " h" h2 " r18 t8 ReadOnly vHelpText")

    local x2, w2, cap
    x2 := w2 - 80
    cap := sT("gui", "btn_OK", "/OK")
    btn_OK := HlpWnd.Add("Button"
                , "x" x2 " y+10 w100 h30 Default", cap)
    btn_OK.OnEvent("Click", ButtonHelpOK.Bind("Normal"))

    Help_Title := S_TITLE " - "  sT("gui", "Help", "/Help")
    HlpWnd.Title := Help_Title

    x2 := x1 + w1 + 6
    w2 := w2 + Round(scx * 40)
    HlpWnd.Show("x" x2 " y" y1 " w" w2)

    ; set text AFTER show to avoid selecting all
    HelpText.Text := s_Usage

    WinWaitActive(Help_Title, , 1)
    SetTitleMatchMode(2) ; contains
    return
}

/**************************************************
 * #### ButtonHelpOK: close the Help subwindow
 */
ButtonHelpOK(*)
{
    global
    ToolTip()
    HlpWnd.Destroy()
    return
}

/**************************************************
 * #### FolderChanged: update UI when certain input fields have changed
 */
FolderChanged(ctl, *)
{
    static busy := false
    if (busy)
        return
    busy := true
    FoldersListUpdate(ctl.isOut)
    GuiSubmitAndGoTest()
    busy := false
    return
}

/**************************************************
 */
FoldersDataUpdate(s_Folder, isOut)
{
    global

    ; one-and-only-one trailing backslash
    s_Folder := RTrim(s_Folder, "\") "\"

    ; if new item is already in the list, remove it:
    local ar := (isOut ? g_arOutFolders : g_arSrcFolders)
    local k, v
    for k, v in ar {
        v := RTrim(v, "\") "\"
        if (v == s_Folder)
            ar.RemoveAt(k)
    }

    ; add new item @ head of list:
    ar.InsertAt(1, s_Folder)
    return ar
}

/**************************************************
 * #### FoldersListUpdate: update underlying data if new folder has been added
 ** (maintain MRU list of recent items w/ newest item at top)
 */
FoldersListUpdate(isOut)
{
    global
    static busy := false
    if (busy)
        return
    busy := true

    Gmain.Submit(0)
    local cbo := Gmain[(isOut ? "vOutFolder" : "vSrcFolder")]
    local s_Folder := ""
    try {
        if (StrLen(g_tmp_folder)) {
            s_Folder := g_tmp_folder ; from ButtonFolder()
            g_tmp_folder := ""
        }
        else {
            s_Folder := cbo.Text
        }

        if (!Strlen(DirExist(s_Folder))) {
            busy := false
            return
        }

        ; if new item is already in the list, remove it;
        ; add new item @ head of list:
        local ar := FoldersDataUpdate(s_Folder, isOut)

        ; update the control
        cbo.Delete()
        cbo.Add(ar)
        cbo.Choose(1)
    }
    busy := false
    return
}

/**************************************************
 * #### GuiClose: called when GUI closes
 */
GuiClose()
{
    ToolTip()
    ExitApp()
    return
}

/**************************************************
 * #### GuiDropFiles: called when files are dragged onto the GUI window
 */
GuiDropFiles(_GuiObj, _GuiCtrlObj, FileArray, _X, _Y)
{
    global
    local i, s
    for i, s in FileArray
    {
        if (StrLen(DirExist(s)))
        {
            g_tmp_folder := s
            FoldersListUpdate(false)
            break
        }
    }
    GuiSubmitAndGoTest()
    return
}

/**************************************************
 * #### GuiEscape: called when [Escape] key is pressed
 */
GuiEscape:
{
    ToolTip()
    return
}

;/////////////////////////////////////////////////
;; UTILITIES
;/////////////////////////////////////////////////

/**************************************************
 * #### GuiSubmitAndGoTest: update UI when certain input fields have changed
 */
GuiSubmitAndGoTest()
{
    global
    local G := Gmain
    local oSaved     := G.Submit(0)
    local vSrcFolder := oSaved.vSrcFolder
    local vOutFolder := oSaved.vOutFolder

    local s_ErrMsg := GoTests(vSrcFolder, vOutFolder)
    if (StrLen(s_ErrMsg)) {

        ShowStatus(s_ErrMsg)
        G["Btn_Go"].Enabled := false
        return
    }
    G["Btn_Go"].Enabled := true

    ; in case path overflows available space, show a tooltip:
    G["vSrcFolder"].ToolTip := vSrcFolder
    G["vOutFolder"].ToolTip := vOutFolder

    ; check for non-fatal error(s):
    ; (none)

    ss_msg := sT("status", "ready", "/Ready")
    ShowStatus(ss_msg, ICON_CHECK)
    return
}

/**************************************************
 * #### GoTests: determine if all input fields are ready for execution
 *
 * * return a blank string if ready,
 *   else return a diagnostic message
 */
GoTests(sSrcFolder, sOutFolder)
{
    local msg
    if (!StrLen(FileExist(sSrcFolder))) {
        msg := sT("status", "bad_Folder", "/Bad Folder")
        return msg
    }
    if (!StrLen(FileExist(sOutFolder))) {
        msg := sT("status", "bad_Folder", "/Bad Folder")
        return msg
    }
    ; success
    return ""
}

/**************************************************
 * #### ShowStatus: update Status Bar
 *
 * @param {Integer} icon - override the default Status Bar icon (index into Shell32.dll)
 */
ShowStatus(msg, icon:=0)
{
    global
    local SB := GMain["Status1"]

    if (!StrLen(msg)) {

        g_StatText := sT("status", "ready", "")
        g_StatIcon := (icon) ? icon : ICON_CHECK

        SB.SetIcon("Shell32.dll", g_StatIcon, 1)
        SB.SetText(" " g_StatText, 1, 0)
    }
    else {
        g_StatText := msg
        g_StatIcon := (icon) ? icon : ICON_CAUTION

        SB.SetIcon("Shell32.dll", g_StatIcon, 1)
        SB.SetText(" " g_StatText, 1, 0)
    }
    return
}

; (end)
