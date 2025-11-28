# OneLocaleDlg_Dialog() – language chooser

```ahk
OneLocaleDlg_Dialog(parentTitle, locale_info_object)
```

Scans the `lang/` folder and (the location is stored in `locale_info_object` returned from `CodeLocale_Init`) and any 'baked' language Maps. Shows a dropdown; if the user selects a different language, this function writes the new choice back to the .ini, then calls your callback `OneLocaleDlg_Result()` (you must implement it).

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

That’s literally all most apps need.
