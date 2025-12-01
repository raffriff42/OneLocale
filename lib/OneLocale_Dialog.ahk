; OneLocale_Dialog.ahk

#Requires AutoHotkey v2.0

;;Requirements
#Include "OneLocale.ahk"

;; (Table of Contents)
;  OneLocaleDlg_Dialog(sParentWinTitle, optional_args)
;  OneLocaleDlg_ListChanged(*)
;  OneLocaleDlg_OK(*)
;  OneLocaleDlg_Cancel(*)
;  class CLocaleDlg {
;      IniWriter()
;      EnsureWindowIsOnScreen()
;      FilenameRegexEscape(sName)
;      ListLangFiles(sLangDir, sName, sTemplate, mapPriority)
;  }
;  Callback // user-defined, but template is supplied
;      OneLocaleDlg_Result()

;@ahk-neko-ignore 125 line 'function too big'
/**********************************************
 * #### OneLocaleDlg_Dialog - show a Language Chooser dialog box
 *
 * - Scans abvailable languages
 * - Fills a Dropdown ListBox
 * - Shows the dialog
 * - User selects a language
 * - Calls user-defined callback `OneLocaleDlg_Result()` (see example below)
 *
 * @param {String} sParentWinTitle - the parent window's
 *     [Title](https://www.autohotkey.com/docs/v2/misc/WinTitle.htm)
 *
 * @param {Object} optional_args - a set of named values, listed below.
 * You only need to supply the values which are non-default;
 *
 * __NOTE__ if you called {@link OneLocale_Init}, simply pass its returned object,
 *
 * - `sLangFolder` {String} default = "lang"
 *   - override the default .LANG file subdirectory
 *   - if `sLangFolder` is "" (empty), .LANG files go in script directory
 *
 * - `sName` {String} default = ""
 *   - base .INI and .LANG file name
 *   - if `sName` is empty (default), it's set to `A_ScriptName` without extension
 *
 * - `langID` {String} the current Language ID
 *   - An ISO 639-style Tag ('en', 'fr') _OR_
 *     A 4-hex-digit LCID ('0409', '000C') (with or without '0x' prefix)
 *     - If not empty or "(auto)", `langID` overrides any .INI file entry.
 *     - If there is no .INI entry and no `langID` argument, `A_Language` will be used for automatic
 *        language selection (provided a compatible language file has been installed)
 *   - `langID` sources, lowest to highest priotity:
 *      `A_Language`, .INI file, `optional_args`
 *   - if `langID` (wherever it came from) isn't a valid language ID, this routine fails.
 *
 * - `mapPriority` - {Boolean} determines whether Maps or Files have
 *    priority when a given Language is supported by both; if true (default),
 *    Maps have priority (does not affect dialog listbox sort order)
 *
 * @return nothing, but:
 *
 * - On success, the .INI file Language entry will be updated.
 * - Calls `OneLocaleDlg_Result()`, which you must write (see generic implementation below)
 * - Sets global `OneLocaleDlg.StatusMessage`.
 *
 *   - If something went wrong, `OneLocaleDlg.StatusMessage` will have an error message.
 *   - If user clicked Cancel, it will be "Cancel".
 *   - Else if user clicked OK, it will be "Language=" and the new language ID.
 *   - On success, the application must reload all language-specific
 *     strings. The easiest way to do that is to restart the application,
 *     reading the .INI file Language entry on startup.
 *
 * ##### Example call
 *
 * ```AutoHotkey
 * locale_info := OneLocale_Init()
 * . . .
 * MyGui := Gui()
 * . . .
 * ; (Menu Handler)
 * global locale_info, MyGui
 * OneLocaleDlg_Dialog(MyGui.Title, locale_info)
 * ```
 *
 * This calls `OneLocaleDlg_Result()` when complete; generic implementation below
 *
 * ```AutoHotkey
 * OneLocaleDlg_Result()
 * {
 *     global S_TITLE
 *     global OneLocaleDlg
 *     local msg := OneLocaleDlg.StatusMessage
 *     if (msg == "Cancel") ; user Canceled
 *         return
 *     if (InStr(msg, "Language=")) ; user switched language
 *     {
 *         ; update all sT() strings in the application
 *
 *         ; or save application state and Reload
 *         SaveAppState() ; (you write this)
 *         Reload
 *         return
 *     }
 *     MsgBox(msg, S_TITLE, "icon!") ; error
 *     return
 * }
 * ```
 * <!--
 * @version 2024-09-26
 * @version 2025-09-20 replaced long argument list with Object
 * @version 2025-10-03 put current language at the top of the list
 * @version 2025-10-23 `optional_args` : remove `noSubfolders`, add `sLangFolder`
 * @version 2025-11-03 use g_lang_map if it's available; optional_arg `mapPriority`
 * -->
 */
OneLocaleDlg_Dialog(sParentWinTitle, optional_args:="")
{
    global OneLocaleDlg  ; Gui object
        ;.parentWinTitle  ; parent window's WndTtitle
        ;.ini_path        ; .INI file location
        ;.lang_name       ; name of current language
        ;.arLangs         ; array of installed .LANG files
        ;.ctDDLangList    ; dropdown list
        ;.BtnOK           ; OK button
        ;.StatusMessage

    ;////////////////////////////////
    ; ARGS
    ;////////////////////////////////

    local sRootPath    := A_ScriptDir
    local sName        := SubStr(A_ScriptName, 1, -4)
    local sLangID      := ""
    local sLangFolder  := "lang"
    local mapPriority  := false

    if (IsSet(optional_args) && IsObject(optional_args))
    {
        local enn := optional_args
        if !(optional_args is Map)
            enn := optional_args.OwnProps()
        local sKey, sValue
        for sKey, sValue in enn
        {
            switch (sKey)
            {
                case "sName"         : sName       := sValue
                case "langID"        : sLangID     := sValue
                case "sLangFolder"   : sLangFolder := sValue
                case "mapPriority"   : mapPriority := sValue
                default:
            }
        }
    }

    ;////////////////////////////////
    ; INIT
    ;////////////////////////////////

    ; `sLangID` sources, lowest to highest priority:
    ;  `A_Language`, .INI file, `optional_args`

    local ini_path := sRootPath "\" sName ".ini"
    local sLangIDSource := "argument" ; forms part of error message
    if (!IsSet(sLangID) || sLangID=="(auto)")
        sLangID := ""

    if (!StrLen(sLangID)) {
        if (StrLen(FileExist(ini_path))) {
            sLangIDSource := sName ".ini"
            sLangID := IniRead(ini_path, "general", "Language", "")
        }
    }

    if (!StrLen(sLangID)) {
        sLangIDSource := "A_Language"
        sLangID := A_Language
    }

    local idType := CLocale.GetIDType(sLangID)
    if (!StrLen(idType)) {
        MsgBox("OneLocaleDlg_Dialog error: language ID '" sLangID "' not valid"
                    , A_ScriptName, "icon!")
        return
    }

    local info   := CLocale.GetLocaleInfoSet(sLangID)
    ; -> Object (`LCID`, `IsoTag`, `Name`, `Native`, `Parent`)
    if (!IsObject(info)) {
        MsgBox("OneLocaleDlg_Dialog error: language ID '" sLangID "' not valid"
                    , A_ScriptName, "icon!")
        return
    }

    sLangFolder := LTrim(sLangFolder, "\ ")
    if (StrLen(sLangFolder))
        sLangFolder := "\" sLangFolder
    sLangFolder := sRootPath sLangFolder

    local sTemplate := "/Name/-[/TAG/].lang"

    ; returns Array of Object {languageID:, languageName:, FullPath:}
    ;         for all .LANG files matching sTemplate,
    ;         and for all submaps of g_lang_data,
    ;         sorted by language name
    local arLangs := CLocaleDlg
        .ListLangFiles(sLangFolder, sName, sTemplate, mapPriority)

    local arList := [] ; dropdown list data
    local n, o
    for n, o in arLangs {
        ; put current language at the top of the list
        if (o.languageName == info["Name"])
            arList.InsertAt(1, o.languageName)
        else
            arList.Push(o.languageName)
    }

    ;////////////////////////////////
    ; GUI
    ;////////////////////////////////

    local hOwner := WinExist(sParentWinTitle)
    local sOpt   := "+OwnDialogs +Owner" hOwner " -SysMenu -DPIScale"
    local sTitle := sT("dialog_lang", "title", "/Change Language")

    OneLocaleDlg := Gui(sOpt, sTitle)
    local Gdlg := OneLocaleDlg

    if (!StrLen(idType))
    {
        Gdlg.StatusMessage := sT("errors", "OneLocaleDlg_lang_not_found"
            , "/'Language' entry '%LangID%' from %src% not valid"
            , {LangID:sLangID, src:sLangIDSource})
        OneLocaleDlg_Result()
        return
    }
    Gdlg.SetFont("s10", )
    Gdlg.parentWinTitle := sParentWinTitle
    Gdlg.StatusMessage := ""

    Gdlg.ini_path  := ini_path
    Gdlg.lang_name := info["Name"]
    Gdlg.arLangs   := arLangs

    ;; DROPDOWN

    local cap := sT("dialog_lang", "lbl_lang"
                    , "/User Interface Language:")
    local ctl := Gdlg.Add("Text", "x12 y14 r1", cap)

    ctl := Gdlg.Add("DropDownList"
        , "xp y+10 w300 vctDDLangList", arList)
    ctl.OnEvent("Change", OneLocaleDlg_ListChanged)
    ctl.ToolTip := sT("tooltips_dialog_lang", "lang_list"
        , "/Set User Interface Language")

    local k, v
    for k, v in arList {
        if (v == Gdlg.lang_name) {
            ctl.Choose(k)
            break
        }
    }

    ;; BUTTON(S)

    cap := sT("dialog_lang", "lbl_buttons"
        , "/App will restart if you change Language"
        . "\n(work in progress will be lost)")
    ctl := Gdlg.Add("Text", "x12 y+14", cap)

    local x1 := 12
    local x2 := 160
    cap := sT("dialog_lang", "btn_OK", "/OK")
    ctl := Gdlg.Add("Button"
        , "x" x1 " y+20 w100 -Wrap Section vBtnOK"
        , cap)
    ctl.OnEvent("Click", OneLocaleDlg_OK)
    ctl.Enabled := false

    cap := sT("dialog_lang", "btn_Cancel", "/Cancel")
    ctl := Gdlg.Add("Button"
        , "x" x2 " ys w100 -Wrap"
        , cap)
    ctl.OnEvent("Click", OneLocaleDlg_Cancel)

    ;; SHOW GUI

    ToolTip() ; close any current ToolTips

    ; position dialog box at an offset from main window,
    ; but keep it within screen boundaries
    WinGetPos &winX, &winY, &winWid, &winHgt, sParentWinTitle
    local win2X := winX + 120
    local win2Y := winY - 60
    local winX, winY, winWid, winHgt
    CLocaleDlg.EnsureWindowIsOnScreen(&winX, &winY, winWid, winHgt, &win2X, &win2Y)

    Gdlg.Show("x" win2X " y" win2Y)
    Gdlg.OnEvent("Escape", OneLocaleDlg_Cancel)
    WinWaitActive Gdlg.Title
    return
} ; /OneLocaleDlg_Dialog

/**********************************************
 * #### OneLocaleDlg_ListChanged - enable/disable OK button
 *
 * - called from OneLocaleDlg_Dialog
 */
OneLocaleDlg_ListChanged(*)
{
    global OneLocaleDlg
    local Gdlg := OneLocaleDlg
        ;.lang_name       ; name of current language
        ;.ctDDLangList    ; dropdown list
        ;.BtnOK           ; OK button

    Gdlg.Submit(false)

    ; newly selected language name
    local LangList := Gdlg["ctDDLangList"]
    local BtnOK    := Gdlg["BtnOK"]

    if (LangList.Text == Gdlg.lang_name)
        BtnOK.Enabled := false
    else
        BtnOK.Enabled := true
    return
}

/**********************************************
 * #### OneLocaleDlg_OK - if a new language selected, reload the Gui
 *
 * - called from OneLocaleDlg_Dialog
 */
OneLocaleDlg_OK(*)
{
    global OneLocaleDlg
    local Gdlg := OneLocaleDlg
        ;.ini_path        ; .INI file location
        ;.lang_name       ; name of current language
        ;.arLangs         ; array of installed .LANG files
        ;.ctDDLangList    ; dropdown list
        ;.StatusMessage

    Gdlg.Submit(false)

    local LangList := Gdlg["ctDDLangList"]
    if (LangList.Text == Gdlg.lang_name)
        return ; return to Dialog (should not occur as 'OK' button is disabled)

    local sID := ""
    local n, o
    for n, o in Gdlg.arLangs
    {
        ; o = {languageID:, languageName:, FullPath:}
        if (o.languageName == LangList.Text) {
            sID := o.languageID
            break
        }
    }

    if (!StrLen(sID)) {
        Gdlg.StatusMessage := sT("errors", "OneLocaleDlg_newname_not_found"
                        , "/Unexpected error: Language file not found for '%newname%'."
                        , {newname:LangList.Text})
        OneLocaleDlg_Result()
        return
    }

    local e
    try {
        CLocaleDlg.IniWriter(Gdlg.ini_path, "general", "Language", " " sID)
    }
    catch Error as e {
        MsgBox(sT("errors", "OneLocaleDlg_ini_write_error"
                    , "/Could not write to configuration file\n%path%"
                    , {path:Gdlg.ini_path})
                , Gdlg.Title, "icon!")
    }
    Gdlg.StatusMessage := "Language=" sID
    OneLocaleDlg_Result()
    Gdlg.Destroy
    return
}

/**************************************************
 * #### OneLocaleDlg_Cancel - close the Language dialog
 *
 * - called from OneLocaleDlg_Dialog
 */
OneLocaleDlg_Cancel(*)
{
    global OneLocaleDlg
    local Gdlg := OneLocaleDlg
        ;.parentWinTitle
        ;.StatusMessage

    ToolTip() ; close any current ToolTips
    WinActivate Gdlg.parentWinTitle
    Gdlg.StatusMessage := "Cancel"
    OneLocaleDlg_Result()
    Gdlg.Destroy
    return
}

;///////////////////////////////////////////////////////////////////////////////
class CLocaleDlg {

    /**************************************************
     * #### IniWriter: wrapper for IniWrite; catches any error
     *
     * @param {String} sPath - full path of .INI file;
     * if it does not exist, it will be created
     *
     * @param {String} sSection - section name within .INI file;
     * the heading that appears in square brackets (do not include the brackets)
     *
     * @param {String} sKey - key name in the .ini file
     *
     * @param {String} sValue - value to be written
     *
     * @return {Boolean} true on success, false if write failed
     */
    static IniWriter(sPath, sSection, sKey, sValue)
    {
        try {
            IniWrite sValue, sPath, sSection, sKey
            return true
        }
        catch {
            return false
        }
    }

    /**************************************************
     * #### EnsureWindowIsOnScreen: enforce basic screen constraints
     *
     * - modifies ByRef params `winX`, `winY`,  `win2X`, `win2Y`
     *
     * @param {Integer} winX    - [IN][OUT] left edge of window
     * @param {Integer} winY    - [IN][OUT] top  edge of window
     * @param {Integer} winWd   - [IN] width  of window
     * @param {Integer} winHgt  - [IN] height of window
     * @param {Integer} win2X   - [IN][OUT] left edge of optional child window
     * @param {Integer} win2Y   - [IN][OUT] top  edge of optional child window
     * @param {Integer} win2Wd  - [IN] width  of optional child window
     * @param {Integer} win2Hgt - [IN] height of optional child window
     *
     * - the optional child window will be kept in the same screen (monitor) as the parent,
     *   except sometimes when the parent overlaps multiple screens.
     * <!--
     * @version 2024-08-18 uses virtual desktop, which may not be contiguous
     * @version 2024-08-24 uses monitor nearest to input position
     * -->
      */
    static EnsureWindowIsOnScreen(&winX, &winY, winWid:=300, winHgt:=300
                        , &win2X:=0, &win2Y:=0, win2Wid:=300, win2Hgt:=300)
    {
        local pRECT, hmon, pINFO, scrL, scrT, scrR, scrB

        pRECT := Buffer(16, 0)
        NumPut("Int", Round(winX)          , pRECT,  0)
        NumPut("Int", Round(winY)          , pRECT,  4)
        NumPut("Int", Round(winX + winWid) , pRECT,  8)
        NumPut("Int", Round(winY + winHgt) , pRECT, 12)
        ; dwFlags
        static MONITOR_DEFAULTTONEAREST := 0x2

        hmon := DllCall("MonitorFromRect"
                , "Ptr" , pRECT.Ptr
                , "UInt", MONITOR_DEFAULTTONEAREST
                , "Int")
        if (hmon) {
            pINFO := Buffer(40, 0) ;VarSetCapacity
            NumPut("Int", 40, pINFO, 0)
            if (DllCall("GetMonitorInfoA"
                    , "Ptr", hmon
                    , "Ptr", pINFO.Ptr
                    , "Int")) {
                scrL := NumGet(pINFO,  0+20, "Int")
                scrT := NumGet(pINFO,  4+20, "Int")
                scrR := NumGet(pINFO,  8+20, "Int")
                scrB := NumGet(pINFO, 12+20, "Int")

                winX := Min(Max(scrL, winX), scrR - winWid)
                winY := Min(Max(scrT, winY), scrB - winHgt)

                win2X := Min(Max(scrL, win2X), scrR - win2Wid)
                win2Y := Min(Max(scrT, win2Y), scrB - win2Hgt)
                return ; success
            }
        }
        ; fallback - use entire virtual desktop
        scrL := SysGet(76) ; SM_XVIRTUALSCREEN
        scrT := SysGet(77) ; SM_YVIRTUALSCREEN
        scrW := SysGet(78) ; SM_CXVIRTUALSCREEN
        scrH := SysGet(79) ; SM_CYVIRTUALSCREEN

        winX := Min(Max(scrL, winX), scrL + scrW - winWid)
        winY := Min(Max(scrT, winY), scrT + scrH - winHgt)

        win2X := Min(Max(scrL, win2X), scrL + scrW - win2Wid)
        win2Y := Min(Max(scrT, win2Y), scrT + scrH - win2Hgt)
        return
    }

    /**********************************************
     * #### FilenameRegexEscape: escape all regexp special chars in a filename
     *
     * * `\`, `*`, `?`, `|` ignored as they are not filename chars
     *
     * @param {String} sName - a file name, with or without extension
     *
     * @return {String} `sName` with special characters escaped for use in regex
     */
    static FilenameRegexEscape(sName)
    {
        local s
        s := StrReplace(sName, "[", "\[" )
        s := StrReplace(s    , "]", "\]" )
        s := StrReplace(s    , "(", "[(]")
        s := StrReplace(s    , ")", "[)]")
        s := StrReplace(s    , ".", "[.]")
        s := StrReplace(s    , "-", "[-]")
        s := StrReplace(s    , " ", "[ ]")
        s := StrReplace(s    , "+", "[+]")
        s := StrReplace(s    , "{", "[{]")
        s := StrReplace(s    , "}", "[}]")
        s := StrReplace(s    , "^", "[^]")
        s := StrReplace(s    , "$", "[$]")
        return s
    } ; /FilenameRegexEscape

    /**********************************************
     * #### ListLangFiles - list languages with .LANG file support
     *
     * - Returns {Array} of {Object} `{languageID:, languageName:, FullPath:}`
     *   for all .LANG files matching `sTemplate`,
     *   and for all submaps of `g_lang_data`,
     *   sorted by language name;
     * - If a `languageID` is supported by a `Map` rather than a File,
     *   its `FullPath` is ":map:"
     *
     * @param {String} sLangDir - directory that holds the .LANG files
     *
     * @param {String} sName    - base file name
     *
     * @param {String} sTemplate - pattern that tests for .LANG file names
     *
     * - Default `/NAME/-[/TAG/].lang"
     *   - `/NAME/` is replaced with `sName`
     *   - `/TAG/`  is replaced with a Regex that matches any LCID or ISO language ID
     * - See {@link OneLocale_Init}
     * - See {@link OneLocaleDlg_Dialog}
     *
     * @param {Boolean} mapPriority - determines whether Maps or Files have
     *   priority when a given Language is supported by both; if true,
     *   Maps have priority
     *
     * @return {Array} of {Object} `{languageID:, languageName:, FullPath:}`
     *   for all matching .LANG maps and files
     *
     * - languageID {String} - an LCID or ISO tag identifying the language
     * - languageName {String} - the name of the Language in English
     * - FullPath {String}
     *   - if the Language is supported by a Map, this equals ":map:"
     *   - else, it is the full path to the .LANG file
     * - Sorted by language name
     * - Duplicates removed
     * - Map sources have priority, if so set by `mapPriority` argument
     * - Can be used to create a Gui dropdown list of installed languages
     * <!--
     * @version 2024-09-24
     * @version 2025-10-11 signature
     * @version 2025-11-02 Map support
     * -->
     */
    static ListLangFiles(sLangDir, sName, sTemplate, mapPriority)
    {
        if (!StrLen(sTemplate))
            sTemplate := "/Name/-[/TAG/].lang"

        local sPatt
        sPatt := StrReplace(sTemplate, "/Name/", sName)
        sPatt := CLocaleDlg.FilenameRegexEscape(sPatt)
        sPatt := "i)^" StrReplace(sPatt, "/TAG/"
                , "(" "([a-z]+)([-][a-z-]+)?" "|" "(0x)?([0-9A-F]{4,4})" ")")

        ; LIST FILES

        local mapFiles := Map()
        local langID, info
        Loop Files sLangDir "\*.*"
        {
            local s_fullname, m
            SplitPath A_LoopFileFullPath, &s_fullname
            if (RegExMatch(s_fullname, sPatt, &m))
            {
                langID := m[1]
                info := CLocale.GetLocaleInfoSet(langID)
                ; -> Object (`LCID`, `IsoTag`, `Name`, `Native`, `Parent`)
                if (IsObject(info))
                {
                    if (!mapFiles.Has(info["Name"]))
                    {
                        mapFiles[info["Name"]] := {languageID:langID
                                                 , languageName:info["Name"]
                                                 , FullPath:A_LoopFileFullPath}
                    }
                }
            }
        }

        ; LIST MAPS

        local mapMaps  := Map()
        local lang_map := 0
        if (IsSet(%"g_lang_map"%))
            lang_map := %"g_lang_map"%
        if (lang_map Is Map)
        {
            local kk, mm
            for kk, mm in lang_map
            {
                if ((mm Is Map) && mm.Has(":lang_id:"))
                {
                    langID := mm[":lang_id:"]
                    info := CLocale.GetLocaleInfoSet(langID)
                    ; -> Object (`LCID`, `IsoTag`, `Name`, `Native`, `Parent`)
                    if (IsObject(info))
                    {
                        mapMaps[info["Name"]] := {languageID:langID
                                                , languageName:info["Name"]
                                                , FullPath:":map;"}
                    }
                }
            }
        }

        ; MERGE

        local mapFirst, mapSecond
        if (mapPriority) {
            mapFirst  := mapMaps
            mapSecond := mapFiles
        }
        else {
            mapFirst  := mapFiles
            mapSecond := mapMaps
        }

        local mapMerge := Map()
        local sNames   := ""   ; newline-delimited list of language names
        for kk, mm in mapFirst
        {
            if (!mapMerge.Has(kk)) {
                mapMerge[kk] := mm
                sNames .= mm.languageName "`n"
            }
        }
        for kk, mm in mapSecond
        {
            if (!mapMerge.Has(kk)) {
                mapMerge[kk] := mm
                sNames .= mm.languageName "`n"
            }
        }

        ; SORT - copy to a new array sorted by Name

        local arOut := Array()
        local sSort := Sort(sNames)
        arSrt := StrSplit(sSort, "`n")
        local n, s
        for n, s in arSrt {
            if (StrLen(s))
                try arOut.Push(mapMerge[s])
        }
        return arOut
    } ; /ListLangFiles
} ; /CLocaleDlg

; (end)
