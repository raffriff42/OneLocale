;*****************************************************************
; OneLocale_Demo.ahk
;; OneLocale test & demo
;
;@version 1.1  2023-12-13
;@version 1.2  2024-01-14 support updated OneLocale
;@version 1.3  2025-09-05 reorganized #Includes
;@version 1.3  2025-09-18 support updated OneLocale
;@version 1.4  2025-11-25 support updated OneLocale, misc. tweaks
;*****************************************************************
S_TITLE   := "OneLocale_Demo"
S_VERSION := "1.4"
;@Ahk2Exe-SetVersion 1.4.0.3
;@Ahk2Exe-SetName OneLocale_Demo
;@Ahk2Exe-SetDescription OneLocale test & demo
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
#NoTrayIcon

#Warn All, MsgBox
;#Warn LocalSameAsGlobal, Off
;#Warn Unreachable, Off

;; INCLUDES

#Include "lib\OneLocale.ahk"
#Include "lib\OneLocale_Dialog.ahk"
#Include "lib\OneLocale_Utils.ahk"
#Include "lib\ToolTips.ahk"

;; INIT

;//////////////////////////////////////////////////////////////////
; Optional 'Baked' Language(s) from Code instead of File(s):
; initialize g_lang_map (Map containing language data)
#Include "include\OneLocale_Demo-[en].ahk"
#Include "include\OneLocale_Demo-[de].ahk"

; OneLocale_Init:
; - Determine .INI path and verify it exists.
; - Get a Language ID from .INI file entry or `A_Language`
; - The .LANG file folder and the 'baked' (hard coded) data are searched for the
;     best or most compatible match for the given language ID.
; - Return an Object with named properties.
;   - Important properties are
;       `.success`, `.errmsg`, `.langID` and `.fallback`
;   - If baked data was selected, `.langMap` will be true and `.langPath` will be `:map:`
;   - If suitable language doesn't exist, the fallback language will be loaded;
;       in that case, `.fallback` will be true.
;   - As long as `.success` is true, the application can continue; if it's false,
;       it has a fatal error and must quit.
; - Set the globals listed below.
;
if (1) {
    ; (normal ini)
    locale_info := OneLocale_Init()
}
else {
    ; (init for case of alternate .LANG folder and commented baked code #Include)
    locale_info := OneLocale_Init({ sLangFolder:"lang_load" })
}
if (!locale_info.success) {
    MsgBox(locale_info.errmsg, S_TITLE, "icon!")
    ExitApp
}
; (these globals are set by OneLocale_Init)
;g_ini_path   == locale_info.iniPath
;g_lang_path  == locale_info.langPath
;g_lang_id    == locale_info.langID
;g_docs_path  == locale_info.docsPath
;//////////////////////////////////////////////////////////////////

if (!A_IsCompiled) {
    icon_path := A_ScriptDir "\images\OneLocale.ico"
    TraySetIcon icon_path
}

;; GUI

Gmain := BuildGui()
return

BuildGui()
{
    global S_TITLE, S_VERSION, g_title

    ;//////////////////////////////////////////////////////////////////
    ; sT(sSection, sKey, sDefault:="ERROR", args:="", ...)
    ; retrieve a message from a language-specific File or Map
    g_title := sT("gui", "title", "/%title% - version %ver%", {title:S_TITLE, ver:S_VERSION})
    ;..............^section..^key..^default.....................^args
    ;//////////////////////////////////////////////////////////////////

    local G := Gui(, g_title)
    G.Opt("-MaximizeBox -MinimizeBox -DPIScale")

    ;// 'cap' (caption) is a reusable variable
    local cap := sT("gui", "ctlText1"
                    , "/Enter today's date:")
    local ctl := G.Add("Text", , cap)

    ctl := G.Add("Edit", "w200 vsEdit1")
    ctl.ToolTip := sT("tooltips", "ctlEdit1"
            , "/This is a tooltip for the control \n whose name is ctlEdit1.")
    ctl.Value := FormatExDate(A_Now, , locale_info.langID)

    local arList := [ sT("list", "Red"  , "/Red")
                    , sT("list", "Green", "/Green")
                    , sT("list", "Blue" , "/Blue") ]
    ctl := G.Add("ListBox", "w200 choose1 vChoose1 section", arList)
    ctl.ToolTip := sT("tooltips", "ctlList1"
            , "/Choose a color from the list.")

    ctl := G.Add("CheckBox", "xs y100 vChk1"
            , sT("gui", "ctlChk1", "/&Option 1"))
    ctl.ToolTip := sT("tooltips", "ctlChk1"
            , "/This option does nothing.")

    cap := sT("multiline", "[section]"
            , "/Multiline \n text")
    ctl := G.Add("Edit", "w300 xs r8 t4 vsQuote", cap)
    ctl.ToolTip := sT("tooltips", "multiline"
            , "/Multiline text.")

    cap := sT("gui", "btn_Browse"
            , "/Browse...")
    ctl := G.Add("Button", "w60 Section vBtnBrowse", cap)
    ctl.OnEvent("Click", BtnBrowse)
    ctl.ToolTip := sT("tooltips", "btn_Browse"
            , "/Browse for a file.")

    cap := sT("gui", "btn_Help"
            , "/Help...")
    ctl := G.Add("Button", "w60 xs+120 ys", cap)
    ctl.OnEvent("Click", BtnHelp)
    ctl.ToolTip := sT("tooltips", "btn_Help"
            , "/View Readme in browser.")

    cap := sT("gui", "btn_Quit"
            , "/Quit")
    ctl := G.Add("Button", "w60 xs+240 ys", cap)
    ctl.OnEvent("Click", BtnQuit)

    FileMenu := Menu()
    G.mnu_lang := sT("menu", "language" , "/&Language...\tCtrl+L")
    FileMenu.Add(G.mnu_lang, MnuHandler)
    G.mnu_test := sT("menu", "file_test", "/&Error test\tCtrl+E")
    FileMenu.Add(G.mnu_test, MnuHandler)
    G.mnu_quit := sT("menu", "file_quit", "/&Quit\tCtrl+Q")
    FileMenu.Add ; ----- separator
    FileMenu.Add(G.mnu_quit, MnuHandler)

    HelpMenu := Menu()
    G.mnu_read := sT("menu", "help_read", "/&About...`tF1")
    HelpMenu.Add(G.mnu_read, MnuHandler)

    MyMenuBar := MenuBar()
    G.mnu_file := sT("menu", "mnu_file" , "/&File")
    MyMenuBar.Add(G.mnu_file, FileMenu)
    G.mnu_help := sT("menu", "mnu_help" , "/&Help")
    MyMenuBar.Add(G.mnu_help, HelpMenu)

    G.MenuBar := MyMenuBar

    G.Show("Center")
    G["Choose1"].Focus()

    ; button with icon (works in all languages)
    ; added LAST so other controls' ClassNNs are not affected

    ctl := G.Add("Button", "w24 h24 x244 y60 vBtnDialog +0x40", "") ; 0x40 == BS_ICON
    ctl.OnEvent("Click", (ctrl, *) => (OneLocaleDlg_Dialog(g_Title, locale_info)))
    ctl.ToolTip := sT("tooltips", "dialog"
            , "/Choose language.")

    ; set the button's icon (icon is destroyed @ Gui_Close)
    G.hImg1 := SetCtlGraphic(G.HWnd, ctl.ClassNN
            , "images\OneLocale-ChooseLang-X-globe_x016.ico"
            , 16, 16)

    G.OnEvent("Close" , Gui_Close)
    G.OnEvent("Escape", Gui_Close)

    OnMessage(0x200, On_WM_MOUSEMOVE)
    OnMessage(0x2A3, On_WM_MOUSELEAVE)
    return G

} ; /BuildGui

;; EVENTS

/**************************************************
 */
MnuHandler(ItemName, ItemPos, MenuObject)
{
    global Gmain, locale_info
    switch (ItemName)
    {
    case Gmain.mnu_lang:
            ;////////////////////////////////////////////////////
            OneLocaleDlg_Dialog(g_Title, locale_info)
            ; calls OneLocaleDlg_Result() when complete
            ;////////////////////////////////////////////////////
    case Gmain.mnu_test:
            BtnError()
    case Gmain.mnu_read:
            BtnHelp()
    case Gmain.mnu_quit:
            BtnQuit()
    default:
            MsgBox("MnuHandler: unknown item '" ItemName "'")
    }
    return
}

/**************************************************
 * #### browse for a file
 */
BtnBrowse(*)
{
    global Gmain, g_title
    Gmain["Choose1"].Focus() ; move focus off the Browse button after use

    local sTitle  := sT("dialog_browse", "title", "/Select a text file")
    local sFilter := sT("dialog_browse", "filter", "/Text Files") " (*.txt`; *.ahk)"
    local sStart  := EnvGet("userprofile") "\Documents"

    local fs1 := FileSelect("3", sStart, sTitle, sFilter)
    if (StrLen(FileExist(fs1)))
    {
        MsgBox("Success, '" fs1 "' exists.", S_TITLE)
    }
    return
}

/**************************************************
 */
BtnError(*)
{
    local msg

    ;//////////////////////////////////////////////////////////////////
    ; from sT() doc comments:
    ; if 'section'=="errors", pass the 'key' verbatim to output as a prefix.
    ; This prefix allows tech support to identify the error by a string that
    ; does not change, regardless of the user's language.
    ; (very useful if the .lang file was independently user-created)
    ;//////////////////////////////////////////////////////////////////

    msg := sT("errors", "bad_path", , {path:"C:\no\such\file.null"})
    MsgBox msg, S_TITLE, "icon!"
    return
}

/**************************************************
 */
BtnHelp(*)
{
    global Gmain
    Gmain["Choose1"].Focus() ; move focus off the Help button after use
    local cmd := "open https://onelocale.dev/"
    Run(cmd)
    return
}

/**************************************************
 */
BtnQuit(*)
{
    Gmain.Destroy()
    ExitApp
}

/**************************************************
 */
Gui_Close(*)
{
    global Gmain
    try DllCall("DestroyIcon", "UInt", Gmain.hImg1)
    Gmain.Destroy()
    ExitApp
}

;; FUNCTIONS

/**********************************************
 * #### OneLocaleDlg_Result: handle result of OneLocaleDlg_Dialog()
 */
OneLocaleDlg_Result()
{
    ;//////////////////////////////////////////////////////////////////
    ; this is a callback method written by you, the developer
    ;//////////////////////////////////////////////////////////////////
    global Gmain, S_TITLE
    global OneLocaleDlg
    local msg := OneLocaleDlg.StatusMessage

    Gmain["Choose1"].Focus() ; move focus off the Choose button after use

    if (msg == "Cancel") ;// user Canceled
        return
    if (InStr(msg, "Language=")) ;// user switched language
    {
        SaveAppState() ;// you write this too
        Reload
        ;////////////////////////////////////////////////////
        ; the alternative to Reloading your app
        ; is reloading all visible Gui strings
        ;////////////////////////////////////////////////////
        return
    }
    MsgBox(msg, S_TITLE, "icon!") ; error
    return
}

/**********************************************
 * #### LocaleReload:
 */
LocaleReload()
{
    return
}

/**********************************************
 * #### SaveAppState: save state to .INI before closing down
 */
SaveAppState()
{
    ;////////////////////////////////////////////////////
    ; nothing to do here, in this demo app
    ;////////////////////////////////////////////////////
    return
}

/**************************************************
 * #### SetCtlGraphic: show a graphic image on a control such as a Button
 *
 * @param {Integer} HWnd     - Gui window handle
 * @param {String}  ClassNN  - control name in Window Spy
 * @param {String}  ImgPath  - path to the image to be displayed
 * @param {Integer} Wid      - image width  (default 32)
 * @param {Integer} Hgt      - image height (default 32)
 *
 * @return image handle - use it with DllCall("DestroyIcon", ...) when finished
 * Source:
 *   https://www.autohotkey.com/board/topic/8296-images-on-buttons/
 */
SetCtlGraphic(HWnd, ClassNN, ImgPath, Wid:=32, Hgt:=32, IsIcon:=true)
{
    ; load the image from the file and retrieve the image handle
    local hImg := DllCall("LoadImage"
                    , "UInt", 0
                    , "Str" , ImgPath
                    , "UInt", 1
                    , "Int" , Wid
                    , "Int" , Hgt
                    , "UInt", 0x10 | 0x20)  ; LR_LOADFROMFILE | LR_LOADTRANSPARENT

    ; assign the image to the button (0xF7 = BM_SETIMAGE)
    SendMessage(0xF7, 1, hImg, ClassNN, "ahk_id " HWnd)

    ; return the handle to the image
    return hImg
}

; (end)
