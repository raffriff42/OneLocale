# OneLocale – Notes for Translators

Thank you for helping make someone’s app feel native!

### What you are editing

- A normal INI-style file with extension `.lang`
- Save as *UTF-16 LE with BOM* (Notepad → Save As → Encoding → “UTF-16 LE”)

### Rules (very short)

- Never change the _key_ - anything to the left of `=`
- Never change _variable_ - words inside `%percent signs%`
- `&` = set access key (underlined letter). Choose a letter that isn’t used yet in the same window.
- `\t` inside menu items = keyboard shortcut (e.g. `&Save\tCtrl+S`)
- `\n` = force a new line
- `\w` = remove the line break (let the program wrap instead) when placed at at the beginning or end of a line
- Anything after `\z` is a comment for you and will never appear to the user
- To show a literal `%` write `\%`
- To show a literal `&` that should not underline, write `&&`

### Multi-line sections

Some sections have no `=` signs at all. Translate the whole block exactly as it appears.
Blank lines are ignored in sections; use `\n` if you really need an empty line.

That’s it. If something feels weird, just add a comment:
`\z your note here`
The developer will see it.

Questions? Open an issue on the GitHub repo – we’re friendly

### The 2025 way

Just paste the entire .lang file into Grok / Claude / ChatGPT and say:
“Translate this AutoHotkey OneLocale language file to German. Follow the rules in the comments exactly. Never touch keys or %variables%.”
Maybe attach a copy of these notes.

They’ll give you a perfect file in seconds — then you only skim for tone.
(Yes, this is how most new translations will happen from now on.) 😄

– the OneLocale team (and Grok says hi)
