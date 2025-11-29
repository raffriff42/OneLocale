## OneLocale_Init(): Setup

```autohotkey
locale_info := OneLocale_Init(optional_args := "")
```
#### What it does

Detects the user’s language, loads the best-matching `.lang` file (or baked map), and prepares everything for `sT()`.

Accepts an object containing named values. See the table below.

Returns an object with various named values. Check `.success` first — if `false`, show `.errmsg` and abort.

#### Typical usage

```autohotkey
locale_info := OneLocale_Init()
if !locale_info.success {
    MsgBox locale_info.errmsg, , "Icon!"
    ExitApp
}
```

#### Most useful `optional_args` (all others keep sensible defaults)

| Key            | Default   | Meaning |
|----------------|-----------|--------|
| `sLangFolder`  | "lang"    | Where your `.lang` files live |
| `sName`        | Script name | Base name for ini/lang files |
| `noLangFile`   | false     | Use the .ini itself as the language file |
| `sFallback`    | "en"      | Language to use when nothing else matches |
| `mapPriority`  | true      | Baked maps win over loose .lang files |


#### Parameters

{Object} `optional_args` - a set of named values, listed below.
You only need to supply the values which are non-default.

- `noLangFile` {Boolean} default = false
  - if false (default), use separate .LANG file;
  - if true, the .INI file serves as the .LANG file;
    `sLangFolder` is ignored;
    on return, `docsPath` will be A_ScriptDir "\" `sName` "." `sDocExt`;
    its existence is NOT tested for.

- `sLangFolder` {String} default = "lang"
  - override the default .LANG file subdirectory
  - if `sLangFolder` is "" (empty), .LANG files go in script directory

- `sDocsFolder` {String} default = "docs"
  - override the default help file subdirectory
  - if `sDocsFolder` is "" (empty), help files go in script directory

- `sName` {String} default = ""
  - base .INI and .LANG file name
  - if `sName` is empty (default), it's set to `A_ScriptName` without extension

- `sLangName` {String} default = ""
  - base .LANG file name;
  - if empty (default), it's set to `A_ScriptName` `-[/TAG/]`;
    this routine replaces `/TAG/` with the active Language Tag

- `sDocName` {String} default = ""
  - base doc file name;
  - if empty (default), it's set to `A_ScriptName` `-[/TAG/]`;
    this routine replaces `/TAG/` with the active Language Tag
  - (this is to support language-specific documentation; if you don't have that,
    ignore this argument)

- `sDocExt` {String} default = "html"
  - doc file extension, eg "txt", "md", "pdf", or "html" (the default)
  - For example, if `sDocName` is "MyScript-readme", `sDocExt` is "txt" and the
    language ID is "en", this function looks for a file named "MyScript-readme-\[en].txt"

- `sFallback` {String} default = "en"
  - An ISO 639-style Tag ('en', 'fr') _OR_
    4-hex-digit LCID ('0409', '000C') (with or without '0x' prefix)
  - ISO tag or LCID to use if no .LANG file was found for the given language (as calculated above);
    in this case, returned Object `.fallback` will be true;
    - The .LANG and doc files MUST exist, or initialization fails
    - Useful if you prefer automatic language selection based on `A_Language`; in this case leave
      the .INI entry blank; the closest available language will be chosen automatically.

- `sLangID` {String} default = "(auto)"
  - An ISO 639-style Tag ('en', 'fr') _OR_
    A 4-hex-digit LCID ('0409', '000C') (with or without '0x' prefix)
    - If not empty or "(auto)", `sLangID` overrides any .INI file entry.
    - If there is no .INI entry and no `sLangID` argument, `A_Language` will be used for automatic
      language selection (provided a compatible language file has been installed)
  - `sLangID` sources, lowest to highest priotity:
     `A_Language`, .INI file, `optional_args`
  - if `sLangID` (wherever it came from) isn't a valid language ID, this routine fails.

- `mapPriority` {Boolean} default true; determines whether Maps ('baked' data)  or .LANG Files have priority when a given Language is supported by both. Setting this to `false` means any .LANG files in `sLangFolder` will be preferred over any baked data, as long as they are compatible with the requested language.

#### Return Value

{Object} with the following properties:

- `.success` {Boolean} if true, the initialization was successful.

- `.errmsg` {String} error or warning message, if any.

- `.langID` {String} ISO Tag or LCID code for the current language;
  - It will be the best matching .LANG file that could be found;
  - May be a parent language, or may be the Fallback language.
  - This value also stored in global variable `g_lang_id`

- `.name` {String} human-readable language name (e.g., "English")

- `.fallback` {Boolean} if true, the Fallback language was used.

- `.iniPath` {String} location of main .INI file
  - File must exist, or `.success` will be false
  - This value also stored in global variable `g_ini_path`

- `.langPath` {String} location of active .LANG file
  - If `noLangFile` argument was set, `.langPath` will be same as `.iniPath`
  - This value also stored in global variable `g_lang_path`

- `.docsPath` {String} location of active docs (help) file, if any;
  - If `noLangFile` argument was set, `.docsPath` will be the empty string
  - This value also stored in global variable `g_docs_path`

- `.isoTag` {String} ISO Tag for the current language
- `.lcid` {String} 4-hex-digit LCID code for the current language
  - `.isoTag` and `.lcid` are alternate ways of specifying a language.

- `.langMap` {Boolean} if true, 'baked' (hard coded) language data was used;
  - if `,langMap` is true, `.langPath` and `g_lang_path` will be ":map:"

- `sLangFolder` {String}  copied from argument
- `sName`       {String}  copied from argument
- `mapPriority` {Boolean} copied from argument

Back to [README](../../README.md)
