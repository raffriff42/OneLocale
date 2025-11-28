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
;  LoadLangFile(out_map, src_path)
;  BakeLangMap(src_map, src_path, out_path, lang_id)
;  class CLocale_Baker {
;      LoadExtenderFile(out_map, src_path)
;      BakeExtenderMap(fout, ext_map)
;  }
;  writes 'OneLocale_BuildMap_%lang_id%()' function to 'out_path'

/*****************************************
 * ##### LoadLangFile: read a .LANG file, populate Map tree
 *
 * @param {Map}    out_map  - the Map to be populated
 * @param {String} src_path - source .LANG file (.INI files accepted too)
 *
 * @returns {Map} out_map, populated as shown below:
 * ```ini
 * <language ID> {Map} ; eg, "en" - language root, returned by this routine
 *      |-- ":lang_id:" {String} ; ISO tag or LCID code (eg, "fr-CA" or "0C0C")
 *      |-- ":source:"  {String} ; path to source .LANG file
 *      |-- ; ":name:"    {String} ; language name in English   ; eg, "French (Canada)"
 *      |-- ; ":native:"  {String} ; name in its native script  ; eg, "français (Canada)"
 *      |-- ; ":isoTag:"  {String} ; ISO tag for the language   ; eg, "fr-CA"
 *      |-- ; ":lcid:"    {String} ; LCID code                  ; eg, "0C0C"
 *      |-- ; ":parent:"  {String} ; parent language, if any    ; eg, "fr"
 *      |   ; (commented items to be entered later - see OneLocale_Init)
 *      |-- <section-name> {Map} ; eg, "general"
 *      |        |-- key=value
 *      |        |-- key=value...
 *      |        |-- "[section]" {Array} ; raw lines, copied verbatim from .LANG
 *      |-- ; other sections...
 *      |-- ":extenders:" {Map} ; if [:extenders:] section present in .LANG file
 *               |-- ":source:"  {String} ; path to source .LANG file
 *               |-- "[section]" {Array}  ; mixed array of Strings (file paths), and
 *                                        ; Maps (to be populated later from those files)
 * ```
 * @throws {Error} if file cannot be read
 * <!--
 * @version 2025-10-25
 * @version 2025-11-07 revised
 * -->
 */
LoadLangFile(out_map, src_path)
{
    local fin, e
    local sLine, m

    if !(out_map Is Map)
        throw Error("'out_map' is not a Map")

    try {
        fin := FileOpen(src_path, "r")
    }
    catch Error as e {
        throw Error("could not open`n"
                . "'" src_path "'`n"
                . "for reading`n" e.Message)
    }

    local sSec := ""
    local msec := 0
    local asec := 0
    while (!fin.AtEOF)
    {
        sLine := fin.ReadLine()
        if (!StrLen(sLine) || RegExMatch(sLine, "^[ \t]*;"))
        {
            ; blank line or comment
            continue
        }
        else if (RegExMatch(sLine, "^[ \t]*"
                                 . "\["
                                 . "([^\]]+)"
                                 . "\]"
                                 , &m))
        {
            ; found start of section: init new section Map
            msec := Map()

            ; give the section a name
            sSec := m[1]
            msec[":map_name:"] := sSec

            ; add section to 'out_map' by name
            out_map[sSec] := msec

            ; init '[section]' array;
            ;   stores all lines in the section
            asec := []

            ; attach array to section Map
            msec["[section]"] := asec

        }
        else {
            ; a line in the current section:

            ; 1) save the line verbatim in case this is a 'bulk' section
            asec.Push(sLine)

            ; 2) parse 'key = value' line and save key-value pair:
            if (RegExMatch(sLine, "i)^[ \t]*"
                                . "([^ \t=]+)"
                                . "[ \t]*[=][ \t]*"
                                . "([^\r\n]*)$"
                                , &m))
            {
                msec[m[1]] := m[2]
            }
        }
    } ; /fin.AtEOF

    local k
    for k, msec in out_map
    {
        if (msec[":map_name:"] != ":extenders:")
            continue

        ; handle [:extenders:] section - mixed array
        ; - initially all Strings (absolute or relative file paths);
        ; - next section appends Maps (populated from those files)

        asec := msec["[section]"]

        local vExt
        for k, vExt in asec
        {
            ; for each array element in [:extenders:] section
            ; (mixed array of Paths and Maps; ignore any Maps)
            if (vExt Is Map)
                continue

            ; get absolute path:
            vExt := CLocale.PathRelativeTo(vExt, src_path)
            if (!StrLen(FileExist(vExt)))
                continue

            ; init extender Map
            local mExt := Map()
            mExt[":source:"] := vExt

            ; populate extender Map from file
            CLocale_Baker.LoadExtenderFile(mExt, vExt)

            ; append Map to "[section]" Array:
            asec.Push(mExt)
        }
    }
    fin.Close()

    return out_map
} ; /LoadLangFile

/*****************************************
 * ##### BakeLangMap: input Map tree, generate code to rebuild the tree
 *
 * - Writes `OneLocale_BuildMap_%lang_id%()` function to `out_path`
 *   (overwrites any existing file there)
 *
 * @param {String} out_path - file to be created or overwritten
 * @param {Map}    src_map  - source Map tree - see {@link LoadLangFile} return value
 * @param {String} src_path - source file (used as a note in the generated comments ONLY)
 * @param {String} lang_id  - identifier (ISO tag or LCID code) for the current map
 *
 * @returns {Boolean} true on success
 * @throws {Error} if file write fails
 * <!--
 * @version 2025-10-27
 * -->
 */
BakeLangMap(out_path, src_map, src_path, lang_id)
{
    ; open ouput file:
    local fout, e
    try {
        fout := FileOpen(out_path, "w `n", "UTF-8")
    }
    catch Error as e {
        throw Error("could not open`n"
                . "'" out_path "'`n"
                . "for writing`n" e.Message)
    }

    ; write preamble:
    fout.WriteLine("#Requires AutoHotkey v2.0")
    fout.WriteLine("")
    fout.WriteLine("`; AUTO-GENERATED - DO NOT EDIT")
    fout.WriteLine("`; timestamp " A_Now)
    fout.WriteLine("`; generated by OneLocale_Baker.ahk :: BakeLangMap()")
    fout.WriteLine("`; source = " src_path)
    fout.WriteLine("")

    local funcName := "OneLocale_BuildMap_" lang_id
    funcName := CLocale.StringToVariable(funcName)

    ; call 'OneLocale_BuildMap_xx'
    fout.WriteLine(funcName "()")
    fout.WriteLine("")

    ; write start of 'OneLocale_BuildMap_xx' function
    fout.WriteLine("/*****************************************")
    fout.WriteLine(" * ##### " funcName ": initialize global Map 'g_lang_map'")
    fout.WriteLine(" * - Conversion of a .LANG file into a Map tree")
    fout.WriteLine(" */")
    fout.WriteLine(funcName "()")
    fout.WriteLine("{")

    fout.WriteLine("    global g_lang_map")
    fout.WriteLine("    if (!IsObject(g_lang_map))")
    fout.WriteLine("        g_lang_map := Map()")
    fout.WriteLine("")

    ; init output Map:
    fout.WriteLine("    local mlng, msec, msub, asec")
    fout.WriteLine("    mlng := Map()")
    fout.WriteLine("    mlng[`":lang_id:`"] := `"" lang_id "`"")

    ; attach output Map to root Map:
    fout.WriteLine("    g_lang_map[`"" lang_id "`"] := mlng")
    fout.WriteLine("")

    ; for each section of input Map:
    local k, msec
    local submap, submaps := []
    for k, msec in src_map
    {
        ; write section preamble:
        fout.WriteLine("")
        fout.WriteLine("    `; section '" msec[":map_name:"] "'")

        ; init section Map:
        fout.WriteLine("    msec := Map()")
        fout.WriteLine("    msec[`":map_name:`"] := `"" msec[":map_name:"] "`"")

        ; attach to output Map
        fout.WriteLine("    mlng[`"" msec[":map_name:"] "`"] := msec")

        fout.WriteLine("")
        fout.WriteLine("    `; ...[section] raw data")

        ; init '[section]' Array:
        fout.WriteLine("    asec := []")

        ; for each item in '[section]' Array:
        local kk, vv
        for kk, vv in msec[ "[section]" ]
        {
            if (vv Is Map)
            {
                ; if a Map, it's an extender; save for later processing
                submaps.Push(vv)
            }
            else {
                ; else if a String, copy verbatim to Array
                fout.WriteLine("    asec.Push(`"" vv "`")")
            }
        }
        ; attach '[section]' Array to section Map
        fout.WriteLine("    msec[`"[section]`"] := asec")

        ; for each item in section Map:
        fout.WriteLine("")
        fout.WriteLine("    `; ...section keys and values")
        for kk, vv in msec
        {
            ; if value not a Map or Array, save as 'key = value' item:
            if (!IsObject(vv) && kk != ":map_name:" && kk != "[section]")
                fout.WriteLine("    msec[`"" Trim(kk) "`"] := `"" Trim(vv) "`"")
        }
        fout.WriteLine("")
    }

    ; for each extender Map, write to output file as code:
    for kk, submap in submaps
    {
        if !(submap Is Map)
            continue

        local mapname := kk
        if (submap.Has(":map_name:"))
            mapname := submap[":map_name:"]

        ; write extender preamble
        fout.WriteLine("")
        fout.WriteLine("    `;==========================")
        fout.WriteLine("    `; submap '" mapname "'")
        fout.WriteLine("    `; source = " submap[":source:"])
        fout.WriteLine("")

        ; init extender Map
        fout.WriteLine("    msub := Map()")
        fout.WriteLine("    msub[`":map_name:`"] := `"" kk "`"")
        fout.WriteLine("    mlng[`":extenders:`"][`"[section]`"].Push(msub)")

        CLocale_Baker.BakeExtenderMap(fout, submap)
    }
    fout.WriteLine("    return")
    fout.WriteLine("}")
    fout.WriteLine("`; (end)")
    fout.WriteLine("")
    fout.Close
    ;Sleep 1000

    return true
} ; /BakeLangMap

;///////////////////////////////////////////////////////////////////////////////
class CLocale_Baker
{
    /*****************************************
    * ##### LoadExtenderFile: read a .LANG file, populate Map tree
    *
    * @param {Map}    out_map  - the Map to be populated
    * @param {String} src_path - source .LANG file (.INI files accepted too)
    *
    * @returns {Map} out_map, populated as shown below:
    * @throws {Error} if file cannot be read
    * <!--
    * @version 2025-11-07
    * -->
    */
    static LoadExtenderFile(out_map, src_path)
    {
        local fin, e
        local sLine, m

        if !(out_map Is Map)
            throw Error("'out_map' is not a Map")

        try {
            fin := FileOpen(src_path, "r")
        }
        catch Error as e {
            throw Error("could not open`n"
                    . "'" src_path "'`n"
                    . "for reading`n" e.Message)
        }

        local sSec := ""
        local msec := 0
        local asec := 0
        while (!fin.AtEOF)
        {
            sLine := fin.ReadLine()
            if (!StrLen(sLine) || RegExMatch(sLine, "^[ \t]*;"))
            {
                ; blank line or comment
                continue
            }
            else if (RegExMatch(sLine, "^[ \t]*"
                                    . "\["
                                    . "([^\]]+)"
                                    . "\]"
                                    , &m))
            {
                ; found start of section: init new section Map
                msec := Map()

                ; give the section a name
                sSec := m[1]
                msec[":map_name:"] := sSec

                ; add section Map to 'out_map' by name
                out_map[sSec] := msec

                ; init '[section]' array;
                ;   stores all lines in the section
                asec := []

                ; attach array to section Map
                msec["[section]"] := asec
            }
            else {
                ; a line in the current section:

                ; 1) save the line verbatim in case this is a 'bulk' section
                asec.Push(sLine)

                ; 2) parse 'key = value' line and save key-value pair:
                if (RegExMatch(sLine, "i)^[ \t]*"
                                    . "([^ \t=]+)"
                                    . "[ \t]*[=][ \t]*"
                                    . "([^\r\n]*)$"
                                    , &m))
                {
                    msec[m[1]] := m[2]
                }
            }
        } ; /fin.AtEOF
        fin.Close()

        return out_map
    } ; /LoadExtenderFile

    /*****************************************
     * ##### BakeExtenderMap: input a Map, generate .ahk code
     *
     * @param {Object} fout     - output file handle
     * @param {Map}    ext_map  - source Map
     *
     * @returns nothing
     * <!--
     * @version 2025-11-06
     * -->
     */
    static BakeExtenderMap(fout, ext_map)
    {
        ; for each section of input Map:
        local submaps := []
        local k, msec
        for k, msec in ext_map
        {
            if !(msec Is Map)
                continue

            ; write section preamble:
            fout.WriteLine("")
            fout.WriteLine("    `; section '" msec[":map_name:"] "'")

            ; init section Map:
            fout.WriteLine("    msec := Map()")
            fout.WriteLine("    msec[`":map_name:`"] := `"" msec[":map_name:"] "`"")

            ; attach to output Map
            fout.WriteLine("    msub[`"" msec[":map_name:"] "`"] := msec")

            fout.WriteLine("")
            fout.WriteLine("    `; ...[section] raw data")

            ; init '[section]' Array:
            fout.WriteLine("    asec := []")

            ; for each item in '[section]' Array:
            local kk, vv
            for kk, vv in msec[ "[section]" ]
            {
                ; if a String, copy verbatim to Array
                if !(vv Is Map) {
                    fout.WriteLine("    asec.Push(`"" vv "`")")
                }
            }

            ; attach '[section]' Array to section Map
            fout.WriteLine("    msec[`"[section]`"] := asec")
            fout.WriteLine("")

            ; for each item in section Map:
            fout.WriteLine("    `; ...section keys and values")
            for kk, vv in msec
            {
                ; if value not a Map or Array, save as 'key = value' item:
                if (!IsObject(vv) && kk != ":map_name:" && kk != "[section]")
                    fout.WriteLine("    msec[`"" Trim(kk) "`"] := `"" Trim(vv) "`"")
            }
            fout.WriteLine("")
        }
        return
    } ; /BakeExtenderMap

} ; /CLocale_Baker

; (end)
