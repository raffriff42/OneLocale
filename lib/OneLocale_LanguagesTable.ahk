#Requires AutoHotkey v2.0

;; (Table of Contents)
;   GetLanguagesTable(printToDebug)
;   GetLanguagesTable_GetLocaleInfoSet(sID)

#Include "OneLocale.ahk"

/**********************************************
 * #### GetLanguagesTable: get language database indexed by LCID
 *
 * - Language Tags sourced from [Microsoft](
 *     https://learn.microsoft.com/en-us/openspecs/windows_protocols/ms-lcid/a9eac961-e77d-41a6-90a5-ce1a8b0cdb9c)
 *   (scroll down to Table 2)
 *
 * @param {Boolean} printToDebug - if true, print table to debugger
 *                                 in fixed-width format; default false
 *
 * @return {Map} of Maps, indexed by LCID; each 'row' consists of:
 * ```text
 *   Key=LCID  ('0409')
 *   Value=Map:
 *     'LCID'         ('0409')
 *     'IsoTag'       ('en-US')
 *     'Name'         ('English (United States)')
 *     'Parent'       ('en')
 *     'DecimalPt'    ('.')
 *     'GroupChar'    (',')
 *     'DigitGroup'   ('3;0')
 *     'TimeFormat'   ('h:mm:ss')
 *     'DateFormat'   ('yyyy/mm/dd')
 *     'NegFormat'    ( '(n)', '-n', '- n', 'n-' or 'n -' )
 * ```
 * <!--
 * @version 2024-09-19
 * -->
 */
GetLanguagesTable(printToDebug:=false)
{
    local ar, first, sLCID, info, args
    ar := Map()
    first := true
    loop 0xFFFF
    {
        sLCID := Format("{:04X}", A_Index)

        ;; Skip default and transient LCIDs
        if (RegexMatch(sLCID, "(04|08|0C|14|20|24|28|2C|30|34|38|3C|40|44|48|4C)00"))
            continue
        LocaleName := CLocale.LCIDToLocaleName(A_Index)

        ;; Skip unknown LCIDs
        if not LocaleName
            continue

        info := GetLanguagesTable_GetLocaleInfoSet(LocaleName)
        ;
        ;    Map('LCID', 'IsoTag', 'Name', 'Parent'
        ;      , 'DecimalPt', 'GroupChar', 'DigitGroup'
        ;      , 'TimeFormat', 'DateFormat', 'NegFormat')

        if (printToDebug) {
            args := [ "LCID:`t'"      sLCID "'"
                    , "Tag:`t"        info["IsoTag"]
                    , "NegFmt:`t"     info["NegFormat"]
                    , "Group:`t"      info["DigitGroup"]
                    , "GroupChar:`t'" info["GroupChar"] "'"
                    , "DecimalPt:`t'" info["DecimalPt"] "'"
                    , "TimeFormat:`t" info["TimeFormat"]
                    , "DateFormat:`t" info["DateFormat"]
                    , "Layout:`t"     info["Layout"]
                    , "Name:`t"       info["Name"]
                    , "Native:`t"     info["Native"] ]
            DebugOutColumns("", 48, args, first) ; IniFiles.ahk
            first := false
        }
        ar[sLCID] := info
    }
    return ar
}

/**********************************************
 * #### GetLanguagesTable_GetLocaleInfoSet - get language data
 *
 * - see {@link CLocale.GetLocaleInfoSet} - different return fields
 *
 * @param {String} sID - ISO 639-style Tag (`en`, `es`, `de`, `fr` etc.)
 * - _OR _a 4-hex-digit LCID (`0x0409`; an `A_Language` value, with or without a `0x` prefix)
 *
 * @return {Map} (`LCID`, `IsoTag`, `Name`, `Parent`, `DecimalPt`
 *  , `GroupChar`, `DigitGroup`, `TimeFormat`, `DateFormat`, `NegFormat`)
 *
 * - `NegFormat` is one of ( `(n)`|`-n`|`- n`|`n-`|`n -` )
 * <!--
 * @version 2024-09-16
 * @version 2024-09-20 add 'TimeFormat', 'DateFormat'
 * @version 2025-09-09 remove dependency on IniFiles.ahk
 * -->
 */
GetLanguagesTable_GetLocaleInfoSet(sID)
{
    local tagType, sLCID, DisplayName, Parent, DecimalSep, ThousandSep
    local DigitGroup, TimeFormat, DateFormat, nn, NegFormat
    ;<include file="/Projects/ExternalProjects/WinAPI-headers/WinNls.h">(468)
    ;https://learn.microsoft.com/en-us/windows/win32/api/winnls/nf-winnls-getlocaleinfoex
    ;https://learn.microsoft.com/en-us/windows/win32/intl/locale-ineg-constants

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
        return ""
    }

    static LOCALE_SLOCALIZEDDISPLAYNAME  := 0x00000002   ; localized name of locale, eg "German (Germany)" in UI language
    ;static LOCALE_SENGLISHDISPLAYNAME    := 0x00000072   ; Display name (language + country/region usually) in English, eg "German (Germany)"
    static LOCALE_SNATIVEDISPLAYNAME     := 0x00000073   ; Display name in native locale language, eg "Deutsch (Deutschland)

    DisplayName := CLocale.GetLocaleInfo(sID, LOCALE_SLOCALIZEDDISPLAYNAME)
    NativeName  := CLocale.GetLocaleInfo(sID, LOCALE_SNATIVEDISPLAYNAME)

    static LOCALE_SPARENT         := 0x0000006d   ; Fallback name for resources, eg "en" for "en-US"
    static LOCALE_SDECIMAL        := 0x0000000E   ; decimal separator, eg "." for 1,234.00
    static LOCALE_STHOUSAND       := 0x0000000F   ; thousand separator, eg "," for 1,234.00
    static LOCALE_SGROUPING       := 0x00000010   ; digit grouping, eg "3;0" for 1,000,000
    static LOCALE_SSHORTDATE      := 0x0000001F   ; short date format string, eg "MM/dd/yyyy"
    static LOCALE_SDURATION       := 0x0000005d   ; time duration format, eg "hh:mm:ss"
    static LOCALE_SNEGATIVESIGN   := 0x00000051   ; negative sign, eg "-"
    static LOCALE_INEGNUMBER      := 0x00001010   ; negative number mode

    Parent      := CLocale.GetLocaleInfo(sID, LOCALE_SPARENT)
    DecimalSep  := CLocale.GetLocaleInfo(sID, LOCALE_SDECIMAL)
    ThousandSep := CLocale.GetLocaleInfo(sID, LOCALE_STHOUSAND)
    DigitGroup  := CLocale.GetLocaleInfo(sID, LOCALE_SGROUPING)
                                ; Examples:
                                ; 3;0     3,000,000,000,000 (US)
                                ; 3;2;0  30,00,00,00,00,000 (Indic locales)
                                ; 3          3000000000,000
                                ; 3;2       30000000,00,000

    TimeFormat  := CLocale.GetLocaleInfo(sID, LOCALE_SDURATION)
    DateFormat  := CLocale.GetLocaleInfo(sID, LOCALE_SSHORTDATE)

    ;NegSign     := CLocale.GetLocaleInfo(sID, LOCALE_SNEGATIVESIGN) ; always '-'
    nn          := CLocale.GetLocaleInfo(sID, LOCALE_INEGNUMBER)
    switch (nn) {
    case 0:
            NegFormat := "(n)"
    case 1:
            NegFormat := "-n"
    case 2:
            NegFormat := "- n"
    case 3:
            NegFormat := "n-"
    case 4:
            NegFormat := "n -"
    default:
            Assert(false, "GetLocaleInfoSet: Unexpected LOCALE_INEGNUMBER value")
            NegFormat := "-n"
    }

    static LOCALE_IREADINGLAYOUT := 0x0070 ; Returns one of the following 4 reading layout values:
                                           ;  0 - Left to right (eg en-US)
                                           ;  1 - Right to left (eg arabic locales)
                                           ;  2 - Vertical top to bottom with columns to the left and also left to right (ja-JP locales)
                                           ;  3 - Vertical top to bottom with columns proceeding to the right
    dir := CLocale.GetLocaleInfo(sID, LOCALE_IREADINGLAYOUT)
    switch (dir) {
    case 0:
            Layout := "ltr"
    case 1:
            Layout := "rtl"
    case 2:
            Layout := "ja-JP"
    case 3:
            Layout := "vert"
    default:
            Assert(false, "GetLocaleInfoSet: Unexpected LOCALE_IREADINGLAYOUT value")
            Layout := "ltr"
    }

    return Map("LCID"      , sLCID
            , "IsoTag"     , sID
            , "Name"       , DisplayName
            , "Native"     , NativeName
            , "Parent"     , Parent
            , "DecimalPt"  , DecimalSep
            , "GroupChar"  , ThousandSep
            , "DigitGroup" , DigitGroup
            , "Layout"     , Layout
            , "TimeFormat" , TimeFormat
            , "DateFormat" , DateFormat
            , "NegFormat"  , NegFormat )
}

/**********************************************
 * #### DebugOutColumns - print a message and data to Debug window
 *
 * @param {String} msg - any string: optional `comment` above preceding column printout
 *
 * @param {Integer} width - column width
 *
 * @param {String} args - tab-separated names & values:
 * . `[name1 A_Tab value1, name2 A_Tab value2...]`
 *
 * @param {Boolean} heading - if true, print names; default false.
 * . this allows printing a heading for the first row only.
 *
 * @param {String} trunc_char - default "$"
 *
 * - if StrLen(trunc_char)==1 and StrLen(msg) > `width`,
 * - trim `msg` to (maxwid-1) and append `trunc_char`;
 * - else, just trim `msg` to `width`
 *
 * ##### Example calls
 *
 * ```AutoHotkey
 * args := [ "TIME:`t`" FormatTime("hh;mm;ss")
 *         , "COLOR:`t" "Red"
 *         , "SPIN:`t`" "Up"
 *         , "ERR:`t`" "" ]
 * DebugOutColumns(">message 1", , args, 1)
 *
 * args := [ "TIME:`t`" FormatTime("hh;mm;ss")
 *         , "COLOR:`t" "Green"
 *         , "SPIN:`t`" "Down"
 *         , "ERR:`t`" "Leap second" ]
 * DebugOutColumns(">message 2", , args, 0)
 * ```
 *
 * ##### Example output
 *
 * ```Text
 * >message 1
 * TIME:           COLOR:         SPIN:          ERR:
 * 14;22;30        Red            Up
 * >message 2
 * 14;22;32        Green          Down           Leap second
 * ```
 * <!--
 * @version 2024-08-15
 * -->
 */
DebugOutColumns(msg:="", width:=16, args:="", heading:=0, trunc_char:="$")
{
    if (StrLen(msg))
        msg := RegExReplace(msg, "[\n\r]+", "\n ")

    if (IsObject(args))
    {
        if (StrLen(msg))
            msg .= "`n"

        local n, v, ar, s1
        if (heading) {
            for n, v in args {
                ar  := StrSplit(v, "`t")
                s1  := StrUpper(ar[1])
                msg .= DebugFormatWidth(s1, width, , , trunc_char)
            }
            msg .= "`n"
        }

        for n, v in args {
            ar := StrSplit(v, "`t")
            s1 := RegExReplace(ar[2], "[\n\r]+", "\n ")
            if (n >= args.Length)
                msg .= s1 ; last column - no need to truncate
            else
                msg .= DebugFormatWidth(s1, width, , , trunc_char)
        }
    }
    OutputDebug msg "`n"
    return
} ; /DebugOutColumns

/**************************************************
 * #### DebugFormatWidth - pad or truncate a string to ensure specified widt
 *
 * @param {String} s - any string
 *
 * @param {Integer} maxwid - maximum width of output string (16.1014)
 *
 * @param {Integer} minwid - minimum width of output string;
 * . default -1 means same as `maxwid`;
 * . if `minwid`==0, this function never adds padding.
 *
 * @param {Boolean} left_just - if true (default), pad to right; else, pad to left
 *
 * @param {String} trunc_char - default "$"
 *
 * - if StrLen(trunc_char)==1 and StrLen(msg)>`width`,
 * - trim `msg` to (maxwid-1) and append `trunc_char`;
 * - else, just trim `msg` to `width`
 * <!--
 * @version 2024-08-15
 * @version 2025-11-12
 * -->
 */
DebugFormatWidth(s, maxwid, minwid:=-1, left_just:=1, trunc_char:="$")
{
    maxwid := Min(Max(16, maxwid), 1024)
    if (minwid < 0)
        minwid := maxwid
    minwid := Min(Max(0, minwid), maxwid)

    local lens     := StrLen(s)
    local maxwid_1 := (maxwid - 1)
    if (StrLen(trunc_char)==1 && lens > maxwid_1)
    {
        s := SubStr(s, 1, maxwid_1) trunc_char
    }
    else if (lens > maxwid)
    {
        s := SubStr(s, 1, maxwid)
    }
    else if (lens < minwid)
    {
        local pad := Format("{:" minwid-lens "}", "")
        s := (left_just)
            ? (s . pad)
            : (pad . s)
    }
    return s
} ; /DebugFormatWidth

; (end)
