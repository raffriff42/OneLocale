; OneLocale.ahk
;; language support

#Requires AutoHotkey v2.0

;************************************************
; Credits - I believe that unless otherwise attributed,
; this AutoHotkey code is original
; (other than sample code from the documentation)
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
;  sT(sSection, sKey, sDefault, args, langPath)
;  OneLocale_Init(optional_args)
;  class CLocale {
;      CBoolean(v)
;      ErrAppend(sBase, sAppend, sDelim)
;      ErrDecode(errcode, lang_id_or_path, sSection, sKey)
;      FindBestFile(sID, sFolder, sTemplate, &errmsg)
;      FindBestMap(sID, sFallback, &errmsg)
;      GetIDType(sID)
;      GetLocaleInfo(sID, LCType)
;      GetLocaleInfoSet(sID)
;      IniFileDupeCheck(ini_path)
;      IniReadEx()
;      LCIDToLocaleName(nLCID)
;      LocaleNameToLCID(sTag)
;      MapRead(sMapName, sSection, sKey, sDefault)
;      PathRelativeTo(sHome, sRelative)
;      sE(s, args)
;      StringToVariable(s)
;  }

; globals defined by this script:
g_ini_path  := "" ; the main .INI file
g_lang_path := "" ; active .LANG file
g_lang_id   := "" ; active language code
g_docs_path := "" ; active docs / help fie
g_lang_map  := 0  ; Map containing language data, if initialized

/*****************************************
 * #### sT : translate user-interface messages
 *
 * ##### What it does
 *
 * - Look up a string in the active language, as set in `OneLocale_Init()`.
 * - Replace _named variables_ (enclosed in `%`) using `args` parameter.
 * - If `g_lang_map[g_lang_id]` exists, loads strings from there; see `OneLocale_BuildMap` below.
 * - If not, loads translated strings from a language-specific .LANG file.
 * - If the requested string is not found, return `sDefault` argument
 * - Supports _extender_ files - see [Extenders](#extenders) below.
 *
 * ##### Example
 *
 * ```autohotkey
 * ; MyScript.ahk
 * S_TITLE   := "MyScript"
 * S_VERSION := "1.0"
 * ...
 * locale_info := OneLocale_Init() ; read .INI file, set current language
 * if (!locale_info.success) {
 *     MsgBox(locale_info.errmsg, S_TITLE, "icon!")
 *     ExitApp
 * }
 * ...
 * MyGui.Title := sT("gui", "title", "/%title% - version %ver%"
 *                     , {title:S_TITLE, ver:S_VERSION})
 * ```
 *
 * ```ini
 * ; MyScript.ini
 * [general]
 * language = de
 * ```
 *
 * ```ini
 * ; MyScript-[de].lang
 * [gui]
 * title = %title% - Ausführung %ver%
 * ```
 *
 * As a result, `MyGui.Title` is set to `MyScript - Ausführung 1.0`
 *
 * ##### Arguments
 *
 * @param {String} sSection - section name (see Notes)
 *
 * @param {String} sKey     - key name (see Notes)
 *
 * @param {String} sDefault    - text to use if lookup fails
 *
 * - `sDefault` is useful during development as temporary text until a .LANG file can be created)
 * - if `sDefault` is unset, `sT` will throw errors - good for debugging but NOT for production
 *
 * @param {Object} args      - optional names and values: `{book:"HHGTTG", answer:42}`
 * @param {String} langPath  - if not empty, overrides `g_lang_path` as the path of the .LANG file
 *
 * ##### Notes:
 *
 * - To support Unicode text, save Language files as UTF-16 w/ BOM (Byte Order Mark).
 *   UTF-8 does not work.
 * - .LANG path is specified by global `g_lang_path`, but it can be overridden with the
 *   `langPath` argument
 * - If `sKey`=="[section]" (verbatim, including the brackets), read entire INI section.
 *   Useful for long, multi-line messages. Note leading whitespace is lost, but you can
 *   start lines with `\t` to indent them. Blank lines in the section are read, but ignored
 *   on output; to output blank lines, add `\n` as needed.
 * - If `sSection`=="errors", passes `sKey` verbatim to the output as a prefix to the
 *   message itself. This prefix allows tech support to identify the error by a string that
 *   does not change, regardless of the user's language.
 * - Replaces `\t` with tab char
 * - Replaces `\n` with newline; (ignores one leading space after a newline)
 * - Treats all beyond `\z` as comment (to the translator)
 * - To pass a literal `%`, use `\\%`
 * - To pass a literal `\\`, use `\\\\`
 * - To _remove_ a newline, use `\w` before or after it (this is to ignore a line break in
 *   multiline text, letting the Gui element handle Word Wrap)
 *
 * ##### Examples
 *
 * 'Main' INI file specifying the active language code
 * (codes SHOULD be taken from [Microsoft's list](
 *   https://learn.microsoft.com/en-us/openspecs/windows_protocols/ms-lcid/a9eac961-e77d-41a6-90a5-ce1a8b0cdb9c)
 * (scroll down to Table 2)
 *
 * ```txt
 * ; MyScript.ini
 * [general]
 * language = de
 * ```
 *
 * Language file:
 *
 * ```txt
 * ; MyScript-[en-ES].lang
 * [gui]
 * title = 100\% Awesome\z (this is a comment)
 * [errors]
 * bad_path = File '%path%' \n not found
 * ```
 *
 * Another language file
 *
 * ```txt
 * ; MyScript-[de].lang
 * [gui]
 * title = Fantastisch 100\%
 * [errors]
 * bad_path = Datei '%path%' \n Nicht gefunden
 * ```
 *
 * Usage
 *
 * ```AutoHotkey
 * ; MyScript.ahk
 * locale_info := OneLocale_Init()
 * if (!locale_info.success)
 *     (handle error...)
 * ...
 * title  := sT("gui", "title")
 * ; result (depending on which language file is loaded)
 * ;   "100% Awesome"
 * ;   "Fantastisch 100%"
 * ...
 * filename := "some-file-name.txt"
 * msg := sT("errors", "bad_path", , {path:s_path})
 * ```
 *
 * Result (English)
 * > "bad_path: File 'some-file-name.txt' `n not found"
 *
 * Result (German)
 * > "bad_path: Datei 'some-file-name.txt' `n Nicht gefunden"
 *
 * - (note prefix 'bad_path' shown to user verbatim)
 * - (the prefix is for tech support; the body is for the user)
 *
 * ##### Hard coded data
 *
 * - Strings are compiled into the .EXE for extra security.
 * - Generate code from .LANG with the `OneLocale_BakerGui` app.
 * - `#Include` the generated file in your script.
 * - In your app, call the generated function; it will be named based on the given `lang_id`.
 * - For instance, if `lang_id` is "zh-cn", generated function will be `OneLocale_BuildMap_zh_cn()`
 * - This will initialize `g_lang_map[lang_id]`. `OneLocale_Init` will recognize it, and `sT()` will use it.
 *
 * ##### No language file or data
 *
 * - Code without worryng about the .LANG file until later
 * - This way of coding has some advantages: the default text...
 *
 *   - serves as reminder to the author of the intended final string
 *   - allows script to be tested without a language file
 *   - leading `/` as shown serves as flag showing the default was used,
 *     signaling a language file loading error
 *
 * ```AutoHotkey
 * ; MyScript.ahk
 * msg := sT("gui", "some_example", "/Example: %num%", {num:99})
 * ```
 *
 * Result (if `"some_example"` not defined in lang file):
 *
 * > "/Example: 99"
 *
 * ##### Extenders
 *
 * The .LANG file may list a set of _extender_ files via an optional
 * Extenders section. If the requested message is not found in the main .LANG file,
 * this function looks into the extenders. Extenders are listed in a special
 * section named `:extenders:`.
 *
 * This feature is helpful when you have .LANG data that is used in multiple
 * projects, such as a dialog box (for example, `OneLocaleDlg_Dialog`)
 *
 * Finally, if the search is exhausted, `sDefault` is returned,
 *
 * - Extender paths may be absolute or relative to `sPath`
 *   - May fail for paths on mapped drive letters
 *   - Share paths seem to work, but they are slow when first accessed.
 *   - Short names (forced by Windows to 8.3 form) may not work.
 *   - Symbolic links seem to work.
 *   - `\\?\` (long name enable) prefixed paths are supported,
 *     and are added if needed on long paths.
 *
 * - Files are checked in order until the requested item is found
 * - If the requested item is not found in any of the extenders, `sDefault` is returned;
 *   if there is no `sDefault`, a catchable Error is thrown.
 * <!--
 * @version 2023-02-20 wrote it
 * @version 2023-02-27 add `sDefault` arg
 * @version 2023-03-03 handle sSection=="errors"
 * @version 2023-03-11 argument order
 * @version 2023-03-17 comments; read [section]
 * @version 2023-07-09 comments
 * @version 2023-11-10 comments
 * @version 2023-11-25 ignore one leading space after a newline
 * @version 2023-11-29 moved variable expansion code to sE()
 * @version 2024-09-20 add `langPath`
 * @version 2025-10-16 :extenders: support (simplified IniReadEx)
 * @version 2025-11-03 use g_lang_map instead of a .LANG file if it's available
 * -->
 */
sT(sSection, sKey, sDefault:="ERROR", args:="", langPath:="")
{
    global g_lang_path, g_lang_map, g_lang_id
    local mapped := false
    if (!StrLen(langPath) && IsSet(g_lang_path) && g_lang_path == ":map:")
    {
        try {
            if (g_lang_map[g_lang_id][":lang_id:"] == g_lang_id)
                mapped := true
        }
        ; (catch: mapped := false)
    }

    local errcode := 0
    local errmsg  := ""
    local s := ""
    try {
        if (mapped) {
            if (sKey=="[section]") {
                errcode := 2 ; bad  section
                s := CLocale.MapRead(g_lang_id, sSection, , sDefault)
            }
            else if (StrLen(sKey)) {
                errcode := 3 ; bad key
                s := CLocale.MapRead(g_lang_id, sSection, sKey, sDefault)
            }
            ; (else mapped == false - call IniReadEx)
        }
        else {
            local lang_path := g_lang_path
            if (StrLen(langPath))
                lang_path := langPath

            if (sKey=="[section]") {
                errcode := 12 ; bad section
                s := CLocale.IniReadEx(lang_path, sSection)
            }
            else if (StrLen(sKey)) {
                errcode := 13 ; bad key
                s := CLocale.IniReadEx(lang_path, sSection, sKey)
            }
        }
    }
    catch Error as e {
        if (IsSet(sDefault)) {
            s := sDefault
        }
        else {
            errmsg := CLocale.ErrDecode(errcode, g_lang_id, sSection, sKey)
            throw Error(errmsg "`n" e.Message)
        }
    }

    ; expand named variables
    s := CLocale.sE(s, args)

    ; ignore one leading space after a newline
    s := StrReplace(s, "`n ", "`n")

    if (sSection=="errors" && sKey!="[section]") {
        s := sKey ": " s
    }
    return s
} ; /sT

;@ahk-neko-ignore 255 line 'function too big'
/**************************************************
 * #### OneLocale_Init
 *
 * ##### What it does
 *
 * - Determine .INI path and verify it exists.
 * - Get a Language ID from .INI file entry or `A_Language`
 * - The .LANG file folder and the 'baked' data are searched for the best
 *    or most compatible match for the given language ID.
 * - Doc files are also searched; the best available language may differ
 *     when docs are not shipped to support all languages.
 * - Define global `g_ini_path`, `g_lang_path`, `g_lang_id` and `g_docs_path`
 * - Return an Object with named properties.
 *   - Important properties are
 *       `.success`, `.errmsg`, `.langID` and `.fallback`
 *   - If 'baked' (hard coded) data was selected, `.langPath` will be `:map:`
 *   - If suitable language doesn't exist, the fallback language
 *     (usually English with the `.langID` "en") will be loaded;
 *     in that case, `.fallback` will be true.
 *   - As long as `.success` is true, the application can continue; if it's false,
 *       it has a fatal error and must quit.
 *
 * ##### Basic Usage
 *
 * ```ini
 * ; MyScript.ini
 * [general]
 * language = fr-CA
 * ```
 *
 * ```autohotkey
 * ; MyScript.ahk
 * locale_info := OneLocale_Init()
 * if (!locale_info.success) {
 *     MsgBox(locale_info.errmsg, S_TITLE, "icon!")
 *     ExitApp
 * }
 * ```
 *
 * ##### Parameters
 *
 * @param {Object} `optional_args` - a set of named values, listed below.
 * You only need to supply the values which are non-default.
 *
 * - `noLangFile` {Boolean} default = false
 *   - if false (default), use separate .LANG file;
 *   - if true, the .INI file serves as the .LANG file;
 *     `sLangFolder` is ignored;
 *     on return, `docsPath` will be the empty string
 *
 * - `sLangFolder` {String} default = "lang"
 *   - override the default .LANG file subdirectory
 *   - if `sLangFolder` is "" (empty), .LANG files go in script directory
 *
 * - `sDocsFolder` {String} default = "docs"
 *   - override the default help file subdirectory
 *   - if `sDocsFolder` is "" (empty), help files go in script directory
 *
 * - `sName` {String} default = ""
 *   - base .INI and .LANG file name
 *   - if `sName` is empty (default), it's set to `A_ScriptName` without extension
 *
 * - `sLangName` {String} default = ""
 *   - base .LANG file name;
 *   - if empty (default), it's set to `A_ScriptName` `-[/TAG/]`;
 *     this routine replaces `/TAG/` with the active Language Tag
 *
 * - `sDocName` {String} default = ""
 *   - base doc file name;
 *   - if empty (default), it's set to `A_ScriptName` `-[/TAG/]`;
 *     this routine replaces `/TAG/` with the active Language Tag
 *   - (this is to support language-specific documentation; if you don't have that,
 *     ignore this argument)
 *
 * - `sDocExt` {String} default = "html"
 *   - doc file extension, eg "txt", "md", "pdf", or "html" (the default)
 *   - For example, if `sDocName` is "MyScript-readme", `sDocExt` is "txt" and the
 *     language ID is "en", this function looks for a file named "MyScript-readme-\[en].txt"
 *
 * - `sFallback` {String} default = "en"
 *   - An ISO 639-style Tag ('en', 'fr') _OR_
 *     4-hex-digit LCID ('0409', '000C') (with or without '0x' prefix)
 *   - ISO tag or LCID to use if no .LANG file was found for the given language (as calculated above);
 *     in this case, returned Object `.fallback` will be true;
 *     - The .LANG and doc files MUST exist, or initialization fails
 *     - Useful if you prefer automatic language selection based on `A_Language`; in this case leave
 *       the .INI entry blank; the closest available language will be chosen automatically.
 *
 * - `sLangID` {String} default = "(auto)"
 *   - An ISO 639-style Tag ('en', 'fr') _OR_
 *     A 4-hex-digit LCID ('0409', '000C') (with or without '0x' prefix)
 *     - If not empty or "(auto)", `sLangID` overrides any .INI file entry.
 *     - If there is no .INI entry and no `sLangID` argument, `A_Language` will be used for automatic
 *       language selection (provided a compatible language file has been installed)
 *   - `sLangID` sources, lowest to highest priotity:
 *      `A_Language`, .INI file, `optional_args`
 *   - if `sLangID` (wherever it came from) isn't a valid language ID, this routine fails.
 *
 * - `mapPriority` {Boolean} default true; determines whether Maps ('baked' data)  or .LANG Files
 *   have priority when a given Language is supported by both. Setting this to `false` means any
 *   .LANG files in `sLangFolder` will be preferred over any baked data, as long as they are compatible
 *   with the requested language.
 *
 * For example, calling `OneLocale_Init` with a non-default `optional_args` value:
 *
 * ```autohotkey
 * ; MyScript.ahk
 * locale_info := OneLocale_Init( {mapPriority:false} )
 * if (!locale_info.success) {
 *     MsgBox(locale_info.errmsg, S_TITLE, "icon!")
 *     ExitApp
 * }
 * ```
 *
 * ##### Return Value
 *
 * @return {Object} with the following properties:
 *
 * - `.success` {Boolean} if true, the initialization was successful.
 *
 * - `.errmsg` {String} error or warning message, if any.
 *
 * - `.langID` {String} ISO Tag or LCID code for the current language;
 *   - It will be the best matching .LANG file that could be found;
 *   - May be a parent language, or may be the Fallback language.
 *   - This value also stored in global variable `g_lang_id`
 *
 * - `.langName` {String} human-readable language name (e.g., "English")
 *
 * - `.fallback` {Boolean} if true, the Fallback language was used.
 *
 * - `.iniPath` {String} location of main .INI file
 *   - File must exist, or `.success` will be false
 *   - This value also stored in global variable `g_ini_path`
 *
 * - `.langPath` {String} location of active .LANG file
 *   - If `noLangFile` argument was set, `.langPath` will be same as `.iniPath`
 *   - This value also stored in global variable `g_lang_path`
 *
 * - `.docsPath` {String} location of active docs (help) file, if any;
 *   - If `noLangFile` argument was set, `.docsPath` will be the empty string
 *   - This value also stored in global variable `g_docs_path`
 *
 * - `.isoTag` {String} ISO Tag for the current language
 * - `.lcid` {String} 4-hex-digit LCID code for the current language
 *   - `.isoTag` and `.lcid` are alternate ways of specifying a language.
 *
 * - `.langMap` {Boolean} if true, 'baked' (hard coded) language data was used;
 *   - if `,langMap` is true, `.langPath` and `g_lang_path` will be ":map:"
 *
 * - `sLangFolder` {String}  copied from argument
 * - `sName`       {String}  copied from argument
 * - `mapPriority` {Boolean} copied from argument
 *
 * ##### INI file
 *
 * If you set the script's language with the .INI file, it should have an entry specifying the
 * ISO tag or LCID code under `[general]` as shown below.
 *
 * ```ini
 * ; MyScript.ini
 * [general]
 * language = en
 * ;language = de
 * ```
 *
 * ##### Example - default arguments
 *
 * ```autohotkey
 * ; MyScript.ahk
 * locale_info := OneLocale_Init()
 * if (!locale_info.success) {
 *     MsgBox(locale_info.errmsg, S_TITLE, "icon!")
 *     ExitApp
 * }
 * ```
 *
 * The default arguments suffice _IF_ ( assuming `MyScript` is replaced with your script name, and `/TAG/`
 * means the active language, like "en" )
 *
 * - The .INI file is named `MyScript.ini` and is located in `A_ScriptDir`
 * - The .LANG file is named `MyScript-[/TAG/].lang` and is located in `A_ScriptDir` `\lang`
 * - The .HTML file (if present) is named `MyScript-[/TAG/].html` and is located in `A_ScriptDir` `\docs`
 * - The language ID is specified in the .INI file or is equal to `A_Language`
 *
 * ##### Example - no .LANG file
 *
 * If you want your .INI to also hold your UI text, eliminating .LANG files, you would set `noLangFile` to `true`.
 *
 * ```autohotkey
 * ; MyScript.ahk
 * locale_info := OneLocale_Init( {noLangFile:true} )
 * if (!locale_info.success) {
 *     MsgBox(locale_info.errmsg, S_TITLE, "icon!")
 *     ExitApp
 * }
 * ```
 *
 * ##### Example - no 'docs' subdirectory
 *
 * If you want to put the help file in `A_ScriptDir`, eliminating the
 * "docs" subdirectory, you would clear `sDocsFolder`:
 *
 * ```autohotkey
 * locale_info := OneLocale_Init( {sDocsFolder:""} )
 * if (!locale_info.success) {
 *     MsgBox(locale_info.errmsg, S_TITLE, "icon!")
 *     ExitApp
 * }
 * ```
 * <!--
 * @version 2023-11-10 wrote it
 * @version 2023-11-21 added `sRootPath`, `sLangFolder`
 * @version 2023-12-19 bugfix
 * @version 2023-12-24 no versions
 * @version 2024-01-13 return error message
 * @version 2024-06-15 support `sLangFolder`="NULL" (later `noLangFile`)
 * @version 2024-08-21 add `sLangID`; doc comments
 * @version 2024-08-28 add `sFallback`; better error reporting
 * @version 2024-08-29 doc comments - pseudocode section (removed later)
 * @version 2024-09-15 return `LanguageInfo` object; add `noLangFile`
 * @version 2024-09-17 add `sLangTemplate`
 * @version 2024-09-20 return .iniPath, .langPath
 * @version 2024-09-23 remove `LanguageInfo` code; return an anonymous object
 * @version 2025-09-12 .lang folder always "lang"; new .docs folder, always "docs"
 * @version 2025-09-15 improved noLangFile behavior; argument order
 * @version 2025-09-17 replaced long argument list with Object
 * @version 2025-09-21 check for duplicate sections & keys in .INI & .LANG files
 * @version 2025-10-23 `optional_args` changes; define four globals
 * @version 2025-11-03 use g_lang_map instead of a .LANG file if it's available
 * @version 2025-11-21 add `sLangName`arg, new output fields copied from argument
 * -->
 */
OneLocale_Init(optional_args:="")
{
    global g_ini_path, g_lang_path, g_lang_id, g_docs_path

    ; ARGS ////////////////////////////////////////////////////////////

    local noLangFile:=false, sName:="", sLangID:="(auto)"
    local sLangName:="", sDocName:="", sDocExt:="html", sFallback:="en"
    local sLangFolder:="lang", sDocsFolder:="docs"
    local mapPriority:=true

    if (IsObject(optional_args))
    {
        local enn := optional_args
        if !(optional_args Is Map)
            enn := optional_args.OwnProps()
        local sKey, sValue
        for sKey, sValue in enn
        {
            switch (sKey)
            {
                case "noLangFile"    : noLangFile    := (sValue != 0)
                case "sName"         : sName         := sValue
                case "sLangName"     : sLangName     := sValue
                case "sDocName"      : sDocName      := sValue
                case "sDocExt"       : sDocExt       := sValue
                case "sFallback"     : sFallback     := sValue
                case "sLangID"       : sLangID       := sValue
                case "sLangFolder"   : sLangFolder   := sValue
                case "sDocsFolder"   : sDocsFolder   := sValue
                case "mapPriority"   : mapPriority   := CLocale.CBoolean(sValue)
                default:
                    ; ignore
            }
        }
    }

    if (!StrLen(sName))
        sName := SubStr(A_ScriptName, 1, -4)
    if (!StrLen(sLangName))
        sLangName := sName "-[/TAG/]"
    if (!StrLen(sDocName))
        sDocName := sName "-[/TAG/]"

    local ini_folder := A_ScriptDir
    local ini_path   := ini_folder "\" sName ".ini"
    local errmsg
    if (!StrLen(FileExist(ini_path))) {
        errmsg := "Configuration file `n'" ini_path "'`nnot found"
        return { success:false, fallback:false, errmsg:errmsg }
    }
    errmsg := CLocale.IniFileDupeCheck(ini_path)
    if (StrLen(errmsg)) {
        return { success:false, fallback:false, errmsg:errmsg }
    }

    sLangFolder := LTrim(sLangFolder, "\ ")
    sDocsFolder := LTrim(sDocsFolder, "\ ")
    if (StrLen(sLangFolder))
        sLangFolder := "\" sLangFolder
    if (StrLen(sDocsFolder))
        sDocsFolder := "\" sDocsFolder

    ; NO LANG FILE //////////////////////////////////////////////

    if (noLangFile) {

        g_ini_path  := ini_path
        g_lang_path := ini_path
        g_lang_id   := ""
        g_docs_path := ""

        return { success:true, fallback:false, errmsg:""
               , langID:"" , langName:"", isoTag:"" , lcid:""
               , langMap:false, iniPath:ini_path, langPath:ini_path, docsPath:""
               , sLangFolder:"", sName:sName, mapPriority:mapPriority }
               ; =====> success
    }

    ; LANG ID //////////////////////////////////////////////////////////

    ; `sLangID` sources, lowest to highest priotity:
    ;  `A_Language`, .INI file, `optional_args`

    if (sLangID=="(auto)")
        sLangID := ""

    if (!StrLen(sLangID))
        sLangID := IniRead(ini_path, "general", "Language", "")

    if (!StrLen(sLangID))
        sLangID := A_Language

    ; enforce sLangID validity
    local fallback := false
    tagType := CLocale.GetIDType(sLangID)
    if (!StrLen(tagType)) {

        errmsg   := "language argument '" sLangID "' not valid`n"
        sLangID  := sFallback
        fallback := true

        tagType := CLocale.GetIDType(sLangID)
        if (!StrLen(tagType)) {
            errmsg  .= "language argument '" sFallback "' not valid"
            return { success:false, fallback:true, errmsg:errmsg }
        }
    }

    ; DOCS /////////////////////////////////////////////////////////////

    local docs_folder := ini_folder sDocsFolder
    local sDocsTemplate := sDocName "." sDocExt

    ; find an ID that has a docs file in 'docs_folder'
    ; find best available matching ID (ISO/LCID/Parent/fallback)
    local sDocsID   := CLocale.FindBestFile(sLangID, sFallback, docs_folder, sDocsTemplate)
    local sPatt     := StrReplace(sDocsTemplate, "/TAG/", sDocsID)
    local docs_path := docs_folder "\" sPatt
    local sID       := sLangID

    ; MAPS /////////////////////////////////////////////////////////////

    local rtnObjMap := { success:false, errmsg:"unknown" }

    if (IsSet(g_lang_map) && IsObject(g_lang_map) && (g_lang_map Is Map))
    {
        ; find best available matching ID (ISO/LCID/Parent/fallback)
        sID := CLocale.FindBestMap(sID, sFallback, &errmsg)
        if (InStr(errmsg, "error:"))
            OutputDebug(errmsg "`n") ; BREAKPOINT
        if (sID == sFallback)
            fallback := true

        local mlng := g_lang_map[sID]
        if (IsObject(mlng) && (mlng Is Map)
        && mlng.Has(":lang_id:") && mlng[":lang_id:"] == sID)
        {
            local mapInfo := CLocale.GetLocaleInfoSet(sID)
            ; -> Object (`LCID`, `IsoTag`, `Name`, `Native`, `Parent`)
            if (IsObject(mapInfo))
            {
                mlng[":native:"] := mapInfo["Native"]
                mlng[":parent:"] := mapInfo["Parent"]
                mlng[":isoTag:"] := mapInfo["IsoTag"]
                mlng[":lcid:"]   := mapInfo["LCID"]

                g_ini_path  := ini_path
                g_lang_path := ":map:"
                g_lang_id   := sID
                g_docs_path := docs_path

                rtnObjMap := { success:true, fallback:fallback, errmsg:errmsg
                    , langID:sID, langName:mapInfo["Name"], isoTag:mapInfo["IsoTag"]
                    , lcid:mapInfo["LCID"], langMap:true, iniPath:ini_path
                    , langPath:":map:", docsPath:docs_path
                    , sLangFolder:"", sName:sName, mapPriority:mapPriority }
            }
        }
    }

    ; LANG FILE ////////////////////////////////////////////////////////

    local lang_folder   := ini_folder sLangFolder
    local sLangTemplate := sLangName ".lang"

    ; find an ID that has a lang file in 'lang_folder'
    ; find best available matching ID (ISO/LCID/Parent/fallback)
    sID := CLocale.FindBestFile(sID, sFallback, lang_folder, sLangTemplate, &errmsg)

    local sPatt     := StrReplace(sLangTemplate, "/TAG/", sID)
    local lang_path := lang_folder "\" sPatt

    local fileInfo
    if (!StrLen(FileExist(lang_path)))
    {
        fallback := true
        sID   := sFallback
        sPatt := StrReplace(sLangTemplate, "/TAG/", sID)

        fileInfo := CLocale.GetLocaleInfoSet(sID)
        ; -> Object (`LCID`, `IsoTag`, `Name`, `Native`, `Parent`)
        if (IsObject(fileInfo))
        {
            lang_path := lang_folder "\" sPatt
            if (!StrLen(FileExist(lang_path))) {
                ; no checking for alternate forms...fallback had BETTER exist
                errmsg := CLocale.ErrAppend(errmsg
                    , "fallback ID '" sID "' not found")
                if (rtnObjMap.success)
                    return rtnObjMap
                return { success:false, fallback:true, errmsg:errmsg }
            }
        }
    }

    ; the language file exists; get the corresponding data
    fileInfo := CLocale.GetLocaleInfoSet(sID)
    ; -> Object (`LCID`, `IsoTag`, `Name`, `Native`, `Parent`)
    if (!IsObject(fileInfo)) {
        errmsg := CLocale.ErrAppend(errmsg
            , "'" sID "' language data not found")
        if (rtnObjMap.success)
            return rtnObjMap
        return { success:false, fallback:fallback, errmsg:errmsg }
    }

    local _lang := sID
    local _name := fileInfo["Name"]

    local _tag, _lcid
    if (CLocale.GetIDType(sID)=="ISO") {
        _tag  := sID
        _lcid := CLocale.LocaleNameToLCID(sID)
    }
    else {
        _tag  := CLocale.LCIDToLocaleName(sID)
        _lcid := sID
    }

    ; final check of lang_path:

    if (!StrLen(FileExist(lang_path))) {
        errmsg := CLocale.ErrAppend(errmsg
                    , "Language file `n'" lang_path "'`nnot found")
        if (rtnObjMap.success)
            return rtnObjMap
        return { success:false, fallback:fallback, errmsg:errmsg }
    }

    local msg := CLocale.IniFileDupeCheck(lang_path)
    if (StrLen(msg)) {
        if (rtnObjMap.success)
            return rtnObjMap
        return { success:false, fallback:fallback, errmsg:msg }
    }
    g_ini_path  := ini_path
    g_lang_path := lang_path
    g_lang_id   := sID
    g_docs_path := docs_path

    local rtnObjFile := { success:true, fallback:fallback, errmsg:msg
            , langID:sID, langName:_name, isoTag:_tag, lcid:_lcid, langMap:false
            , iniPath:ini_path, langPath:lang_path, docsPath:docs_path
            , sLangFolder:LTrim(sLangFolder, "\ "), sName:sName
            , mapPriority:mapPriority }

    if (rtnObjMap.success)
    {
        ; both succeeded:

        if (rtnObjFile.fallback)
            return rtnObjMap

        if (rtnObjMap.fallback)
            return rtnObjFile

        if (mapPriority)
            return rtnObjMap
        else
            return rtnObjFile
    }
    ; Map failed, File succeeded
    return rtnObjFile
} ; /OneLocale_Init

;///////////////////////////////////////////////////////////////////////////////
class CLocale
{
    /**********************************************
     * #### CBoolean: convert an unknown variable into a Boolean
     * <!--
     * @version 2025-11-03
     * -->
     */
    static CBoolean(v)
    {
        if (!IsSet(v))
            return false

        if (IsObject(v)) {
            local vv := ""
            try vv := v.Value
            if (StrLen(vv))
                return CLocale.CBoolean(vv)
            try vv := v.Text
            if (StrLen(vv))
                return CLocale.CBoolean(vv)
            return true
        }

        if (IsNumber(v)) {
            if (Round(v) != 0)
                return true
            return false
        }

        if (v = "true") ; non case sensitive
            return true
        return false
    }

    /**********************************************
     * #### ErrAppend: append to error message with delimiter
     *
     * @param {String} sBase - existing error message, which may be empty
     * @param {String} sAppend - message to be added
     * @param {String} sDelim - message separator; default two newlines
     * @return {String} joined error message
     */
    static ErrAppend(sBase, sAppend, sDelim:="`n`n")
    {
        if (StrLen(sBase))
            return sBase sDelim sAppend
        return sAppend
    }

    /**********************************************
     * #### ErrDecode: format common error messages for IniReadEx and MapRead(Ex)
     *
     * @param {Integer} errcode
     * -  1 = bad map lang_id
     * -  2 = bad map section
     * -  3 = bad map key
     * - (etc)
     * @param {String} lang_id_or_path - a language ID (maps) or .LANG path (files)
     * @param {String} sSection - section name
     * @param {String} sKey - key name
     * @returns {String} formatted error message
     * <!--
     * @version 2025-10-31
     * -->
     */
    static ErrDecode(errcode, lang_id_or_path, sSection:=unset, sKey:=unset)
    {
        if (!IsSet(sSection))
            sSection := "(unset)"
        if (!IsSet(sKey))
            sKey := "(unset)"

        local pre := "err #" errcode ": "
        switch (errcode) {
            case 1:  return pre "g_lang_map: submap '" lang_id_or_path "' not found"
            case 2:  return pre "g_lang_map['" lang_id_or_path "']: section '" sSection "' not found"
            case 3:  return pre "g_lang_map['" lang_id_or_path "']['" sSection "']: key " sKey "' not found"

            case 10: return pre lang_id_or_path " :`nsection '" sSection "' not found"
            case 11: return pre lang_id_or_path " :`nsection '" sSection "', key '" sKey "' not found"

            case 31: return pre lang_id_or_path " :`noptional [':extenders:'] not present"
            case 32: return pre lang_id_or_path " :`n[':extenders:']['[section]'] not found"
            case 33: return pre lang_id_or_path " :`n[':extenders:']['[section]'] not a valid Array"

            case 99: return pre "g_lang_map['" lang_id_or_path "']: section '" sSection "' unexpected error"
            default: return pre "unexpected error code"
        }
    }

    /********************
     * #### FindBestFile - find file with most compatible language tag
     *
     * @param {String} sID - An ISO 639-style Tag ('en', 'fr') _OR_
     *   A 4-hex-digit LCID ('0409', '000C') (with or without '0x' prefix)
     *
     * @param {String} sFallback - fallback value for `sID` (ASSUMED TO BE GOOD)
     *
     * @param {String} sFolder - target folder, relative to script path
     *
     * @param {String} sTemplate - a pattern that matches your file names
     *
     * @param {String} errmsg - [OUT, Optional] any error messages
     *
     * @return {String} valid sID
     * <!--
     * @version 2025-09-12
     * -->
     */
    static FindBestFile(sID, sFallback, sFolder, sTemplate, &errmsg:="")
    {
        local sPatt:="", sTmp:="", loopCount:=0, info:={}

        if (!InStr(sTemplate, "/TAG/"))
        {
            info := CLocale.GetLocaleInfoSet(sID)
            ; -> Object (`LCID`, `IsoTag`, `Name`, `Native`, `Parent`)
            if (IsObject(info))
                return sID
            return sFallback
        }

        ; insert sID in sTemplate in place of 'TAG', call the result 'sPatt'
        sPatt := StrReplace(sTemplate, "/TAG/", sID)

        ; scan sFolder for file name(s) that match sPatt
        sTmp := sID
        loopCount := 128 ; sanity check
        while (loopCount--)
        {
            if (StrLen(FileExist(sFolder "\" sPatt))) {
                break ; success
            }
            errmsg .= "FindBestFile: '" sPatt "' not found`n"

            info := CLocale.GetLocaleInfoSet(sTmp)
            ; -> Object (`LCID`, `IsoTag`, `Name`, `Native`, `Parent`)
            if (!IsObject(info))
                break ; failure

            if (CLocale.GetIDType(sTmp)=="LCID") {
                ; try the corresponding ISO:
                sTmp  := info["IsoTag"]
                sPatt := StrReplace(sTemplate, "/TAG/", sTmp)
                if (StrLen(FileExist(sFolder "\" sPatt))) {
                    break ; success
                }
            }
            else {
                ; try the corresponding LCID:
                sTmp  := info["LCID"]
                sPatt := StrReplace(sTemplate, "/TAG/", sTmp)
                if (StrLen(FileExist(sFolder "\" sPatt))) {
                    break ; success
                }
            }

            ; try the Parent:
            sTmp := info["Parent"]
            if (!StrLen(sTmp))
                break ; failure
            sPatt := StrReplace(sTemplate, "/TAG/", sTmp)
        } ; /while

        if (!StrLen(sTmp))
            return sFallback
        return sTmp
    } ; /FindBestFile

    /********************
     * #### FindBestMap - find Map with most compatible language tag
     *
     * @param {String} sID - An ISO 639-style Tag ('en', 'fr') _OR_
     *   A 4-hex-digit LCID ('0409', '000C') (with or without '0x' prefix)
     *
     * @param {String} sFallback - fallback value for `sID` (ASSUMED TO BE GOOD)
     *
     * @param {String} errmsg - [OUT, Optional] any error messages
     *
     * @return {String} valid sID
     * <!--
     * @version 2025-11-04
     * -->
     */
    static FindBestMap(sID, sFallback, &errmsg:="")
    {
        global g_lang_map
        local info, sTmp
        local mapMaps := Map()

        errsg := ""
        if !(g_lang_map Is Map)
        {
            errmsg := "error: g_lang_map is not initialized"
            return sFallback
        }

        if (g_lang_map.Has(sID))
        {
            mlng := g_lang_map[sID]
            if (IsObject(mlng) && (mlng Is Map)
            && mlng.Has(":lang_id:") && mlng[":lang_id:"] == sID)
            {
                errmsg := ""
                return sID
            }
            errmsg .= "error: g_lang_map['" sID "'] not valid`n"
        }

        info := CLocale.GetLocaleInfoSet(sID)
        ; -> Object (`LCID`, `IsoTag`, `Name`, `Native`, `Parent`)
        if (!IsObject(info))
        {
            errmsg := "error: not a valid language ID; returning fallback"
            return sFallback
        }

        if (CLocale.GetIDType(sID)=="LCID")
        {
            ; try the corresponding ISO:
            sTmp := info["IsoTag"]
            if (g_lang_map.Has(sTmp))
            {
                mlng := g_lang_map[sTmp]
                if (IsObject(mlng) && (mlng Is Map)
                && mlng.Has(":lang_id:") && mlng[":lang_id:"] == sTmp)
                {
                    errmsg := "returning ISO tag"
                    return sTmp
                }
                errmsg .= "error: g_lang_map['" sTmp "'] not valid`n"
            }
        }
        else {
            ; try the corresponding LCID:
            sTmp := info["LCID"]
            if (g_lang_map.Has(sTmp))
            {
                mlng := g_lang_map[sTmp]
                if (IsObject(mlng) && (mlng Is Map)
                && mlng.Has(":lang_id:") && mlng[":lang_id:"] == sTmp)
                {
                    errmsg := "returning LCID"
                    return sTmp
                }
                errmsg .= "error: g_lang_map['" sTmp "'] not valid`n"
            }
        }

        ; try the Parent:
        sTmp := info["Parent"]
        if (g_lang_map.Has(sTmp))
        {
            mlng := g_lang_map[sTmp]
            if (IsObject(mlng) && (mlng Is Map)
            && mlng.Has(":lang_id:") && mlng[":lang_id:"] == sTmp)
            {
                errmsg .= "returning parent language"
                return sTmp
            }
            errmsg .= "error: g_lang_map['" sTmp "'] not valid`n"
        }
        errmsg .= "returning fallback"
        return sFallback
    } ; /FindBestMap

    /**********************************************
     * #### GetIDType: determine language ID type and enforce its validity
     *
     * @param {String} sID - an ISO 639-style Tag ('en', 'es', 'de', 'fr' etc.),
     * > OR a 4-hex-digit LCID ('0x0409') (an `A_Language` value, with or without a '0x' prefix)
     *
     * @return {String} "LCID", "ISO" or ""
     */
    static GetIDType(sID)
    {
        local m
        if (RegExMatch(sID, "^([a-z]+)([-][a-z-]+)?" , &m)) {
            return "ISO"
        }
        else if (RegExMatch(sID, "^(0x)?([0-9A-F]{4,4})" , &m)) {
            return "LCID"
        }
        return ""
    } ; /GetIDType

    /**********************************************
     * #### GetLocaleInfo: retrieves information about a locale specified by identifier
     *
     * <https://learn.microsoft.com/en-us/windows/win32/api/winnls/nf-winnls-getlocaleinfoa>
     *
     * @param {String} sID - the empty string (use the current locale),
     *   > OR an ISO 639 Tag
     *
     * @param {Integer} LCType - see WinNls.h and `GetLocaleInfoSet()` for examples
     *
     * @return {String}
     */
    static GetLocaleInfo(sID, LCType)
    {
        local nSize, out
        if (!StrLen(sID) || sID=="0") {

            ; if sID is empty or 0, use LOCALE_NAME_USER_DEFAULT (== 0)
            nSize := DllCall("GetLocaleInfoEx"
                        , "Ptr" , 0
                        , "UInt", LCType
                        , "Ptr" , 0
                        , "UInt", 0)
            if (!nSize)
                return false
            out := Buffer(nSize * 2) ; VarSetCapacity
            nSize := DllCall("GetLocaleInfoEx"
                        , "Ptr" , 0
                        , "UInt", LCType
                        , "Ptr" , out
                        , "UInt", out.Size)
        }
        else {
            nSize := DllCall("GetLocaleInfoEx"
                        , "Str" , sID
                        , "UInt", LCType
                        , "Ptr" , 0
                        , "UInt", 0)
            if (!nSize)
                return ""
            out := Buffer(nSize * 2) ; VarSetCapacity
            nSize := DllCall("GetLocaleInfoEx"
                        , "Str" , sID
                        , "UInt", LCType
                        , "Ptr" , out
                        , "UInt", out.Size)
        }
        if (!nSize)
            return ""
        return StrGet(out)
    } ; /GetLocaleInfo

    /**********************************************
     * #### GetLocaleInfoSet: get language data
     *
     * @param {String} sID - ISO 639-style Tag ('en', 'es', 'de', 'fr' etc.),
     *   > OR a 4-hex-digit LCID ('0x0409')
     *   > (an `A_Language` value, with or without a '0x' prefix)
     *
     * @return {Map|Integer} (`LCID`, `IsoTag`, `Name`, `Native`, `Parent`),
     *    or zero (false) on failure
     * <!--
     * @version 2024-09-16
     * @version 2024-09-20 add 'TimeFormat', 'DateFormat'
     * @version 2025-09-09 remove dependency on IniFiles.ahk
     * @version 2025-09-17 remove extraneous nfo members
     * -->
     */
    static GetLocaleInfoSet(sID)
    {
        local tagType, sLCID, DisplayName, NativeName, Parent

        ;<include file="/Projects/ExternalProjects/WinAPI-headers/WinNls.h">(468)
        ;https://learn.microsoft.com/en-us/windows/win32/api/winnls/nf-winnls-getlocaleinfoex
        ;https://learn.microsoft.com/en-us/windows/win32/intl/locale-ineg-constants

        if (!StrLen(sID))
            return 0

        tagType := CLocale.GetIDType(sID)
        if (tagType=="ISO") {
            ; ISO 639
            sLCID := CLocale.LocaleNameToLCID(sID)
            ;sID := (no change)
        }
        else if (tagType=="LCID") {
            ; 4-hex-digit LCID
            sLCID := SubStr("0x" sID, -4)
            sID   := CLocale.LCIDToLocaleName(Round("0x" sLCID))
        }
        else {
            return 0
        }

        static LOCALE_SLOCALIZEDDISPLAYNAME  := 0x00000002   ; localized name of locale, eg "German (Germany)" in UI language
        static LOCALE_SNATIVEDISPLAYNAME     := 0x00000073   ; Display name in native locale language, eg "Deutsch (Deutschland)
        static LOCALE_SPARENT                := 0x0000006d   ; Fallback name for resources, eg "en" for "en-US"

        DisplayName := CLocale.GetLocaleInfo(sID, LOCALE_SLOCALIZEDDISPLAYNAME)
        NativeName  := CLocale.GetLocaleInfo(sID, LOCALE_SNATIVEDISPLAYNAME)
        Parent      := CLocale.GetLocaleInfo(sID, LOCALE_SPARENT)

        return Map("LCID"      , sLCID
                , "IsoTag"     , sID
                , "Name"       , DisplayName
                , "Native"     , NativeName
                , "Parent"     , Parent )
    } ; /GetLocaleInfoSet

    /**************************************************
     * #### IniFileDupeCheck: check for duplicate sections & keys in .INI file
     *
     * - Check for duplicate section names
     * - Check for duplicate keys within each section
     *
     * @param {String} ini_path - the .INI file path
     *
     * @return {String} error message if duplicate found, else empty string
     * <!--
     * @version 2025-09-21
     * -->
     */
    static IniFileDupeCheck(ini_path)
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
    } ; /IniFileDupeCheck

    /**************************************************
     * #### IniReadEx: IniRead that looks in extender files
     *
     * Works like [IniRead](https://www.autohotkey.com/docs/v2/lib/IniRead.htm), with the added
     * feature that if the requested item  (Key or Section name) is not found in the
     * main .INI file, this function looks into _extender_ files.
     *
     * Extender files are listed in a special .INI section named ':extenders:'.
     *
     * Finally, if the search is exhausted, `sDefault` is returned if it's been set,
     * or an Error is raised if it's not - just like `IniRead`.
     *
     * Extenders can be incorporated into many projects as a __common repository__.
     *
     * ##### Example
     *
     * ```ini
     * ; MyScript-[en].lang
     * [gui]
     * title = MyScript
     * [:extenders:]
     * base = ..\base.lang
     * ```
     *
     * Extender __names__ are required; allowed names follow rules for [variable names](
     * https://www.autohotkey.com/docs/v2/Concepts.htm#names)
     *
     * - They must have only Letters, digits, underscore and non-ASCII characters
     *   (no brackets, braces, slashes, whitespace etc).
     * - The regular expression for valid names is `(*UCP)^[\w]*$`
     * - Names must be unique in `sPath`.
     *
     * Extender __paths__ may be absolute or relative to `sPath`
     *
     * - May fail for paths on mapped drive letters
     * - Share paths seem to work, but they are slow when first accessed.
     *  Short names (forced by Windows to 8.3 form) may not work.
     * - Symbolic links seem to work.
     * - `\\?\` (long name enable) prefixed paths are supported,
     *   and are added if needed on long paths.
     *
     * Extenders are checked in order until the requested item is found
     *
     * If the requested item is not found in any of the extenders, `sDefault` is returned;
     *   if there is no `sDefault`, a catchable Error is thrown.
     *
     * @param {String} sPath - full path of .INI file (.LANG files are .INI files)
     *
     * @param {String} sSection - section name within .INI file;
     *     the heading that appears in square brackets (do not include the brackets)
     *
     *  - Unlike `IniRead`, here you can _not_ omit the section
     *    to get a linefeed (`n) delimited list of section names.
     *
     * @param {String} sKey        - the key name in the .ini file;
     *                               if unset, read entire section
     *                               default=(unset)
     *
     * @param {String} sDefault    - value to return in case of error or item not found;
     *                               default=(unset)
     *
     * @return {String} value of the requested Section or Key; `sDefault` on error
     *
     * @throws
     *     Like `IniRead`, an Error is thrown on failure, but only if `sDefault` is omitted;
     *     an Error is also thrown if an extender name is illegal.
     * <!--
     * @version 2025-10-18 final
     * @version 2025-10-24 simplify - no nested extenders
     * -->
     */
    static IniReadEx(sPath, sSection, sKey:=unset, sDefault:=unset)
    {
        local e, errmsg := ""

        ; to catch errors, do NOT supply sDefault at this point
        local vv := ""
        try {
            if (IsSet(sKey)) {
                vv := IniRead(sPath, sSection, sKey)
            }
            else {
                vv := IniRead(sPath, sSection)
            }
        }
        catch Error as e {
            errmsg := e.Message ; eg, "The requested key, section or file was not found."
            ; continue the search...
        }
        else {
            return vv ; successfully read the value
        }

        ; --------------------------------------------------------------------
        ; if here, did not find the requested item - look in the extender file(s)
        ; --------------------------------------------------------------------

        local sExtends := IniRead(sPath, ":extenders:", , "") ; zero-length default
        if (StrLen(sExtends))
        {
            local arExtends := StrSplit(sExtends, "`n", "`r`t ")
            local iEx, vEx
            for iEx, vEx in arExtends
            {
                vEx := CLocale.PathRelativeTo(vEx, sPath)
                if (!StrLen(FileExist(vEx)))
                    continue

                ; to catch errors, do NOT supply sDefault at this point
                vv := ""
                try {
                    if (IsSet(sKey)) {
                        vv := IniRead(vEx, sSection, sKey)
                    }
                    else {
                        vv := IniRead(vEx, sSection)
                    }
                }
                catch Error as e {
                    errmsg := e.Message
                    ; continue the search...
                }
                else {
                    return vv ; successfully read the value
                }
            } ; /for each arExtends
        } ; /StrLen(sExtends)

        if (IsSet(sDefault)) {
            return sDefault
        }
        throw Error("Requested item was not found.")
    } ; /IniReadEx

    /**********************************************
     * #### LCIDToLocaleName: converts a locale identifier to a locale name
     * https://learn.microsoft.com/en-us/windows/win32/api/winnls/nf-winnls-LCIDToLocaleName
     *
     * @param {Integer} nLCID - an LCID (e.g. `0x0409`)
     *
     * @return {String} ISO 639 Tag
     */
    static LCIDToLocaleName(nLCID)
    {
        local nSize, buf
        ; Flag to allow returning neutral names/lcids for name conversion
        static LOCALE_ALLOW_NEUTRAL_NAMES    := 0x08000000

        nSize := DllCall("LCIDToLocaleName"
                    , "UInt", nLCID
                    , "Ptr" , 0
                    , "UInt", 0
                    , "UInt", LOCALE_ALLOW_NEUTRAL_NAMES)

        buf := Buffer(nSize * 2) ; VarSetCapacity
        nSize := DllCall("LCIDToLocaleName"
                    , "UInt", nLCID
                    , "Ptr" , buf
                    , "UInt", buf.Size
                    , "UInt", LOCALE_ALLOW_NEUTRAL_NAMES)

        return StrGet(buf)
    }

    /**********************************************
     * #### LocaleNameToLCID: converts a locale name to a locale identifier
     *
     * <https://learn.microsoft.com/en-us/windows/win32/api/winnls/nf-winnls-LocaleNameToLCID>
     *
     * @param {String} sTag - an ISO 639 Tag (`en`)
     *
     * @return {String} an LCID (`0409`)
     */
    static LocaleNameToLCID(sTag)
    {
        local nLCID
        nLCID := DllCall("LocaleNameToLCID"
                    , "Str", sTag
                    , "Int", 0)

        return Format("{:04X}", nLCID)
    }

    /**************************************************
     * #### MapRead: IniRead for Maps (submaps of `g_lang_data`)
     *
     * Works like [IniRead](https://www.autohotkey.com/docs/v2/lib/IniRead.htm) except
     * for [Maps](https://www.autohotkey.com/docs/v2/lib/Map.htm) with an .INI-like,
     * key=value structure.
     *
     * @param {String} sMapName - name of current Map (a submap of g_lang_data)
     *
     * @param {String} sSection - required section name within Map; cannot be empty
     *
     *  - Unlike `IniRead`, here you can _not_ omit the section
     *    to get a linefeed (`n) delimited list of section names.
     *
     * @param {String} sKey        - the key name in the .ini file;
     *                               if unset, read entire section
     *                               default=(unset)
     *
     * @param {String} sDefault    - value to return in case of error or item not found;
     *                               default=(unset)
     *
     * @return {String} value of the requested Section or Key; `sDefault` on error
     *
     * @throws
     *     Like `IniRead`, an Error is thrown on failure, but only if `sDefault` is omitted
     * <!--
     * @version 2025-10-31
     * -->
     */
    static MapRead(sMapName, sSection, sKey:=unset, sDefault:=unset)
    {
        global g_lang_map
        if (!IsSet(g_lang_map) || !IsObject(g_lang_map) || !(g_lang_map Is Map))
            throw Error("g_lang_map not initialized")
        if (!IsSet(sMapName) || !StrLen(sMapName))
            throw Error("missing sMapName argument")
        if (!IsSet(sSection) || !StrLen(sSection))
            throw Error("missing sSection argument")

        local e, errmsg := "unknown"
        local errcode := 0

        ; look at g_lang_map[<sMapName>][sSection][sKey]
        local sRtn := ""
        try {
            errcode := 1 ; bad lang_id
            local mlng := g_lang_map[sMapName]

            errcode := 2 ; bad section
            local msec := mlng[sSection]

            if (IsSet(sKey)) {
                ;equiv to: IniRead(sPath, sSection, sKey)
                errcode := 3 ; bad key
                sRtn := msec[sKey]
            }
            else {
                ;equiv to: IniRead(sPath, sSection)
                errcode := 99 ; unexpected error
                local k, v
                for k, v in msec["[section]"] {
                    sRtn .= v "`n"
                }
            }
        }
        catch Error as e {
            if (IsSet(sDefault))
                return sDefault
            errmsg := CLocale.ErrDecode(errcode, sMapName, sSection, sKey)
            throw Error(errmsg "`n" e.Message)
        }
        return sRtn
    } ; /MapRead

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

    /**************************************************
     * #### sE - expand named variables in a string
     *
     * * replace named variables (enclosed in `%`) using `args`
     * * replace `\t` with tab char
     * * replace `\n` with newline
     * * remove all beyond `\z`
     * * to pass a literal `%`, use `\\%`
     * * to pass a literal `\\`, use `\\\\`
     * * To _remove_ a newline, use `\w` before or after it (this is to ignore a
     *   line break in multiline text, letting the Gui element handle Word Wrap)
     *
     * @param {String} s - a string with any variable names wrapped in `%`
     *
     * @param {Object} args - names and values: `{book:"HHGTTG", answer:42}`
     *
     * @return {String} the expanded string
     *
     * ##### Example
     *
     * ```AutoHotkey
     *   sE("The temperature in %city% is %temp%F", {city:"Chicago", temp:44})
     * ```
     * Result: `The temperature in Chicago is 44F`
     * <!--
     * @version 2023-02-20 wrote it
     * @version 2023-11-29 moved variable expansion code from sT()
     * @version 2023-11-29 ported to AHK 2
     * @version 2023-12-17 remove redundant argument checks; limit 1000 name-value pairs
     * @version 2025-09-21 '\w' word wrap
     * -->
     */
    static sE(s, args:="")
    {
        if (!StrLen(s))
            return ""

        ; support escaped '\'
        s := StrReplace(s, "\\", "`b")

        ; remove all beyond '\z'
        ; (replace '\z' w/ '`v' (vert tab) because StrSplit only uses 1-char delimiters)
        s := StrSplit(StrReplace(s, "\z", "`v"), "`v")[1]

        ; replace '\t' with tab char
        ; replace '\n' with newline
        ; replace '\%' with vert tab (re-used from StrSplit call above)
        s := StrReplace(s, "\t", "`t")
        s := StrReplace(s, "\n", "`n")
        s := StrReplace(s, "\%", "`v")

        s := StrReplace(s, "`n\w", " ")
        s := StrReplace(s, "\w`n", " ")

        if (IsObject(args))
        {
            enn := args
            if !(args is Map)
                enn := args.OwnProps()

            local sKey, sValue, replCount:=0
            for sKey, sValue in enn
            {
                if (A_Index > 1000) {
                    throw Error("OneLocale: too many names (limit 1000)", -1)
                }
                s := StrReplace(s, ("%" sKey "%"), sValue, , &replCount, 1000)
                if (replCount >= 1000) {
                    throw Error("OneLocale: too many %" sKey "% replacements "
                    . "(limit 1000 to prevent a runaway expansion)", -1)
                }
            }
        }
        s := StrReplace(s, "`v", "%")
        s := StrReplace(s, "`b", "\")
        return s
    } ; /sE

    /**************************************************
     * #### StringToVariable: Convert arbitrary string into a legal variable name
     * <!--
     * @version 2023-03-26 as CStringUtils.StringToVariable
     * @version 2025-11-05 simplified for processing ISO 639-style language tags
     * -->
     */
    static StringToVariable(s)
    {
        s := Trim(s)
        if (!StrLen(s))
            return ""

        ; replace illegal chars w/ underscore
        s := RegExReplace(s, "i)[^a-z0-9_]", "_")    ; ASCII chars only
        ;s := RegExReplace(s, "[^\w\p{L}\p{N}]", "_") ; non-ASCII chars accepted

        ; condense consecutive underscores
        while (InStr(s, "__") > 0)
            s := StrReplace(s, "__", "_")

        ; if `s` has no legal characters, return empty string
        if (!StrLen(s))
            return ""

        ; limit output length
        return SubStr(s, 1, 1024)
    }
} ; /CLocale

; (end)
