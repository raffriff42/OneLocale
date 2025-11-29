; IniFiles.ahk
;;INI file & misc. utilities

#Requires AutoHotkey v2.0

;************************************************
; Credits - I believe that unless otherwise attributed,
;  this AutoHotkey code is original
;  (other than sample code from the documentation)
;************************************************

;************************************************
; This code is free software; you can redistribute it and/or
; modify it under the terms of the GNU Lesser General Public
; License as published by the Free Software Foundation; either
; version 2.1 of the License, or (at your option) any later version.
;
; This library is distributed in the hope that it will be useful,
; but WITHOUT ANY WARRANTY; without even the implied warranty of
; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
; Lesser General Public License for more details.
;************************************************

;; (Table of Contents)
;   IniReadIgnoreCmt()
;   IniReadSection()
;   IniWriter()
;   IniWriteIfChanged()
;   IniWriteSection()
;   IniWriteSectionIfChanged()
;   IniFileDupeCheck()
;   IniLoadPosition()
;   IniSavePosition()
;   EnsureWindowIsOnScreen()
;   Assert()

/**************************************************
 * #### IniReadIgnoreCmt: IniRead but ignores inline comments
 *
 * - a 'comment' is everything after first semicolon [ ; ]
 * - escaped semicolons [ `; ] in values are supported
 *
 * @param {String} sPath - full path of .INI file
 * @param {String} sSection - section name within .INI file; the heading that appears
 *        in square brackets (do not include the brackets)
 * @param {String} sKey - the key name in the .ini file
 * @param {String} sDefault - value to return in case of error; default="ERROR"
 */
IniReadIgnoreCmt(sPath, sSection, sKey, sDefault:="ERROR")
{
    local vv
    vv := IniRead(sPath, sSection, sKey, sDefault)

    vv := StrReplace(vv, "``;", "`v")
    vv := StrSplit(vv, ";", " ")[1]
    vv := StrReplace(vv, "`v", ";")
    return vv
}

/**************************************************
 * #### IniReadSection: read entire section
 *
 * @param {String} sPath - full path of .INI file
 *
 * @param {String} sSection - section name within .INI file; the heading
 *    that appears in square brackets (do not include the brackets)
 *
 * @param {String} sDefault - value to return in case of error; default="ERROR"
 * <!--
 * @version 2024-08-05 fix `sDefault` support
 * -->
 */
IniReadSection(sPath, sSection, sDefault:="ERROR")
{
    local vv
    vv := IniRead(sPath, sSection, , sDefault)
    if (!StrLen(vv))
        vv := sDefault
    return vv
}

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
IniWriter(sPath, sSection, sKey, sValue)
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
 * #### IniWriteIfChanged: write data to .INI only if data has changed
 *
 * - avoids needless file writing
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
 */
IniWriteIfChanged(sPath, sSection, sKey, sValue)
{
    local ini_value
    ini_value := IniRead(sPath, sSection, sKey)
    if (sValue != ini_value)
        IniWriter(sPath, sSection, sKey, sValue)
    return true
}

/**************************************************
 * #### IniWriteSection: write entire section
 *
 * @param {String} sPath - full path of .INI file;
 * if it does not exist, it will be created
 *
 * @param {String} sSection - section name within .INI file;
 * the heading that appears in square brackets (do not include the brackets)
 *
 * @param {String} sValue - value to be written
 */
IniWriteSection(sPath, sSection, sValue)
{
    try {
        IniDelete sPath, sSection
        Sleep(100)
        IniWrite sValue, sPath, sSection
    }
    return true
}

/**************************************************
 * #### IniWriteSectionIfChanged: write section only if data has changed
 *
 * - avoids needless file writing
 *
 * @param {String} sPath - full path of .INI file;
 * if it does not exist, it will be created
 *
 * @param {String} sSection - section name within .INI file;
 * the heading that appears in square brackets (do not include the brackets)
 *
 * @param {String} sValue - value to be written
 */
IniWriteSectionIfChanged(sPath, sSection, sValue)
{
    local ini_value
    ini_value := IniReadSection(sPath, sSection)
    if (sValue != ini_value)
        IniWriteSection(sPath, sSection, sValue)
    return true
}

/**************************************************
 * #### IniFileDupeCheck: check for duplicate sections & keys in .INI file
 *
 * - Check for duplicate section names
 * - Check for duplicate keys within each section
 * - Note that AHK's (and Windows') behavior in the face of duplicate entries
 *   is to accept the FIRST section or key as the file is read.
 * - Duplicates should be removed to avoid confusion
 *     e.g. "Why isn't my .INI edit having any effect on the script?")
 *
 * @param {String} ini_path - the .INI file path
 *
 * @return {String} empty string if file is good; newline + error message if duplicate found
 * <!--
 * @version 2025-09-21
 * -->
 */
IniFileDupeCheck(ini_path)
{
    local sSections, arSections, mapSections
    local k, v, kk, vv
    local sKeys, arKeys, mapKeys

    ; Check for duplicate section names
    sSections   := IniRead(ini_path)
    arSections  := StrSplit(sSections, "`n", "`r")
    mapSections := Map()
    for k, v in arSections
    {
        if (mapSections.Has(v)) {
            return ini_path ":`nduplicate section '[" v "]'"
        }
        mapSections[v] := 1
    }

    ; Check for duplicate keys within each section
    for k, v in mapSections
    {
        ; for each `key = value` line, trim all to the right of `=`
        sKeys   := IniRead(ini_path, k)
        arKeys  := StrSplit(sKeys, "`n", " `t`r")
        for kk, vv in arKeys
        {
            vv := StrSplit(vv, "=", " `t", 2)[1]
            arKeys[kk] := vv
        }

        mapKeys := Map()
        for kk, vv in arKeys
        {
            if (mapKeys.Has(vv)) {
                return ini_path ":`nduplicate key '" vv "' in section '[" k "]'"
            }
            mapKeys[vv] := 1
        }
    }
    return ""
}

/**************************************************
 * #### IniLoadPosition: load window position from .INI file
 *
 * - call after Gui.Show (suggest Showing off screen before calling this function)
 *
 * @param {String} sPath - full path of .INI file
 *
 * @param {String} sSection - section name within .INI file
 *
 * @param {String} sTitle - see AHK docs `WinTitle`
 *
 * @param {Boolean} loadSize - if true, get width & height; default false
 *
 * @param {Boolean} loadState - if true, get minimized/maximized state; default false
 * <!--
 * @version 2024-08-03 simple implementation
 * @version 2024-08-18 calls EnsureWindowIsOnScreen()
 * -->
 */
IniLoadPosition(sPath, sSection, sTitle, loadSize:=0, loadState:=0)
{
    local win_left, win_top, win_wid, win_hgt
    local ini_left, ini_top, ini_wid, ini_hgt
    local win_state, ini_state
    Assert(WinExist(sTitle), "IniLoadPosition: bad `sTitle`: '" sTitle "'")

    WinGetPos &win_left, &win_top, &win_wid, &win_hgt, sTitle
    ini_left := Round(IniRead(sPath, sSection, "pos_left", win_left))
    ini_top  := Round(IniRead(sPath, sSection, "pos_top" , win_top ))
    ini_wid  := Round(IniRead(sPath, sSection, "pos_wid" , win_wid ))
    ini_hgt  := Round(IniRead(sPath, sSection, "pos_hgt" , win_hgt ))
    EnsureWindowIsOnScreen(&ini_left, &ini_top, ini_wid, ini_hgt)

    if (!loadSize) {
        WinMove ini_left, ini_top, , , sTitle
    }
    else {
        ini_wid := (ini_wid >= 64 ? ini_wid : win_wid)
        ini_hgt := (ini_hgt >= 64 ? ini_hgt : win_hgt)
        WinMove ini_left, ini_top, ini_wid, ini_hgt, sTitle
    }

    if (loadState) {
        win_state := WinGetMinMax(sTitle)
        ini_state := Round(IniRead(sPath, sSection, "win_state", win_state))

        if (win_state != ini_state) {
            if (ini_state < 0)
                WinMinimize sTitle
            else if (ini_state > 0)
                WinMaximize sTitle
            else
                WinRestore sTitle
        }
    }
    return
}

/**************************************************
 * #### IniSavePosition: save window position to .INI file
 *
 * - call from GuiClose
 *
 * @param {String} sPath - full path of .INI file;
 * if it does not exist, it will be created
 *
 * @param {String} sSection - section name within .INI file
 *
 * @param {String} sTitle - see AHK docs `WinTitle`
 *
 * @param {Boolean} saveSize - if true, save width & height; default false
 *
 * @param {Boolean} saveState - if true, save minimized/maximized state; default false
 * <!--
 * @version 2024-08-03
 * @version 2024-09-05 don`t write to .INI if position has not changed
 * @version 2024-09-15 utilize IniWriteIfChanged()
 * -->
 */
IniSavePosition(sPath, sSection, sTitle, saveSize:=0, saveState:=0)
{
    local win_left, win_top, win_wid, win_hgt
    local win_state
    Assert(WinExist(sTitle), "IniSavePosition: bad `sTitle`: '" sTitle "'")
    WinGetPos &win_left, &win_top, &win_wid, &win_hgt, sTitle

    IniWriteIfChanged(sPath, sSection, "pos_left", win_left)
    IniWriteIfChanged(sPath, sSection, "pos_top" , win_top)

    if (saveSize) {
        IniWriteIfChanged(sPath, sSection, "pos_wid", win_wid)
        IniWriteIfChanged(sPath, sSection, "pos_hgt", win_hgt)
    }

    if (saveState) {
        win_state := WinGetMinMax(sTitle)
        IniWriteIfChanged(sPath, sSection, "win_state", win_state)
    }
    return
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
EnsureWindowIsOnScreen(&winX, &winY, winWid:=300, winHgt:=300
                    , &win2X:=0, &win2Y:=0, win2Wid:=300, win2Hgt:=300)
{
    local pRECT, hmon, pINFO, scrL, scrT, scrR, scrB

    ;HMONITOR MonitorFromRect(
    ;  [in] LPCRECT lprc,
    ;  [in] DWORD   dwFlags
    ;);
    ;BOOL GetMonitorInfoA(
    ;  [in]  HMONITOR      hMonitor,
    ;  [out] LPMONITORINFO lpmi
    ;);
    ;MONITORINFO {
    ;  TYPE    NAME       SIZE   OFFSET
    ;  DWORD    cbSize;      4            ; size of the structure, in bytes
    ;  RECT     rcMonitor;  16      4     ; RECT display monitor , virtual-screen coords
    ;  RECT     rcWork;     16     20     ; RECT work area       , virtual-screen coords
    ;  DWORD    dwFlags;     4     36     ; if nonzero, this monitor is the primary
    ;} // size == 40

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
    if (hmon)
    {
        pINFO := Buffer(40, 0) ;VarSetCapacity
        NumPut("Int", 40, pINFO, 0)
        if (DllCall("GetMonitorInfoA"
                , "Ptr", hmon
                , "Ptr", pINFO.Ptr
                , "Int"))
        {
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

/***************************************
 * #### Assert: if argument is false, show an error message
 *
 * - on MsgBox confirmation, stop execution
 *
 * @param {Boolean} bTest - value to test
 * @param {String}  msg   - message to display if bTest==false
 * @param {Boolean} isFatal - if true (default), force quit; else ask user
 */
Assert(bTest, msg, isFatal:=true)
{
    if (!bTest) {
        ;ListLines
        ;ListVars
        bTest := bTest ; BREAKPOINT

        if (isFatal) {
            MsgBox("Assert failed:`n" msg "`nQuitting", , "iconx")
            ExitApp 1
        }
        if ("Yes" == MsgBox("Assert failed:`n" msg "`nAbort?", , "y/n icon?"))
            ExitApp 1
    }
    return
}

; (end)
