## sT() – translation lookup

```ahk
message := sT(section, key, default := "ERROR", args := "", langPath := "")
```

Looks up a string in the active language file and does variable expansion.

#### Examples

```autohotkey
;MyScript.ahk
MyGui.Title := sT("gui", "title", "/My App v%ver%", {ver:"2.0"})

MyGui.Add("Edit", "w400 r6", sT("welcome", "[section]"))

MsgBox sT("errors", "bad_path", "/File not found - %path%", {path:name})

```

```ini
;MyScript-[en].lang
[gui]
title = My App v%ver%

[welcome]
OneLocale provides an easier way to support multiple user-interface \w
languages in AutoHotkey.\n
Even if you don’t plan to support multiple languages, the way OneLocale \w
helps distinguish user-interface text from other string literals in \w
your code is valuable for code maintenance.

; in the special [errors] section, the key is shown verbatim
; before the translated message
[errors]
bad_path = File not found - %path%

```

#### Special sequences understood everywhere

| Sequence | Result         | Note |
|----------|----------------|------|
| `\t`     | Tab            | |
| `\n`     | Line feed      | leading space after it is stripped |
| `\w`     | Remove newline | lets the GUI control word-wrap |
| `\z`     | Comment to translator | text after `\z` is ignored |
| `\%`    | Literal `%`    | |
| `\\`    | Literal `\`    | |

Standard AutoHotkey backtick escapes are allowed too.

Save `.lang` files as *UTF-16-LE with BOM* – that’s the only encoding that works reliably.

There's much more in the doc comments.

Back to [README](../../README.md)
