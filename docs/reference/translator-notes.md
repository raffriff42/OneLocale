# OneLocale – Notes for Translators

Thank you for helping make someone’s app feel native!

### Save as a new file

- Before starting, save your work as a new file.
- Save as *UTF-16 LE with BOM* to preserve Unicode.
This is a resriction of all `.ini` files - a `.lang` file *IS* a type of `.ini` file.
- Save with the proper language *tag*
- For example, a French translation of
  - `MyScript-[en].lang` would be saved as
  - `MyScript-[fr].lang`

Basic language tags are listed at [List of ISO 639-1 Codes](https://en.wikipedia.org/wiki/List_of_ISO_639-1_codes) (Wikipedia)
All 436 valid language tags are listed in this [Microsoft Document](https://learn.microsoft.com/en-us/openspecs/windows_protocols/ms-lcid/a9eac961-e77d-41a6-90a5-ce1a8b0cdb9c) (scroll down to Table 2)
👉 It's easiest to use [OneLocale_FindLangID](../../utilities/OneLocale_FindLangID/) to find valid language tags by partial language name.

For example, entering "esp" lists all Spanish dialects:
![OneLocale_FindLangID](../assets/OneLocale_FindLangID%202025-11-29%20038.png)

### Important Rules

- Never change a *key* - anything to the left of '`=`'.
- Never change a *variable* - words inside `%percent signs%`

### Formatting

- '`&`' sets the *access key* (underlined letter, e.g. '`Save &As...`').
  - Choose an appropriate key for your language
  - Make them unique within a menu, if possible
- '`\n`' forces a new line
- Anything after '`\z`' is a comment for you and will never appear to the user
  - Maybe a comment to you, to give helpful context.
  - Maybe a comment *from* you to the developer or the next translator.
- To show a literal '`%`', write '`\%`'.
- Ampersand ('`&`') sets the underlined *Accesss Key* (see below)
To show '`&`' without the underline, use '`&&`' (e.g. '`Cats && Dogs`)

#### Menus

- Ampersand ('`&`') sets the *Accesss Key* (e.g. '`&Cancel`')
  - Choose an appropriate key for your language.
  - Make them unique within a menu, if possible.
- Tab (`\t`) separates menu *text* and menu *Accelerator* (hotkey)
(e.g. '`&Save \t Ctrl+S`')
  - Choose an appropriate hotkey for your language.
  - Make them unique within a GUI window (each dialog window can have its own hotkeys)
- Discuss with the developer as needed.

See Microsoft’s [docs](https://learn.microsoft.com/en-us/globalization/input/hotkeys-accelerators) for details of both Access Keys and Accelerators.

#### GUI elements

- Ampersand (`&`) sets the Access Key
(e.g. '`Save &As...`')
  - Choose the appropriate key for your language.
  - Make them unique within a GUI window, if possible.
- Unlike Menus, Gui elements like Buttons don't have hotkeys. The developer may have created workarounds for this: the easiest is to have a menu item duplicating the functionality of each Button.

Watch out for translated strings becoming **too long to display properly**. Experiment. Run the app and see how it looks. Try to re-word your translation to make it fit in the space available. If your shortened translation sacrifices important meaning, you can add it back in the element's **Tooltip**, if it has one.

As a rule of thumb, messages should be **no more than ~120% longer than the base language**, although this depends on how much room the developer gave you.

#### Tooltips

- There are no access keys or accelerators.
- No length restriction - tooltips can grow to display a *lot* of text.

#### List contents

- There are no access keys or accelerators.

#### Multi-line sections

Multi-line sections look different because they don't have '`=`' on every line like normal sections.
Multi-line text *should* be labeled with a comment - something like:
`; • Entire section should be translated`

- The entire section should be translated.
- Indent text with '`\t`'.
- Blank lines are ignored on input; use '`\n`' if you need an empty line on output.
- Remove line breaks (allow word wrap) with `\w` at the start or end of line.
- Pay attention to display limits - test often; discuss problems with the developer.

#### Error messages

- Length isn't as limited (200-300% longer than base language is okay)

---

Questions? Open an issue on the GitHub repo – we’re friendly.

### The 2025 way

👉 Just give the entire .lang file into Grok / Claude / ChatGPT and say:
“Translate this AutoHotkey OneLocale language file to German. Never touch keys or %variables%” - and attach a copy of these Notes.

A good AI will give you a near-perfect file in seconds. You only skim for tone.

(Yes, this is how most new translations will happen from now on.) 😀

– the OneLocale team (and Grok says hi)

Back to [README](../../README.md)
