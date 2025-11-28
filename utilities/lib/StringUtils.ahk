; StringUtils.ahk
;; String utilities

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
;   class CStringUtils {
;       AddQuotes()
;       AddSQuotes()
;       RemoveQuotes()
;       Requote()
;       ----------------
;       StringIsVariable()
;       StringToVariable()
;       ----------------
;       DropLeadingZeros()
;       DropTrailingZeros()
;       ----------------
;       ValueOf()
;       FloatCompare()
;       FloatsEqual()
;       ----------------
;       ExpandSZ(arg)
;       GetFunc()
;       IsFunc()
;   }

;///////////////////////////////////////////////////////////////////////////////
class CStringUtils
{
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

    /*******************************
     * #### AddSQuotes: Wrap a string in single quotation marks UNLESS it is already quoted
     */
    static AddSQuotes(s)
    {
        static SQ := Chr(39)
        if (!StrLen(s))
            return SQ SQ
        if ((SubStr(s, 1, 1)==SQ) && (SubStr(s, -1, 1)==SQ))
            return s
        return SQ s SQ
    }

    /***********************************************
     * #### RemoveQuotes: remove matched pairs of double- or single-quotes
     *
     * * preserves escaped single-quotes `\'`
     *
     * @param {String} s - input string; must not contain [`b] (ascii 'bell')
     *
     * @param {String} escapeChar - escapes literal `'`; default `\`
     *
     * @param {Integer} limit - number of quote pairs to remove; default -1 ('infinite')
     *
     * @return {String}
     */
    static RemoveQuotes(s, escapeChar:="\", limit:=-1)
    {
        local cnt:=0
        static DQ := Chr(34)
        static SQ := Chr(39)

        if (!InStr(s, DQ) && !InStr(s, SQ))
            return Trim(s)

        escapeChar := SubStr(escapeChar, 1, 1)
        if (!StrLen(escapeChar))
            escapeChar := "\"

        if (limit<0)
            limit := 0x7FFFFFFF

        s := Trim(s)
        s := StrReplace(s, (escapeChar SQ), "`v")

        while ((cnt++ < limit)
          &&   (StrLen(s))
          &&  ((SubStr(s, 1, 1)==DQ && SubStr(s, -1)==DQ)
          ||   (SubStr(s, 1, 1)==SQ && SubStr(s, -1)==SQ)))
        {
            s := SubStr(s, 2, -1)
        }
        s := StrReplace(s, "`v", (escapeChar SQ))
        return s
    }

    /***********************************************
     * #### Requote: add quotes as needed
     *
     * * numbers:
     *   - preserve decimal & hexadecimal
     *   - float is formatted with 6 decimal places
     *
     * * strings (including quoted decimal & hexadecimal)
     *   - remove any existing single- or double-quotes;
     *   - wrap in double-quotes
     */
    static Requote(s)
    {
        local r
        static DQ := Chr(34)

        r := Trim(s)
        if (InStr(r, "0x", true)==1)
        {
            if (IsXDigit(r))
                return Format("0x{:X}", Round(r))
        }
        if (IsInteger(r))
        {
            if (IsDigit(r) || IsDigit(-r))
                return Format("{:d}", Round(r))
            else
                return Format("0x{:X}", Round(r))
        }
        if (IsFloat(r))
            return Format("{:f}", Float(r))

        return (DQ CStringUtils.RemoveQuotes(r) DQ)
    }

    /**************************************************
     * #### StringIsVariable: Returns true if string `s` is not empty and is a legal variable name
     *
     * * 'legal' here is more strict than AHK's definition; it requires that
     *   - first char is any letter A-Z (not case sensitive) and optionally the underscore;
     *   - additional chars are any letter A-Z, the underscore, and the numbers 0-9
     *
     * @param {Boolean } allowLeadingUnderscore -if true, allow the underscore
     *         as the first (and possibly only) character
     * <!--
     * @version 2023-12-02 `allowLeadingUnderscore`
     * -->
     */
    static StringIsVariable(s, allowLeadingUnderscore:=false)
    {
        if (allowLeadingUnderscore)
            return (RegExMatch(s, "i)^[a-z_][a-z0-9_]*$") == 1)
        else
            return (RegExMatch(s, "i)^[a-z][a-z0-9_]*$") == 1)
    }

    /**************************************************
     * #### StringToVariable: Convert arbitrary string into a legal variable name
     *
     * * 'legal' here is more strict than AHK's definition; it requires that
     *   - first char is any letter A-Z (not case sensitive) and optionally the underscore;
     *   - additional chars are any letter A-Z, the underscore, and the numbers 0-9
     *
     * * Processing:
     *   - passes legal names (as defined above) to output unchanged, except `maxLen` enforced
     *   - if `s` has no legal characters, returns empty string
     *   - if `s` begins w/ other than a legal character, prepends `prefix` argument;
     *     so StringToVariable("42") => 'v42'
     *   - replace illegal characters w/ underscore, and condense consecutive underscores into one
     *
     * @param {String} s - string to process
     *
     * @param {Integer} maxLen - limit output to `maxLen` characters; default 58
     *
     * @param {String} prefix - string to prepend if `s` begins w/ other than a legal character;
     *         default "v" (if `prefix` is empty or is not legal, reverts to default)
     *
     * @param {Boolean} allowLeadingUnderscore - true, allow the underscore
     *         as the first (and possibly only) character
     *
     * ##### Example
     * ```text
     *   "1080p"                   => "v1080p"
     *   "Thumbnails [360p, 720p]" => "Thumbnails_360p_720p"
     * ```
     * <!--
     * @version 2023-03-26
     * @version 2023-12-02 `allowLeadingUnderscore`
     * @version 2024-01-15 remove `pretty` option (now always pretty)
     * -->
     */
    static StringToVariable(s, maxLen:=58, prefix:="v", allowLeadingUnderscore:=false)
    {
        ;local
        s := Trim(s)
        if (!StrLen(s))
            return ""

        ; for efficiency, truncate extremely long input strings
        s := SubStr(s, 1, 4 * maxLen)

        if (CStringUtils.StringIsVariable(s, allowLeadingUnderscore))
        {
            ; return legal variable names unchanged, except `maxLen` applies
            return SubStr(s, 1, maxLen)
        }

        ; replace illegal chars w/ underscore
        s := RegExReplace(s, "i)[^a-z0-9_]", "_")

        ; condense consecutive underscores
        while (InStr(s, "__") > 0) {
            s := StrReplace(s, "__", "_")
        }

        if (!allowLeadingUnderscore && SubStr(s, 1, 1)=="_")
            s := SubStr(s, 2)                   ; remove leading underscore

        if (SubStr(s, -2)=="_s" && StrLen(s)>1)
            s := SubStr(s, 1, -2) "s"           ; trailing '_s' => 's'

        if (StrLen(s)>1 && SubStr(s, -1)=="_")
            s := SubStr(s, 1, -1)               ; remove trailing underscore

        ; if `s` has no legal characters, return empty string
        if (!StrLen(s) || (!allowLeadingUnderscore && s == "_"))
            return ""

        ; if `s` begins w/ other than legal character, prepend `prefix`
        if (1==RegExMatch(s, allowLeadingUnderscore ? "i)^[^a-z_].*" : "i)^[^a-z].*"))
        {
            if (prefix=="v" || !CStringUtils.StringIsVariable(prefix, allowLeadingUnderscore))
                s := "v" s
            else
                s := prefix s
        }

        ; limit output to `maxLen` characters
        return SubStr(s, 1, maxLen)
    }

    /**************************************************
     * #### DropLeadingZeros: Drop leading zeros
     */
    static DropLeadingZeros(s)
    {
        local p:="", s2

        ; remove +/- prefix
        s := Trim(s)
        if (RegexMatch(s, "^([+-])(.*)", &m)) {
            p := m[1]
            s := m[2]
        }
        s2 := RegExReplace(s, "^[ \t]*[0]*(.+)", "$1")
        if (SubStr(s2, 1, 1)==".")
            s2 := "0" s2
        if (!StrLen(s2))
            s2 := "0"
        return p s2
    }

    /**************************************************
     * #### DropTrailingZeros: Drop trailing decimal zeros
     */
    static DropTrailingZeros(s)
    {
        local lens, pR

        if (InStr(s, ".")) {

            lens := StrLen(s)
            pR   := lens
            while (SubStr(s, pR, 1)=="0") {
                pR--
            }

            if (SubStr(s, pR, 1)==".") {
                pR--
            }
            if (pR < lens)
                s := SubStr(s, 1, pR)
        }
        return s
    }

    /*****************************************
     * #### ValueOf - return numeric value of a string
     *
     * * stops reading input at first non-numeric character
     *   (scientific notation like "1.0e3" is supported however);
     *   hex strings require `HexPrefix` prefix (default `0x`)
     *
     * @param {String} v - input string
     * @param {Number} nDefault - value to return if `v` not a number; default -999999
     * @param {Integer} nDecimals - number of decimal places (0..9, default 5)
     * @param {String} HexPrefix - required prefix for string to be recognized as a Hex value
     *
     * * (default `0x`; also allowed `\x`, `$`, `#`, `%`, `&H`)
     *
     * @return {String} formatted numeric value
     *
     * ##### Tested behavior
     *
     * ```AutoHotkey
     * ;INPUT               RESULT       COMMENT
     * "hello"            = (nDefault)   ; NaN
     * 100                = "100"
     * "-1a"              = "-1"         ; ignore trailing alpha
     * "1."               = "1.00000"
     * "1.0a"             = "1.00000"    ; ignore trailing alpha
     * "0.1 2023-02-26"   = "0.10000"    ; ignore all after space
     * "1.0e3"            = "1000.00000"
     * "1.0e-3"           = "0.00100"
     * "1.0e2a"           = "100.00000"  ; ignore trailing alpha
     * "1.0e16"           = "10000000000000000.00000"
     * "1e17"             = "1"          ; exponent > 16 not supported
     * "ff"               = (nDefault)   ; NaN
     * "0xff"             = "255"
     * "0XFF"             = "255"
     * "0x100L"           = "256"        ; ignore trailing alpha
     * "-0x100L"          = "-256"
     * "\xFF"             = "255"        ; if HexPrefix==`\x`
     * "&HFF"             = "255"        ; if HexPrefix==`&H`
     * "#FF"              = "255"        ; if HexPrefix==`#`
     * "%20"              = "32"         ; if HexPrefix==`%`
     * ```
     * <!--
     * @version 2023-03-07 `xdigit` handling
     * @version 2023-07-27 `nDecimals`
     * @version 2024-01-10 `Max` to convert numeric string to floating point
     * @version 2024-01-12 rewrite; `HexPrefix`; integer output allowed; unit testing
     * @version 2024-08-12 doc comments - list examples
     * -->
     */
    static ValueOf(v, nDefault:=-999999, nDecimals:=5, HexPrefix:="0x")
    {
        local nDec, hpx, lex, m

        v := Trim(" " v)
        if (!StrLen(v))
            return nDefault

        nDec := Min(Max(0, Round(nDecimals)), 9)

        hpx := HexPrefix
        lex := 1 ; actual length of hex prefix
        if (!StrLen(hpx) || hpx=="0x") {
            hpx := "0[Xx]"
            lex := 2
        }
        else if (hpx=="\x") {
            hpx := "\\[Xx]"
            lex := 2
        }
        else if (hpx=="&H") {
            lex := 2
        }
        else if (hpx=="$" || hpx=="#" || hpx=="%") {
            hpx := "[" hpx "]"
            lex := 1
        }
        else {
            throw Error("ValueOf: bad `HexPrefix` argument", -1)
        }

        if (RegExMatch(v, "^([+-]?[0-9]+)([.][0-9]*)([Ee][+-]?[0-9]+).*", &m)) {
            ; .............(     1     )(    2    )(      3        )
            return Format("{:." nDec "f}", 1.0 * (m[1] m[2] m[3]))
        }
        else if (RegExMatch(v, "^([+-]?[0-9]+)([.][0-9]*).*", &m)) {
            ; ..................(     1     )(    2    )
            return Format("{:." nDec "f}", 1.0 * (m[1] m[2]))
        }
        else if (RegExMatch(v, "^([+-]?)(" hpx "[0-9A-Fa-f]+).*", &m)) {
            ; ..................(  1  )(        2          )
            return ((m[1]=="-")?"-":"") Format("{:d}", ("0x" SubStr(m[2], lex+1)))
        }
        else if (RegExMatch(v, "^([+-]?[0-9]+).*", &m)) {
            ; ..................(     1     )
            return Format("{:d}", m[1])
        }
        return nDefault
    }

    /****************************************
     * #### FloatCompare - compare two floats to `digits` precision
     *
     * @param {Float} f1 - value to be compared
     * @param {Float} f2 - value to be compared
     * @param {Integer} digits - precision (or approximation) of the comparison
     *
     * @return {Integer}
     *   -  0 if `f1` == `f2` to `digits` precision
     *   -  1 if `f1` >  `f2`
     *   - -1 if `f1` <  `f1`
     * <!--
     * @version 2024-08-30
     * -->
     */
    static FloatCompare(f1, f2, digits:=6)
    {
        if (Abs(f1 - f2) < 10**(-digits))
            return 0
        else if (f1 > f2)
            return 1
        return -1
    }

    /****************************************
     * #### FloatsEqual - determine if two floats are equal to `digits` precision
     *
     * @param {Float} f1 - value to be compared
     * @param {Float} f2 - value to be compared
     * @param {Integer} digits - precision (or approximation) of the comparison
     *
     * @return {Boolean} true if `f1` == `f2` to `digits` precision
     * <!--
     * @version 2024-09-07
     * -->
     */
    static FloatsEqual(f1, f2, digits:=6)
    {
        return (0 == CStringUtils.FloatCompare(f1, f2, digits))
    }

    /******************************
    * #### ExpandSZ: replace "%" pairs with Environment values
    *
    * @see more advanced {@link CLocale.sE}
    * <!--
    * @version 2010       wrote it
    * @version 2025-10-04 port from VB6 to AHK
    * -->
    */
    static ExpandSZ(arg)
    {
        pL := InStr(arg, "%", 0, 1)
        while (pL > 0)
        {
            pr := InStr(arg, "%", 0, pL + 1)
            if (!pr) {
                break
            }
            lenFind := pr - pL - 1
            if (lenFind)
            {
                strRepl := EnvGet(SubStr(arg, pL + 1, lenFind))
                lenRepl := StrLen(strRepl)
                if (lenRepl) {
                    arg := SubStr(arg, 1, pL - 1) . strRepl . SubStr(arg, pr + 1)
                }
            }
            pL := InStr(arg, "%", 0, pL + lenRepl)
        }
        return arg
    }

    /**************************************************
     * #### GetFunc: work-alike for AHKv1 'Func()'
     *
     * - per [AHKv1 docs](https://www.autohotkey.com/docs/v1/lib/Func.htm#Func),
     *  `Func()` retrieves a reference to a function given the function's name
     * - this function can't be named `Func` because that name conflicts w/ built-in class `Func`
     *
     * - Constructors like Gui() and Array() ARE NOT CONSIDERED FUNCTIONS
     * - Global functions only - class member functions NOT SUPPORTED
     *
     * <https://www.autohotkey.com/boards/viewtopic.php?f=83&t=134723>
     *
     * @param {String} sFuncName - name of the function whose reference is retrieved
     *
     * @return {Func|Integer} [Func object](https://www.autohotkey.com/docs/v2/lib/Func.htm#Func)
     *                 if the function exists, else 0
     * <!--
     * @version 2025-10-29
     * -->
     */
    static GetFunc(sFuncName)
    {
        if !((sFuncName is String) && StrLen(sFuncName)) {
            return 0
        }

        try {
            local ofn := %sFuncName%
            if !(ofn is Func)
                return 0
            return ofn
        }
        catch {
            return 0
        }
    }

    /**********************************************
     * #### IsFunc: determine if argument is a function name
     *
     * - Constructors like Gui() and Array() ARE NOT CONSIDERED FUNCTIONS
     * - Global functions only - class member functions NOT SUPPORTED
     *
     * <https://www.autohotkey.com/boards/viewtopic.php?p=412444#p412444> (@swagfag)
     *
     * @param {String} sFuncName - the name of the function
     *
     * @return (Boolean) true if argument is a function name
     * <!--
     * @version 2024-09-14
     * @version 2025-09-29 'nMinParams', 'nMaxParams'
     * @version 2025-10-26 remove 'nMinParams', 'nMaxParams'
     * @version 2025-10-29 simplify - use `GetFunc`
     * -->
     */
    static IsFunc(sFuncName)
    {
        return !(0 == CStringUtils.GetFunc(sFuncName))
    }
} ; /CStringUtils

; (end)
