# OneLocale — Simple, powerful i18n for AutoHotkey v2

[![License](https://img.shields.io/badge/License-LGPL%202.1-blue.svg)](https://opensource.org/license/lgpl-2.1)
[![AutoHotkey v2](https://img.shields.io/badge/AutoHotkey-v2-green.svg)](https://www.autohotkey.com/)

<img src="docs/assets/OneLocale-Earth_icon_2-x128c.png" align="right" width="128" height="128"/>

**Write your GUI strings in plain English (or your language of choice) today — add translations tomorrow without touching your code again.**

<img src="docs/assets/OneLocale-demo4L-ani.gif" alt="OneLocale in action" width="600"/>

### What you get

- One-line `sT()` that feels like normal string usage
- Full variable expansion (`%var%` + named parameters)
- Multi-line messages, access keys (`&`), accelerators (`\tCtrl+S`)
- Translator-friendly `.lang` files (just INI with a few escape rules)
- Automatic fallback + optional “baked” maps → single .exe with no external files
- Built-in language-chooser dialog
- Extender system for shared strings across projects

## Quick Start (runs out of the box)

```autohotkey
; MyScript.ahk
#Requires AutoHotkey v2.0
#Include lib/OneLocale.ahk
S_VERSION := "1.0"
locale_info := OneLocale_Init() ; reads MyScript.ini → picks best language
if (!locale_info.success) {
    MsgBox(locale_info.errmsg, , "icon!")
    ExitApp
}
G := Gui("-MaximizeBox -MinimizeBox")
G.Title := sT("gui", "title", "/My Cool App v%ver%", {ver:S_VERSION})

G.Add("Text", "x16 w400 r9", sT("welcome", "[section]"))
    .SetFont("s10")

G.Add("Button", "x314 w100 Default", sT("gui", "btn_quit", "/&Quit"))
    .OnEvent("Click", (*) => ExitApp())

SB := G.Add("StatusBar", "vStatus1")
SB.SetText(sT("status", "ready", "/Ready"))

G.Show("w430 center")
return
```

```ini
; MyScript.ini
; (optional – leave empty for auto-detect)
[general]
;language = de
```

```ini
;MyScript-[en].lang
[gui]
title = My Cool App v%ver%
btn_quit = &OK

[welcome]
OneLocale provides an easier way to support multiple user-interface \w
languages in AutoHotkey.\n
Even if you don’t plan to support multiple languages, the way OneLocale \w
helps distinguish user-interface text from other string literals in \w
your code is valuable for code maintenance.

[status]
ready = Ready
```

```ini
;MyScript-[de].lang
[gui]
title    = Mein Cooles Programm v%ver%
btn_quit = &Beenden

[welcome]
OneLocale macht die Unterstützung mehrerer Sprachen für die \w
Benutzeroberfläche in AutoHotkey deutlich einfacher.\n
Selbst wenn Sie keine Mehrsprachigkeit planen, ist die Art und Weise, \w
wie OneLocale Text für die Oberfläche von anderen Zeichenketten im \w
Code klar abgrenzt, äußerst wertvoll für die Wartbarkeit Ihres Programms.

[status]
ready    = Bereit

[notes]
translator = Grok
```

Now drop `OneLocale.ahk` in a \lib subfolder, and put `MyScript-[en].lang` and `MyScript-[de].lang` in a \lang subfolder. Switch language instantly by editing the ini or using the included **chooser dialog** (not shown here, but seen in this [Demo](./examples/OneLocale_Demo))

## Full Documentation

- Reference
  - Setting up - [OneLocale_Init()](./docs/reference/init.md)
  - String lookup & format – [sT()](./docs/reference/st.md)
  - [Language Chooser Dialog](./docs/reference/chooser.md)
  - [Baking languages into the .exe](./docs/reference/baker.md) (zero external files)

- [Notes for Translators](./docs/reference/translator-notes.md)
- [Complete Beginner-Friendly Introduction](./docs/OneLocale-Introduction.md) (20 min read)

## Why people love it (quietly)

There are a couple of i18n libraries floating around the forums right now.
**OneLocale** simply gives you the most complete, v2-native feature set today — without drama, without legacy baggage, and with the cleanest developer + translator experience I could build.

That’s it.

## Contributing

Bug reports, translations, or just a “this saved me hours” are all very welcome ♥
Open an issue or PR — I usually reply the same day.

## License

GNU Lesser General Public License v2.1 – use commercially, modify, ship in closed-source apps, no problem.
Full text in [LICENSE](./LICENSE).

---

Made with passion (since Feb 2023 → still going strong in 2025) by [raffriff42](https://github.com/raffriff42)
