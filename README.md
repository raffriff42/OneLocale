# OneLocale — simple, powerful i18n for AutoHotkey v2

[![License](https://img.shields.io/badge/License-LGPL%202.1-blue.svg)](https://opensource.org/license/lgpl-2.1)
![AutoHotkey v2](https://img.shields.io/badge/AutoHotkey-v2-green.svg)
[![View on GitHub](https://img.shields.io/badge/View%20on%20GitHub-000000?style=for-the-badge&logo=github&logoColor=white)](https://github.com/raffriff42/OneLocale)

<img src="docs/assets/OneLocale-Earth_icon_2-x128c.png" align="right" width="128" height="128" alt="OneLocale logo"/>

**Write your GUI strings in plain English (or your language of choice) today — add translations tomorrow without touching your code again.**

<img src="docs/assets/OneLocale-demo4L-692x532.gif" alt="OneLocale in action" width="600"/>

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

- An .ini file - even an empty one - is required:

```dosini
; MyScript.ini
; • 'language=' is optional – leave empty to auto-detect using A_Language
[general]
;language = de
```

- The .lang file format is very human-friendly. With its INI-like *section*, *key*, *value* format, each string comes with context to help the translator.

```dosini
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
wait  = Wait

```

- By the way, an AI, like **Grok**, can do a great job of translating, once they have the [Notes for Translators](./docs/reference/translator-notes.md).

```dosini
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
wait     = Warten

[general]
translator = Grok
```

Now drop `OneLocale.ahk` in a \lib subfolder, and put `MyScript-[en].lang` and `MyScript-[de].lang` in a \lang subfolder. Switch language instantly by editing the ini or using the included **chooser dialog** (not shown here, but seen in this [Demo](./utilities/OneLocale_Demo/))

## Full Documentation

- Reference
  - Setting up - [OneLocale_Init()](./docs/reference/init.md)
  - String lookup & format – [sT()](./docs/reference/st.md)
  - [Language Chooser Dialog](./docs/reference/dialog.md)
  - [Baking languages into the .exe](./docs/reference/baker.md) (zero external files)

- [Notes for Translators](./docs/reference/translator-notes.md)
- [Complete Beginner-Friendly Introduction](./docs/OneLocale-Introduction.md) (20 min read)

## Helper apps

- [OneLocale_Demo](./utilities/OneLocale_Demo/) is a slightly biger demo with fully commented code.
- [OneLocale_Baker](/utilities/OneLocale_Baker/) turns .lang data into .ahk code.
- [OneLocale_FindLangID](./utilities/OneLocale_FindLangID) finds ISO Tags by partial language names.

Browsing the source code of these apps should give you some ideas. All sample and demo code is public domain BTW, marked [CC0 1.0](https://creativecommons.org/publicdomain/zero/1.0/).

## Why people love it

There are a couple of i18n libraries floating around the forums right now.
**OneLocale** simply gives you the most complete, v2-native feature set today — without drama, without legacy baggage, and with the cleanest developer + translator experience.

That’s it.

## Contributing

Bug reports, translations, or just a “this saved me hours” are all very welcome ♥
Open an issue or PR — I usually reply the same day.

[AutoHotkey Community discussion](https://www.autohotkey.com/boards/viewtopic.php?f=83&t=139639)

## License

GNU Lesser General Public License v2.1 – use commercially, modify, ship in closed-source apps, all no problem. Full text in [LICENSE](./LICENSE).

## About

OneLocale was first created in February 2023, and has been slowly refined as it was used in many of my personal projects.

I've been doing this class of software for awhile. OneLocale is a complete rework of my 2013 **NetText** project [(sourceforge)](https://sourceforge.net/projects/nettext/) and there is other work going back a few years before that.

-- [raffriff42](https://github.com/raffriff42)
