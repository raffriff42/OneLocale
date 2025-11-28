; OneLocale_Utils.ahk
;; language support

#Requires AutoHotkey v2.0
;requirements
;#Include "IniFiles.ahk"
;#Include "OneLocale.ahk"

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
;   FormatExCurrency()   formats a currency string using named Locale
;   FormatExDate()       formats a date using named Locale
;   FormatExDuration()   formats a duration of time using named Locale
;   FormatExNumber()     formats a number string using named Locale
;   FormatExTime()       formats a time using named Locale

/**********************************************
 * #### FormatExCurrency - formats a currency string using named Locale
 *
 * @param {String} sValue - The number string to format
 *
 * @param {String} sLocaleName - An ISO 639-style Tag ('en', 'es', 'de', 'fr' etc.);
 *   > if omitted, the current system default is assumed
 *
 * @return {String} formatted string
 *
 * h/t jNizM https://www.autohotkey.com/boards/viewtopic.php?t=10082
 */
FormatExCurrency(sValue, sLocaleName:="!x-sys-default-locale")
{
    local nSize, curr, rtn
    nSize := DllCall("GetCurrencyFormatEx"
                , "str", sLocaleName
                , "uint", 0
                , "str", sValue
                , "ptr", 0
                , "ptr", 0
                , "int", 0)
    if (!nSize)
        return false
    curr := Buffer(nSize << 1) ; VarSetCapacity
    rtn := DllCall("GetCurrencyFormatEx"
                , "str", sLocaleName
                , "uint", 0
                , "str", sValue
                , "ptr", 0
                , "ptr", curr
                , "int", curr.size)
    if (!rtn)
        return false
    return StrGet(curr)
}

/**********************************************
 * #### FormatExDate: formats a date using named Locale
 *
 * @param {String} sDate - A date in YYYYMMDDHH24MISS format:
 *   > * 'YYYY' = 4-digit year
 *   > * 'MM'   = 2-digit month
 *   > * 'DD'   = 2-digit day of the month
 *   > * 'HH24' = 2-digit hours in 24-hour format
 *   > * 'MI'   = 2-digit minutes
 *   > * 'SS'   = 2-digit seconds
 * @param {String} sFormat - Format string; if empty, uses the default for `sLocaleName`
 * @param {String} sLocaleName -
 *   > An ISO 639-style Tag ('en', 'es', 'de', 'fr' etc.);
 *   > if omitted, the current system default is assumed
 * @return {String} formatted string
 *
 * h/t jNizM https://www.autohotkey.com/boards/viewtopic.php?t=10082
 */
FormatExDate(sDate, sFormat:="", sLocaleName:="!x-sys-default-locale")
{
    local SYSTEMTIME, nSize, buf, rtn
    SYSTEMTIME := Buffer(16, 0) ; VarSetCapacity
    NumPut("UShort", SubStr(sDate,  1, 4), SYSTEMTIME,  0) ; Year
    NumPut("UShort", SubStr(sDate,  5, 2), SYSTEMTIME,  2) ; Month
    NumPut("UShort", SubStr(sDate,  7, 2), SYSTEMTIME,  6) ; Day
    NumPut("UShort", SubStr(sDate,  9, 2), SYSTEMTIME,  8) ; Hour
    NumPut("UShort", SubStr(sDate, 11, 2), SYSTEMTIME, 10) ; Minutes
    NumPut("UShort", SubStr(sDate, 13, 2), SYSTEMTIME, 12) ; Seconds

    if (!StrLen(sFormat)) {
        nSize := DllCall("GetDateFormatEx"
                , "Str" , sLocaleName
                , "UInt", 0
                , "Ptr" , SYSTEMTIME
                , "Ptr" , 0
                , "Ptr" , 0
                , "Int" , 0
                , "Ptr" , 0)
        if (!nSize)
            return false
        buf := Buffer(nSize << 1) ; VarSetCapacity
        rtn := DllCall("GetDateFormatEx"
                , "Str" , sLocaleName
                , "UInt", 0
                , "Ptr" , SYSTEMTIME
                , "Ptr" , 0
                , "Ptr" , buf
                , "Int" , buf.size
                , "Ptr" , 0)
    }
    else {
        nSize := DllCall("GetDateFormatEx"
                , "Str" , sLocaleName
                , "UInt", 0
                , "Ptr" , SYSTEMTIME
                , "Str" , sFormat
                , "Ptr" , 0
                , "Int" , 0
                , "Ptr" , 0)
        if (!nSize)
            return false

        buf := Buffer(nSize * 2) ; VarSetCapacity
        rtn := DllCall("GetDateFormatEx"
                , "Str" , sLocaleName
                , "UInt", 0
                , "Ptr" , SYSTEMTIME
                , "Str" , sFormat
                , "Ptr" , buf
                , "Int" , buf.size
                , "Ptr" , 0)
    }
    if (!rtn)
        return false
    return StrGet(buf)
}

/**********************************************
 * #### FormatExDuration: formats a duration of time using named Locale
 *
 * @param {Float} sDuration - A time duration in seconds
 * @param {String} sFormat - Format string with characters as shown below;
 *   > if empty, uses the default for `sLocaleName`
 *   > * d: days
 *   > * h or H: hours
 *   > * hh or HH: hours;
 *   >     if less than ten, add a leading zero
 *   > * m: minutes
 *   > * mm: minutes;
 *   >     if less than ten, add a leading zero
 *   > * s: seconds
 *   > * ss: seconds;
 *   >     if less than ten, add a leading zero
 *   > * f: fractions of a second
 * @param {String} sLocaleName -
 *   > An ISO 639-style Tag ('en', 'es', 'de', 'fr' etc.);
 *   > if omitted, the current system default is assumed
 * @return {String} formatted string
 *
 * h/t jNizM https://www.autohotkey.com/boards/viewtopic.php?t=10082
 */
FormatExDuration(sDuration, sFormat:="hh:mm:ss", sLocaleName:="!x-sys-default-locale")
{
    local nSize, dur, rtn
    if (!StrLen(sFormat)) {
        nSize := DllCall("GetDurationFormatEx"
                    , "Str"  , sLocaleName
                    , "UInt" , 0
                    , "Ptr"  , 0
                    , "Int64", sDuration * 10000000     ; seconds to 100-nanoseconds
                    , "Ptr"  , 0
                    , "Ptr"  , 0
                    , "Int"  , 0)
        if (!nSize)
            return false
        dur := Buffer(nSize << 1) ; VarSetCapacity
        rtn := DllCall("GetDurationFormatEx"
                    , "Str"  , sLocaleName
                    , "UInt" , 0
                    , "Ptr"  , 0
                    , "Int64", sDuration * 10000000
                    , "Ptr"  , 0
                    , "Ptr"  , dur
                    , "Int"  , dur.size)
    }
    else {
        nSize := DllCall("GetDurationFormatEx"
                    , "Str"  , sLocaleName
                    , "UInt" , 0
                    , "Ptr"  , 0
                    , "Int64", sDuration * 10000000     ; seconds to 100-nanoseconds
                    , "Str"  , sFormat
                    , "Ptr"  , 0
                    , "Int"  , 0)
        if (!nSize)
            return false
        dur := Buffer(nSize << 1) ; VarSetCapacity
        rtn := DllCall("GetDurationFormatEx"
                    , "Str"  , sLocaleName
                    , "UInt" , 0
                    , "Ptr"  , 0
                    , "Int64", sDuration * 10000000
                    , "Str"  , sFormat
                    , "Ptr"  , dur
                    , "Int"  , dur.size)
    }
    if (!rtn)
        return false
    return StrGet(dur)
}

/**********************************************
 * #### FormatExNumber: formats a number string using named Locale
 *
 * @param {String} sValue - The number string to format
 * @param {String} sLocaleName -
 *   > An ISO 639-style Tag ('en', 'es', 'de', 'fr' etc.);
 *   > if omitted, the current system default is assumed
 * @return {String} formatted string
 *
 * h/t jNizM https://www.autohotkey.com/boards/viewtopic.php?t=10082
 */
FormatExNumber(sValue, sLocaleName:="!x-sys-default-locale")
{
    local nSize, buf, rtn
    nSize := DllCall("GetNumberFormatEx"
                , "Str" , sLocaleName
                , "UInt", 0
                , "Str" , sValue
                , "Ptr" , 0
                , "Ptr" , 0
                , "Int" , 0)
    if (!nSize)
        return false
    buf := Buffer(nSize << 1) ; VarSetCapacity
    rtn := DllCall("GetNumberFormatEx"
                , "Str" , sLocaleName
                , "UInt", 0
                , "Str" , sValue
                , "Ptr" , 0
                , "Ptr" , buf
                , "Int" , buf.size)
    if (!rtn)
        return false
    return StrGet(buf)
}

/**********************************************
 * #### FormatExTime: formats a time using named Locale
 *
 * @param {String} sTime - A time in YYYYMMDDHH24MISS format:
 *   > * 'YYYY' = 4-digit year
 *   > * 'MM'   = 2-digit month
 *   > * 'DD'   = 2-digit day of the month
 *   > * 'HH24' = 2-digit hours in 24-hour format
 *   > * 'MI'   = 2-digit minutes
 *   > * 'SS'   = 2-digit seconds
 * @param {String} sFormat - Format string; if empty, uses the default for `sLocaleName`
 * @param {String} sLocaleName -
 *   > An ISO 639-style Tag ('en', 'es', 'de', 'fr' etc.);
 *   > if omitted, the current system default is assumed
 * @return {String} formatted string
 *
 * h/t jNizM https://www.autohotkey.com/boards/viewtopic.php?t=10082
 */
FormatExTime(sTime, sFormat:="", sLocaleName:="!x-sys-default-locale")
{
    local SYSTEMTIME, nSize, buf, rtn
    SYSTEMTIME := Buffer(16, 0) ; VarSetCapacity
    NumPut("ushort", SubStr(sTime,  1, 4), SYSTEMTIME,  0) ; Year
    NumPut("ushort", SubStr(sTime,  5, 2), SYSTEMTIME,  2) ; Month
    NumPut("ushort", SubStr(sTime,  7, 2), SYSTEMTIME,  6) ; Day
    NumPut("ushort", SubStr(sTime,  9, 2), SYSTEMTIME,  8) ; Hour
    NumPut("ushort", SubStr(sTime, 11, 2), SYSTEMTIME, 10) ; Minutes
    NumPut("ushort", SubStr(sTime, 13, 2), SYSTEMTIME, 12) ; Seconds

    if (!StrLen(sFormat)) {
        nSize := DllCall("GetTimeFormatEx"
                    , "Str" , sLocaleName
                    , "UInt", 0
                    , "Ptr" , SYSTEMTIME
                    , "Ptr" , 0
                    , "Ptr" , 0
                    , "Int" , 0)
        if (!nSize)
            return false

        buf := Buffer(nSize << 1) ; VarSetCapacity
        rtn := DllCall("GetTimeFormatEx"
                    , "Str" , sLocaleName
                    , "UInt", 0
                    , "Ptr" , SYSTEMTIME
                    , "Ptr" , 0
                    , "Ptr" , buf
                    , "Int" , buf.size)
    }
    else {
        nSize := DllCall("GetTimeFormatEx"
                    , "Str" , sLocaleName
                    , "UInt", 0
                    , "Ptr" , SYSTEMTIME
                    , "Str" , sFormat
                    , "Ptr" , 0
                    , "Int" , 0)
        if (!nSize)
            return false
        buf := Buffer(nSize * 2) ; VarSetCapacity
        rtn := DllCall("GetTimeFormatEx"
                    , "Str" , sLocaleName
                    , "UInt", 0
                    , "Ptr" , SYSTEMTIME
                    , "Str" , sFormat
                    , "Ptr" , buf
                    , "Int" , buf.size)
    }
    if (!rtn)
        return false
    return StrGet(buf)
}

; (end)
