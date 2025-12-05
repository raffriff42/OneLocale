; FileUtils.ahk
;;file handling

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
;  class CFileUtils {
;      PathRelativeTo()
;      SplitPathFunc()
;      GetPathPart()
;      GetParent()
;      GetBaseName()
;      GetExtension()
;      DropExtension()
;      ----------------
;      GetAssociatedProgramPath(sExt)
;      GetPathFromCommand(sCommand)
;      GetTempFilePath(sFolder, sPrefix, sSuffix, sExt, nNumber)
;      ----------------
;      AddQuotes()
;      RemoveQuotes()
;      HasBadFilenameChar(s)
;      ILLEGAL_FILENAME_CHARS(option)
;      path_ellipsis(s, max_len)
;      path_ellipsis_pix(hWnd, s, max_wid)
;      PathIsDirectory(sPath)
;      PrefixLongPath(s)
;      RemoveIllegalFilenameChars(s)
;      ResolveShortcut(sPath)
;      ----------------
;      sOpenDlg(  hOwner, sFolder_FileName, nFlags, sTitle, sFilters)
;      sSaveAsDlg(hOwner, sFolder_FileName, nFlags, sTitle, sFilters)
;      _FileDlg ; 'private'
;      ----------------
;      static ReadOnly        := 1
;      static OverwritePrompt := 2
;      ; (etc)
;  }

;///////////////////////////////////////////////////////////////////////////////
class CFileUtils
{
    /**************************************************
     * #### PathRelativeTo: input relative path, return absolute path
     *
     * - cf. Windows' `PathRelativePathTo`, `GetFullPathName`
     *
     * @param {String} sRelative - the absolute or relative path
     * @param {String} sHome - the path `sRelative` may be relative to
     * @param {Boolean} isFolder - if true, assume `sRelative` is a folder path;
     *                  else (default) assume it's a file path
     *
     * @return {String} an absolute path (which may not exist)
     */
    static PathRelativeTo(sRelative, sHome, isFolder:=false)
    {
        local s_parent, s_drive
        SplitPath sHome, , &s_parent, , , &s_drive

        if (RegexMatch(sRelative, "i)^[a-z][:]")) {
            return sRelative ; absolute path
        }
        else if (RegexMatch(sRelative, "i)^\\\\[a-z0-9_?-]")) {
            return sRelative ; UNC path
        }
        else if (RegexMatch(sRelative, "^\\")) {
            return s_drive sRelative ; parent drive, root path
        }
        else if (isFolder) {
            return RTrim(sHome, "\") "\" sRelative ; relative path (directory)
        }
        else {
            return s_parent "\" sRelative ; relative path (file)
        }
    }

    /**********************************************
     * #### SplitPathFunc: like SplitPath, but returns a Object
     *
     * @param {String} sPath - file name or URL to be analyzed
     *
     * @return {Object} { Drive, Parent, Name, BaseName, Extension }
     * <!--
     * @version 2025-12-05 raffriff42
     * -->
     */
    static SplitPathFunc(sPath)
    {
        local s_name, s_parent, s_ext, s_basename, s_drive
        SplitPath sPath, &s_name, &s_parent, &s_ext, &s_basename, &s_drive

        return { Drive:s_drive, Parent:s_parent, BaseName:s_basename
                , Name:s_name, Extension:s_ext }
    }

    /**********************************************
     * #### GetPathPart: extract parts from file specification
     *
     * @param {String} sPath - file name or URL to be analyzed
     *
     * @param {String} sFormat - "dpnx" or some subset thereof
     *
     * - "d" Drive     - Drive letter (with ':') or server name
     * - "p" Path      - Path, excluding Drive; no final '\'
     * - "n" Name      - the file Name without extension
     * - "x" eXtension - the file Extension, with '.'
     *
     * All allowed values of `sFormat`
     *
     * ```txt
     *  d, dp, dpn, dpnx
     *  p, pn, pnx
     *  n, nx
     *  x
     * ```
     * @param {Boolean} isFolder - if true, assume `sPath` is a folder;
     *                  else (default) assume it's a file;
     *                  (ths only matters if `sPath` is a relative path)
     *
     * @return {String} specified part of `sPath`
     *
     * @throws {Error} if `sFormat` is illegal
     * <!--
     * @version 2024-10-01
     * @version 2025-11-25 `isFolder`
     * -->
     */
    static GetPathPart(sPath, sFormat, isFolder:=false)
    {
        if (!StrLen(sPath)) {
            return ""
        }
        local s_fullname, s_parent, s_ext, s_basename, s_drive

        if (!StrLen(s_drive)) {
            sPath := CFileUtils.PathRelativeTo(sPath, A_WorkingDir, isFolder)
        }
        SplitPath sPath, &s_fullname, &s_parent, &s_ext, &s_basename, &s_drive
        s_parent := SubStr(s_parent, StrLen(s_drive)+2)

        switch (sFormat) {
        case "d":
                return s_drive
        case "dp":
                return s_drive "\" s_parent
        case "dpn":
                return s_drive "\" s_parent "\" s_basename
        case "dpnx":
                return s_drive "\" s_parent "\" s_fullname
        case "p":
                return s_parent
        case "pn":
                return s_parent "\" s_basename
        case "pnx":
                return s_parent "\" s_fullname
        case "n":
                return s_basename
        case "nx":
                return s_fullname
        case "x":
                return "." s_ext
        default:
                throw Error("illegal format argument", "GetPathPart")
        }
    }

    /**************************************************
     * #### GetParent - return parent directory
     *
     * @param {String} sFullPath - file name or URL to be analyzed
     *
     */
    static GetParent(sFullpath)
    {
        return CFileUtils.GetPathPart(sFullpath, "dp")
    }

    /**********************************************
     * #### GetBaseName - return file name without its path, dot and extension
     *
     * @param {String} sFullPath - file name or URL to be analyzed
     */
    static GetBaseName(sFullpath)
    {
        return CFileUtils.GetPathPart(sFullpath, "n")
    }

    /**********************************************
     * #### GetExtension - return the file's extension, without the dot
     *
     * @param {String} sFullPath - file name or URL to be analyzed
     */
    static GetExtension(sFullpath)
    {
        return CFileUtils.GetPathPart(sFullpath, "x")
    }

    /**************************************************
     * #### DropExtension - return `sFullpath` without extension
     *
     * @param {String} sFullPath - file name or URL to be analyzed
     */
    static DropExtension(sFullpath)
    {
        return CFileUtils.GetPathPart(sFullpath, "dpn")
    }

    /*****************************************
     * #### GetAssociatedProgramPath: get program (if any) associated with Extension
     *
     * - (NOTE if extension is executable, this returns junk, eg "%1")
     *
     * @param {String} sExt - a file extension, with leading dot;
     *     append optional Action after pipe `|` (see Example)
     *
     * ##### Example
     *
     * ```AutoHotkey
     * ExePath  := GetAssociatedProgramPath(".ahk")
     * EditPath := GetAssociatedProgramPath(".ahk|edit")
     * ```
     * <!--
     * @version 2023-03-14
     * -->
     */
    static GetAssociatedProgramPath(sExt)
    {
        ; Thanks:
        ; RegRead associated program for a file extension - AutoHotkey Community
        ; https://www.autohotkey.com/board/topic/54927-regread-associated-program-for-a-file-extension/#entry344810

        local arExt   := StrSplit(sExt, "|")
        sExt          := arExt[1]
        local sAction := arExt[2]

        ; name of default Application
        ; HKEY_CLASSES_ROOT\<sExt>\@(Default)
        local sApp := RegRead("HKCR\" sExt)

        if (StrLen(sApp) < 2) {
            ; no Application associated w/ this Extension
            return ""
        }

        if (!StrLen(sAction)) {
            ; get default Action
            ; HKEY_CLASSES_ROOT\<sApp>\shell
            sAction := RegRead("HKCR\" sApp "\shell")
            if (!StrLen(sAction))
                sAction := "open"
        }
        ; remove any verb arguments, eg "open runas UIAccess Edit" => "open"
        sAction := StrSplit(sAction, " ")[1]

        ; Command line for Action
        ; HKEY_CLASSES_ROOT\<sApp>\shell\<sAction>\command
        local sCommand := RegRead("HKCR\" sApp "\shell\" sAction "\command")

        ; return Command line with arguments removed
        return CFileUtils.GetPathFromCommand(sCommand)
    }

    /*****************************************
     * #### GetPathFromCommand - get program path from a command line
     *
     * @param {String} sCommand - a command line
     *
     * @return {String} program path - keep quotes (if any) but remove arguments (if any)
     */
    static GetPathFromCommand(sCommand)
    {
        static DQ := Chr(34)
        local ps  := InStr(sCommand, " ")
        local pq1 := InStr(sCommand, DQ)
        local pq2 := InStr(sCommand, DQ, , 2)

        local sPath
        if (!pq1 && !pq2)
            sPath := sCommand
        else if (pq1==1 && pq2>1)
            sPath := SubStr(sCommand, 1, pq2)
        else if (ps > 0)
            sPath := SubStr(sCommand, 1, ps-1)
        else
            sPath := sCommand
        return sPath
    }

    /**********************************************
     * #### GetTempFilePath: get a unique filename in the given directory
     *
     * @param {String} sFolder - folder to place the file in; it must exist
     * @param {String} sPrefix - a name prefix - can be anything, default "$"
     * @param {String} sSuffix - a name suffix- can be anything, default (empty)
     * @param {String} sExt - the file extension, default "tmp"
     * @param {Integer} nNumber - a number to add to the filename; will grow as needed
     *
     * @return {String} a unique filename within the given directory
     */
    static GetTempFilePath(sFolder, sPrefix:="$", sSuffix:="", sExt:="tmp", nNumber:=100)
    {
        local TmpName:="", TmpPath:=""

        if (!StrLen(FileExist(sFolder)))
        {
            return "" ; "< sFolder not found - folder must exist >"
        }
        nNumber := Max(0, Round(nNumber))
        loop
        {
            if (++nNumber > 99999) {
                return "" ; "< can't find a unique name in this folder >"
            }
            TmpName := Format("{:d}", nNumber)
            TmpPath := sFolder "\" sPrefix TmpName sSuffix "." sExt
        }
        until (!StrLen(FileExist(TmpPath)))

        return TmpPath
    }

    /*******************************
     * #### AddQuotes: Wrap a string in quotation marks UNLESS it is already quoted
     */
    static AddQuotes(s)
    {
        static DQ := Chr(34)
        if (!StrLen(s))
            return DQ DQ
        if ((SubStr(s, 1, 1)==DQ) && (SubStr(s, -1, 1)==DQ))
            return s
        return DQ s DQ
    }

    /***********************************************
     * #### RemoveQuotes: remove matched pairs of quotes
     *
     * - escaped quotes not supported
     */
    static RemoveQuotes(s)
    {
        static DQ := Chr(34)
        if (StrLen(s) >= 2 && (SubStr(s, 1, 1)==DQ) && (SubStr(s, -1, 1)==DQ))
            return SubStr(s, 2, -1)
        return s
    }

    /******************************
     * #### HasBadFilenameChar: find first illegal filename char
     *
     * - this function allows the period `.` even though some say it is 'reserved'
     *
     * @param {String} s - the proposed file name
     *
     * @return 0 if `s` only contains characters legal in a filename;
     *    else returns the position of the first bad character
     *
     * @see {@link RemoveIllegalFilenameChars}
     */
    HasBadFilenameChar(s)
    {
        if (!StrLen(s))
            return 0
        return RegExMatch(s, CFileUtils.ILLEGAL_FILENAME_CHARS("regex"))
    }

    /*****************************************
     * #### ILLEGAL_FILENAME_CHARS: list illegal (reserved) characters
     *
     * - namely, ` x00-x1f " * / : \ < > ? | `
     * - see <https://en.wikipedia.org/wiki/Filename#In_Windows>
     *
     * @param {String} option - set the format with one of the following:
     *
     * - "regex" (char class)
     * - "expand" (add spaces as shown above)
     * - "" (default; as above but with no spaces)
     * <!--
     * @version 2025-11-17 per testing, all \x00-\x1f forbidden
     * -->
     */
    static ILLEGAL_FILENAME_CHARS(option:="")
    {
        if (option=="regex") {
            ;return   "[\n\r\t\`"\*/:\\<>\?\|]" ; per docs
            return "[\x00-\x1f\`"\*/:\\<>\?\|]" ; per testing
        }
        else if (option=="expand") {
            return " x00-x1f `" * / : \ < > ? | "
        }
        return "x00-x1f`"*/:\<>?|"
    }

    /*****************************************
     * #### path_ellipsis: shorten a path by removing chars and adding ellipsis '...'
     *
     * - adapted from <https://www.autohotkey.com/board/topic/53852-function-compressfilename/>
     *
     * @param {String}  s       - the full path
     * @param {Integer} max_len - character length limit; default 40
     *
     * @return {String} `s`, truncated if necessary; if so, ellipsis (...) is added
     */
    static path_ellipsis(s, max_len:=40)
    {
        static MAX_PATH := 260
        local charSize := 2
        local pRtn := Buffer(MAX_PATH * charSize, 0)

        ;https://learn.microsoft.com/en-us/windows/win32/api/shlwapi/nf-shlwapi-pathcompactpathexw
        local iRtn := DllCall("shlwapi.dll\PathCompactPathEx"
                        , "Ptr" , pRtn
                        , "Str" , SubStr(s, 1, MAX_PATH)
                        , "UInt", max_len)
        if (!iRtn) {
            ; fallback - trim and append ellipsis
            return SubStr(s, max_len-2) Chr(0x2026)
        }
        return StrGet(pRtn)
    }

    /*****************************************
     * #### path_ellipsis_pix: shorten a path by removing chars and adding '...'
     *
     * @param {Integer}  hWnd    - window handle of the target
     * @param {String}   s       - the full path
     * @param {Integer}  max_wid - width limit in pixels; default 200
     *
     * @return {String} `s`, truncated if necessary; if so, ellipsis (...) is added
     *
     * ##### Example
     * ```autohotkey
     * hh := ControlGetHwnd("Edit1", S_TITLE)
     * ControlGetPos , , &nctWid, , "Edit1", S_TITLE
     * shortName := CFileUtils.path_ellipsis_pix(hh, longName, nctWid)
     * ```
     * @see TrimStringToWidth.ahk :: GetStringWidth()
     */
    static path_ellipsis_pix(hWnd, s, max_wid:=200)
    {
        static MAX_PATH := 260
        try {
            local charSize := 2
            local pRtn := Buffer(MAX_PATH * charSize, 0)
            StrPut(SubStr(s, 1, MAX_PATH), pRtn, "UTF-16")

            hWnd := Round(hWnd)
            if (!hWnd) {
                throw Error("fallback")
            }

            local hDC := DllCall("user32.dll\GetDC"
                            , "Ptr", hWnd
                            , "Ptr")
            if (!hDC) {
                throw Error("fallback")
            }

            ;https://learn.microsoft.com/en-us/windows/win32/api/shlwapi/nf-shlwapi-pathcompactpathw
            local iRtn := DllCall("shlwapi.dll\PathCompactPath"
                            , "Ptr" , hDC
                            , "Ptr" , pRtn
                            , "UInt", max_wid
                            , "Int" )

            DllCall("user32.dll\ReleaseDC"
                            , "Ptr", hWnd
                            , "Ptr", hDC)
            if (!iRtn) {
                throw Error("fallback")
            }
            return StrGet(pRtn, "UTF-16")
        }
        catch {
            ; fallback: assume aprox. 5 pixels per character
            return CFileUtils.path_ellipsis(s, Round(max_wid / 5))
        }
    }

    /*****************************************
     * #### PathIsDirectory: test if a path is a directory
     *
     * @param {String} sPath - a file or directory path
     *
     * @return {Boolean} true if `sPath` exists AND is a directory
     */
    static PathIsDirectory(sPath)
    {
        if (!StrLen(sPath))
            return false
        return (InStr(FileExist(sPath), "D"))
    }

    /*****************************************
     * #### PrefixLongPath: add the prefix to handle paths longer than MAX_PATH
     *
     * @see Microsoft: [Maximum Path Length Limitation](
     *           https://learn.microsoft.com/en-us/windows/win32/fileio/maximum-file-path-limitation?tabs=registry)
     *
     * @param {String}  sPath - the full path (should be an absolute or UNC path - relative paths not handled)
     *
     * @return {String} `sPath` with long path prefix added as required (unless it's a relative path)
     * @throws {Error} if `sPath` is a relative path AND longer than MAX_PATH
     * <!--
     * @version 2025-10-25 incorporating suggestions from Grok 4
     * -->
     */
    static PrefixLongPath(sPath)
    {
        ; per Microsoft (link above)
        ; - To specify an extended-length path, use the "\\?\"     prefix.
        ; - To specify such a path using UNC  , use the "\\?\UNC\" prefix.
        ;
        if (StrLen(sPath) > (260 - 1))  ; (MAX_PATH - 1)
        {
            ; Check for existing long path prefix (local or UNC)
            if (RegExMatch(sPath, "^\\\\?\\\\(UNC\\\\)?"))  ; Matches ^\\?\  or ^\\?\UNC\
            {
                return sPath
            }
            else if (RegExMatch(sPath, "i)^[a-z]:\\\\"))  ; Absolute local/mapped: ^[a-z]:\
            {
                return "\\?\" sPath
            }
            else if (RegExMatch(sPath, "^\\\\")
                 && !RegExMatch(sPath, "^\\\\\.\\\\"))  ; Starts with \\  but not device \\.\
            {
                return "\\?\UNC" SubStr(sPath, 3)  ; Skip leading \\
            }
            else {
                throw Error("Invalid or relative path too long (unhandled type: "
                           . sPath ")", "PrefixLongPath")
            }
        }
        return sPath
    }

    /******************************
     * #### RemoveIllegalFilenameChars: strip illegal filename characters
     *
     * @param {String} s - a proposed file name
     *
     * @return {String} `s` with illegal filename characters removed
     */
    static RemoveIllegalFilenameChars(s)
    {
        if (!StrLen(s))
            return ""
        return RegExReplace(s, CFileUtils.ILLEGAL_FILENAME_CHARS("regex"), "")
    }

    /*****************************************
     * #### ResolveShortcut: read a Shortcut (.lnk) and return the link target
     *
     * @param {String}  sPath - the full path to the shortcut
     *
     * @return {String} link target, with arguments if any; if `sPath` not a valid shortcut, returns it unchanged
     * @see AHK Docs [FileGetShortcut](https://www.autohotkey.com/docs/v2/lib/FileGetShortcut.htm)
     */
    static ResolveShortcut(sPath)
    {
        local OutTarget, OutArgs, e, errmsg
        try {
            ;FileGetShortcut LinkFile , &OutTarget, &OutDir, &OutArgs, &OutDescription, &OutIcon, &OutIconNum, &OutRunState
            FileGetShortcut sPath , &OutTarget, , &OutArgs
            if (!StrLen(OutTarget))
                return sPath
            if (StrLen(OutArgs))
                return "`"" OutTarget "`" " OutArgs
            return OutTarget
        }
        catch Error as e {
            errmsg := e.Message ; for inspection in debugger
        }
        return sPath
    }

    /******************************
     * #### sOpenDlg: shows the Open common dialog
     *
     * - unlike FileSelect, supports multiple `|`-delimited filter sets in a dropdown list
     *
     * @param {Integer} hOwner - the parent form hWnd
     *
     * @param {String} sFolder_FileName - a folder name, a file name, or a full path
     *
     * @param {Integer} nFlags - a sum of the following
     *  - ReadOnly            := 1
     *  - HideReadOnly        := 4
     *  - NoChangeDir         := 8
     *  - AllowMultiselect    := 0x200
     *  - PathMustExist       := 0x800
     *  - FileMustExist       := 0x1000
     *  - CreatePrompt        := 0x2000
     *  - NoDereferenceLinks  := 0x100000
     *
     * @param {String} sTitle - dialog Title
     *
     * @param {String} sFilters - string to indicate which types of files are shown by the dialog
     * * e.g. `Documents (*.txt)|All files (*.*)`
     *
     * @return {String} full path of selected file; if 'AllowMultiselect' is set,
     *                 returns parent folder and list of files, delimited by "`n";
     *                 if error or user canceled, returns empty string
     * ##### Example:
     * ```AutoHotkey
     * sFileName := sOpenDlg(hWnd, "example.txt", 0, "Select File", "Text Files (*.txt)|*.txt|All Files (*.*)|*.*")
     * ```
     */
    static sOpenDlg(hOwner, sFolder_FileName, nFlags:=0, sTitle:="", sFilters:="")
    {
        nFlags := 0
        try nFlags := Round(nFlags)
        nFlags &= ~CFileUtils.OverwritePrompt

        ; try to force use of new-style dialog box:
        nFlags |= CFileUtils.Explorer
        nFlags |= CFileUtils.LongNames

        if (!StrLen(sTitle))
            sTitle := "Open File"
        if (!StrLen(sFilters))
            sFilters := "All Files (*.*)|*.*"

        return CFileUtils._FileDlg("comdlg32\GetOpenFileNameW"
                        , hOwner, sFolder_FileName, nFlags, sTitle, sFilters)
    }

    /******************************
     * #### sSaveAsDlg: shows the Save As common dialog
     *
     * - unlike FileSelect, supports multiple `|`-delimited filter sets in a dropdown list
     *
     * @param {Integer} hOwner - the parent form hWnd
     *
     * @param {String} sFolder_FileName - a folder name, a file name, or a full path
     *
     * @param {Integer} nFlags - a sum of the following
     *  - OverwritePrompt     := 2
     *  - NoChangeDir         := 8
     *  - PathMustExist       := 0x800
     *  - FileMustExist       := 0x1000
     *  - CreatePrompt        := 0x2000
     *  - NoDereferenceLinks  := 0x100000
     *
     * @param {String} sTitle - dialog Title
     *
     * @param {String} sFilters - string to indicate which types of files are shown by the dialog
     * * e.g. `Documents (*.txt)|All files (*.*)`
     *
     * @return {String} full path of selected file
     *
     * ##### Example:
     * ```AutoHotkey
     * sFileName := sSaveAsDlg(hWnd, "example.txt", 0, "Select File", "Text Files (*.txt)|*.txt|All Files (*.*)|*.*")
     * ```
     */
    static sSaveAsDlg(hOwner, sFolder_FileName, nFlags:=0, sTitle:="", sFilters:="")
    {
        nFlags := 0
        try nFlags := Round(nFlags)
        nFlags |= CFileUtils.FileMustExist
        nFlags |= CFileUtils.HideReadOnly
        nFlags &= ~CFileUtils.ReadOnly
        nFlags &= ~CFileUtils.AllowMultiselect

        ; try to force use of new-style dialog box:
        nFlags |= CFileUtils.Explorer
        nFlags |= CFileUtils.LongNames

        if (!StrLen(sTitle))
            sTitle := "Save File As"
        if (!StrLen(sFilters))
            sFilters := "All Files (*.*)|*.*"

        return CFileUtils._FileDlg("comdlg32\GetSaveFileNameW"
                        , hOwner, sFolder_FileName, nFlags, sTitle, sFilters)
    }

    /******************************
     * #### _FileDlg: shows the Open or Save As common dialog
     *
     * - "private" -  used by `sOpenDlg` and `sSaveAsDlg`
     * <!--
     * @version 2025-10-06 adapted from SKAN https://tiny.cc/fileselectfile
     * @version 2025-10-08 incorporated suggestions from Grok
     * -->
     */
    static _FileDlg(sFuncName, _hOwner, sFolder_FileName, nFlags, sTitle, sFilters)
    {
        global ErrorLevel

        ;adapted from SKAN:
        ; @see https://tiny.cc/fileselectfile
        ; @see https://www.autohotkey.com/boards/viewtopic.php?t=81514

        local hOwner := 0
        try hOwner := Round(_hOwner)

        local sFileName, sStartFolder, sDefExt
        SplitPath sFolder_FileName, &sFileName, &sStartFolder, &sDefExt

        ; Set 'df' before LTrim (per SKAN: checks raw for leading "|")
        local df := (Ord(sFilters) == 124)
        local sFilt
        sFilt := df ? LTrim(sFilters, "|") : sFilters
        sFilt := StrLen(sFilt) ? sFilt : "All files (*.*)"

        ; normalize "|"s
        local pp := InStr(sFilt, "||", , -1)           ; find rightmost "||"
        local s1 := pp ? SubStr(sFilt, 1, pp) : sFilt  ; chop off rightmost "||" if found
        local s2 := StrReplace(s1, "||", "|")
        sFilt := s2  ; Assign back for parse loop

        ; expand sFilt
        ;   from "Text Documents (*.txt; *.text)"
        ;   to   "Text Documents (*.txt;*.text)|*.txt;*.text|"
        local sLoopDelim := "|"
        local sLoopOmit  := " "
        local sFiltTemp  := ""
        Loop Parse, sFilt , sLoopDelim, sLoopOmit
        {
            lv := A_LoopField                   ; eg, "Text Documents (*.txt; *.text)"
            pp := InStr(lv, "(", , -1)          ; find rightmost "("
            s3 := Trim(SubStr(lv, pp), "( )")   ; extract (text in parens)
            ns := StrReplace(s3, " ", "")       ; delete internal " "s
            if (pp && StrLen(ns))
            {
                s1 := df ? "{1:}|{2:}|" : "{1:}({2:})|{2:}|"
                s2 := SubStr(lv, 1, pp-1)       ; Text to the left of "("
                sFiltTemp .= Format(s1, s2, ns) ; eg, "Text Documents (*.txt;*.text)|*.txt;*.text|"
            }
        }

        ; add 2nd trailing "|"
        sFilt := sFiltTemp "|"

        ; replace "|" with NULL chars
        local charSize := 2
        local lenFilt  := StrLen(sFilt)
        local pszFilt  := Buffer(lenFilt * charSize, 0)
        StrPut(sFilt, pszFilt, "UTF-16")
        local NCHAR    := 0  ; NULL char
;NCHAR := 167  ; "§" for for inspecting in debugger
        local pp := 0
        local cc
        while (pp < (lenFilt * charSize)) {
            cc := NumGet(pszFilt, pp, "UChar")
            if (cc == 124) {   ; "|"
                NumPut("UChar", NCHAR, pszFilt, pp)
                NumPut("UChar", 0    , pszFilt, pp + 1)  ; Ensure full wide null (safer)
            }
            pp += charSize
        }
;sFiltTemp := StrGet(pszFilt, "UTF-16") ; for inspecting in debugger ONLY

        local nMaxFile := 65536  ; for multiselect safety
        local pszFile  := Buffer(nMaxFile * charSize, 0)
        StrPut(sFileName, pszFile, "UTF-16")

        local nFilterIndex := 0

        local pszStart := Buffer(512 * charSize, 0)
        StrPut(sStartFolder, pszStart, "UTF-16")

        local pszTitle := Buffer(1024 * charSize, 0)
        StrPut(sTitle, pszTitle, "UTF-16")

        local pszExt := Buffer(32 * charSize, 0)  ; Larger for safety
        StrPut(sDefExt, pszExt, "UTF-16")

        ; Creating OPENFILENAME Struct
        local P8   := (A_PtrSize == 8)
        local pOFN := Buffer((P8 ? 168 : 96), 0)

        ;NumPut Type, Number, Target , Offset
        NumPut("UInt" , (P8 ? 136 : 76), pOFN, 0)                 ; lStructSize
        NumPut("Ptr"  , hOwner         , pOFN, (P8 ?  08 : 04))   ; hwndOwner
        NumPut("Ptr"  , pszFilt.Ptr    , pOFN, (P8 ?  24 : 12))   ; lpstrFilter
        NumPut("UInt" , nFilterIndex   , pOFN, (P8 ?  44 : 24))   ; nFilterIndex
        NumPut("Ptr"  , pszFile.Ptr    , pOFN, (P8 ?  48 : 28))   ; lpstrFile
        NumPut("UInt" , nMaxFile       , pOFN, (P8 ?  56 : 32))   ; nMaxFile
        NumPut("Ptr"  , pszStart.Ptr   , pOFN, (P8 ?  80 : 44))   ; lpstrInitialDir
        NumPut("Ptr"  , pszTitle.Ptr   , pOFN, (P8 ?  88 : 48))   ; lpstrTitle
        NumPut("UInt" , nFlags         , pOFN, (P8 ?  96 : 52))   ; flags
        NumPut("Ptr", (StrLen(sDefExt) ? pszExt.Ptr : 0)
                                       , pOFN, (P8 ? 104 : 60)) ; lpstrDefExt
        local rtn := 0
        try rtn := DllCall(sFuncName, "Ptr", pOFN.Ptr, "UInt")
        if (!rtn) {
            ; https://learn.microsoft.com/en-us/windows/win32/api/commdlg/nf-commdlg-commdlgextendederror
            local errcode1 := DllCall("comdlg32\CommDlgExtendedError", "UInt")
            return "" ; error, or user canceled
        }
        local sRtn, pf, sLine
        if (nFlags & CFileUtils.AllowMultiselect) {
            ; Extract file list
            sRtn := ""
            pf   := pszFile.Ptr
            while ( sLine := StrGet(pf, "UTF-16") ) {
                sRtn .= sLine "`n"
                pf += ((StrLen(sLine) + 1) * charSize)
            }
            sRtn := Rtrim(sRtn, "`n")
        }
        else {
            sRtn :=  StrGet(pszFile.Ptr, "UTF-16")
        }
        ErrorLevel := 0
        return sRtn
    } ; /_FileDlg

    static ReadOnly             := 1            ; read only
    static OverwritePrompt      := 2            ; prompt to overwrite file [Save mode]
    static HideReadOnly         := 4            ; hide read-only
    static NoChangeDir          := 8            ; no changing directory
    static HelpButton           := 0x10
    static NoValidate           := 0x100
    static AllowMultiselect     := 0x200        ; allow multiselect [Open mode]
    static ExtensionDifferent   := 0x400
    static PathMustExist        := 0x800        ; path must exist
    static FileMustExist        := 0x1000       ; file must exist
    static CreatePrompt         := 0x2000       ; prompt to create file
    static ShareAware           := 0x4000
    static NoReadOnlyReturn     := 0x8000
    static NoLongNames          := 0x40000
    static Explorer             := 0x80000
    static NoDereferenceLinks   := 0x100000     ; don't dereference links
    static LongNames            := 0x200000
} ; /CFileUtils

; (end)
