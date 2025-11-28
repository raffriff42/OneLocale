# Baking languages into the .exe (zero external files)

In OneLocale, there are two kinds of language data at run time:

- *file* (.lang files) and
- *baked* (hard-coded - implemented as a Map tree)

**OneLocale_Baker** loads a .lang file and *bakes* it into source code

Your script runs the source to build a 'baked' (map tree) database.

1. Run `utilities/OneLocale_BakerGui/OneLocale_BakerGui.ahk`
2. Point it at a folder full of `*.lang` files
3. It generates one `#Include`-able file per language (e.g. `OneLocale_map_de.ahk`)
4. `#Include` the generated file(s) in your project
5. The generated function (e.g. `OneLocale_BuildMap_de()`) is called for you.
6. `sT` transparently gets the translated text from the best source available - file or map.

Result: your compiled .exe contains **all translations** – nothing to ship separately, and no read-permission problems on restricted systems.
