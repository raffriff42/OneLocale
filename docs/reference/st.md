# sT() – translation lookup

```ahk
translated := sT(section, key, default := "ERROR", args := "", langPath := "")
```

Looks up a string in the active language file and does variable expansion.

#### Examples

```autohotkey
sT("gui", "title", "/My App v%ver%", {ver:"2.0"})
; -> returns “My App v2.0” (or the translated version)

sT("errors", "bad_path", "/File not found - %path%", {path:name})
; -> returns (if language = German)
; bad_path: file_not_found – Datei ‚readme.txt‘ wurde nicht gefunden.”
;(the key is shown verbatim only in the special [errors] section)

sT("messages", "welcome", "[section]")
; special syntax – returns the ENTIRE "welcome" section (multi-line)
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
