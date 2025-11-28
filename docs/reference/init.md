## OneLocale_Init(): Setup

```autohotkey
locale_info := OneLocale_Init(optional_args := "")
```

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

The doc comments are extensive.

Back to [README](../../README.md)
