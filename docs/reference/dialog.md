# OneLocaleDlg_Dialog() – language chooser

```ahk
OneLocaleDlg_Dialog(parentTitle, locale_info_object)
```

#### What it does

- Scans the .lang file folder and any 'baked' language Maps.
- Shows a dialog box with a dropdown list of all available languages.
- Waits for the user.
- If the user selects a different language, this function:
  - Writes the new choice back to the .ini,
  - Then calls your callback `OneLocaleDlg_Result()`

#### Callback - minimal implementation

```autohotkey
OneLocaleDlg_Result() {
    msg := OneLocaleDlg.StatusMessage
    if (msg = "Cancel") ; user Canceled
        return
    if (InStr(msg, "Language=")) ; user selected a new language
        Reload ; easiest way to update the language
    ; if here, something went wrong
    MsgBox msg
    return
}
```

#### Arguments

{String} `sParentWinTitle` - the parent window's [Title](https://www.autohotkey.com/docs/v2/misc/WinTitle.htm)

{Object} `optional_args` - a set of named values, listed below.
You only need to supply the values which are non-default.

- `sLangFolder` {String} default = "lang"
  - override the default .LANG file subdirectory
  - if `sLangFolder` is "" (empty), .LANG files go in script directory

- `sName` {String} default = ""
  - base .INI and .LANG file name
  - if `sName` is empty (default), it's set to `A_ScriptName` without extension

- `langID` {String} the current Language ID
  - An ISO 639-style Tag ('en', 'fr') _OR_
    A 4-hex-digit LCID ('0409', '000C') (with or without '0x' prefix)
    - If not empty or "(auto)", `langID` overrides any .INI file entry.
    - If there is no .INI entry and no `langID` argument, `A_Language` will be used for automatic
       language selection (provided a compatible language file has been installed)
  - `langID` sources, lowest to highest priotity:
     `A_Language`, .INI file, `optional_args`
  - if `langID` (wherever it came from) isn't a valid language ID, this routine fails.

- `mapPriority` - {Boolean} determines whether Maps or Files have
   priority when a given Language is supported by both; if true (default),
   Maps have priority (does not affect dialog listbox sort order)

> :point_right: __NOTE__ simply pass the returned object from [OneLocale_Init()](init.md).

#### Return value (none)

- On success, the .INI file Language entry will be updated.
- Calls `OneLocaleDlg_Result()`, which you must write (see generic implementation below)
- Sets global `OneLocaleDlg.StatusMessage`.

  - If something went wrong, `OneLocaleDlg.StatusMessage` will have an error message.
  - If user clicked Cancel, it will be "Cancel".
  - Else if user clicked OK, it will be "Language=" and the new language ID.
  - On success, the application must reload all language-specific
    strings. The easiest way to do that is to restart the application,
    reading the .INI file Language entry on startup.

Back to [README](../../README.md)
