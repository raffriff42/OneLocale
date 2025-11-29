## sT() – translation lookup

```ahk
message := sT(section, key, default := "ERROR", args := "", langPath := "")
```

#### What it does

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

#### Arguments

{String} sSection - section name

{String} sKey     - key name

{String} sDefault    - text to use if lookup fails

- `sDefault` is useful during development as temporary text until a .LANG file can be created)
- if `sDefault` is unset, `sT` will throw errors - good for debugging but NOT for production

{Object} args      - optional names and values: `{book:"HHGTTG", answer:42}`

{String} langPath  - if not empty, overrides `g_lang_path` as the path of the .LANG file

#### 'Baked' (hard coded) data

- Strings are compiled into the .EXE for extra security.
- Generate code from .LANG with the `OneLocale_BakerGui` app.
- `#Include` the generated file in your script.
- The generated function will be called for you.
- For instance, if `lang_id` is "zh-cn", generated function will be `OneLocale_BuildMap_zh_cn()`
- This will initialize a [Map](https://www.autohotkey.com/docs/v2/lib/Map.htm) tree; [OneLocale_Init()](init.md) will recognize it, and [sT()](st.md) will use it.

#### Extenders

The .LANG file (or Map) may list a set of _extender_ files (or maps) via an optional Extenders section. If the requested message is not found in the main .LANG file (or map), this function looks into the extenders. Extenders are listed in a special section (or key) named `:extenders:`.

This feature is helpful when you have .LANG data that is used in multiple projects, such as a dialog box (for example, `OneLocaleDlg_Dialog`)

Finally, if the search is exhausted, `sDefault` is returned,

- Extender paths may be absolute or relative to `sPath`
  - May fail for paths on mapped drive letters
  - Share paths seem to work, but they are slow when first accessed.
  - Short names (forced by Windows to 8.3 form) may not work.
  - Symbolic links seem to work.
  - `\\?\` (long name enable) prefixed paths are supported,
    and are added if needed on long paths.

- Files are checked in order until the requested item is found
- If the requested item is not found in any of the extenders, `sDefault` is returned; if there is no `sDefault`, a catchable Error is thrown.

Back to [README](../../README.md)
