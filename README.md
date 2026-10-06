# LocaleBlox

**A Roblox game's words in twenty-five languages: Luau tables looked up by key, plural forms, and
the lint that keeps the tables whole.**

LocaleBlox is the locale machinery of the game Grabby Pit as a package. A game keeps its strings in
plain Luau tables, one per language; LocaleBlox picks the table from the player's Roblox locale,
formats a key into a sentence, makes a noun agree with its number, and checks that every language
holds every key with the same placeholders, in its own script. There is no `LocalizationService`,
no cloud table and nothing to upload.

> **Status: 0.1.0.** Every rule is proven by specs that run on every push, and each of 73 small
> slips in them makes the suite fail (`tests/Mutate.luau`). The whole library is plain Luau and
> runs on LuneBlox, the Luau version Roblox runs. It was required once in a real Roblox server and
> every module answered there; no game has shipped with it yet.

## Install

```sh
pesde add xopoiii/localeblox -t roblox -a LocaleBlox
```

or pin it exactly in `pesde.toml`:

```toml
[dependencies]
LocaleBlox = { name = "xopoiii/localeblox", version = "=0.1.0", target = "roblox" }
```

LocaleBlox has no dependencies. It touches no Roblox service, so the same modules load on the
client, on the server and off Roblox.

## A game's words in a minute

```lua
local LocaleBlox = require(path.to.LocaleBlox)

-- The game's own tables stay in the game: one key a line, English as the source.
local en: LocaleBlox.Table = {
	feed = "Feed",
	movedTo = "%s's colony moved to the %s",
	worldGarden = "Garden",
	pieces = "%d / %d pieces carried off",
}
local plurals: LocaleBlox.Plurals = {
	en = { pieces = { one = "%d / %d piece carried off", other = "%d / %d pieces carried off" } },
}

-- One reader per client, from the player's LocaleId.
local text = LocaleBlox.Text.new({
	tables = { en = en, ru = ru },
	plurals = plurals,
	localeId = Players.LocalPlayer.LocaleId,
})

button.Text = text.get("feed")
line.Text = text.get("movedTo", ownerName, { key = "worldGarden" })
progress.Text = text.count("pieces", carried, total)
```

## What stays in a game

Its tables and its plural forms, the names of its data, how a sentence travels from its server (as
a key and arguments, over its own wire), and the scripts that read its files and call the lint.

## The API

### `Text`

`Text.new(options)` returns a reader. `options.tables` is the game's tables by locale, with English
required; `options.localeId` is any BCP-47 tag; `options.plurals` is optional.

| Function | What it returns |
|---|---|
| `get(key, ...)` | The string for `key`, formatted with `string.format` when arguments follow. An argument `{ key = "..." }` is looked up first, so a translated sentence never gets an English word in a slot. With no arguments the template is returned as written. |
| `count(key, n, ...)` | A sentence whose noun agrees with `n`, which is the first format argument. Without forms for the key it is the flat string. |
| `data(kind, name, field?)` | `get(Keys.of(kind, name, field))`. |
| `has(key)` | Whether the key has text in this locale or in English. |
| `locale()`, `localeId()` | The resolved locale, and the id it came from. |
| `isRtl()` | Whether this locale is written right to left. |

Amounts are written by the game (`"12.5K"`) and ride `%s`.

**Plural forms.** `plurals[locale][key][category]`, the category being CLDR's: `zero`, `one`, `two`,
`few`, `many`, `other`. A missing category falls back to `other`, then `many`, then `one`. A locale
with a table and no forms for a key uses its flat string, which is right for a language whose noun
does not change. A locale with no table at all counts in English, by English's rules.

### `Locale`

- `Locale.localeFor(localeId)`: the locale a LocaleId reads. Case and the separator do not matter.
  `be` and `kk` read `ru`; `tl` reads `fil`; `zh-hant`, `zh-tw`, `zh-hk` and `zh-mo` read
  `zh-hant` and every other Chinese tag reads `zh-hans`; `es-es`, `pt-pt` and `fr-ca` read `es-ES`,
  `pt-PT` and `fr-CA`; anything unknown reads `en`.
- `Locale.router(tables)`: `get(locale, key)` with the fallback locale, English, key;
  `keys(locale)` and `populated()`, sorted; `localeFor`. It errors if there is no English table.
- `Locale.isRtl(locale)`: true for `ar`.
- `Locale.ALL`: the twenty-five locales, frozen: `en`, `ru`, `pt`, `es`, `id`, `de`, `fr`, `fil`,
  `hi`, `vi`, `th`, `ms`, `ja`, `ko`, `zh-hant`, `tr`, `pl`, `ar`, `it`, `nl`, `uk`, `zh-hans`,
  `es-ES`, `pt-PT`, `fr-CA`.

### `Plural`

`Plural.category(locale, n)`: Russian and Ukrainian have `one`, `few`, `many`; Polish the same with
`one` only at exactly one; Arabic all six; French counts zero with `one`; English, German, Dutch,
Spanish, Portuguese, Italian, Hindi and Filipino have `one` and `other`; every other locale is
`other`. `n` is taken whole and without its sign.

### `Keys`

`Keys.of(kind, name, field?)`: `Keys.of("food", "sugar_cube")` is `"foodSugarCube"`, and
`Keys.of("product", "pay_rush", "blurb")` is `"productPayRushBlurb"`.

## The lint

Four modules that take text and tables and return a sorted list of problems, each a line a person
can act on. An empty list is a clean result. A game's script reads its own files and calls them; a
game's spec can call them on the tables it requires.

```lua
local locales: LocaleBlox.Parsed = {}
for _, path in localeFiles do
	LocaleBlox.Parse.source(fs.readFile(path), locales, { zhHans = "zh-hans", zhHant = "zh-hant" })
end
local problems = LocaleBlox.Lint.tables(locales)
```

- `Parse.source(source, out, aliases?)` adds every table of a Luau source to `out[code][key]`. A
  table opens with `local name: Type = {` (or `const`) on a line of its own, holds one
  `key = "value",` per line one tab deep, and closes with `}` at the start of a line. `aliases`
  renames a variable to its locale code. `Parse.specifiers(text)` lists a string's `string.format`
  specifiers.
- `Lint.tables(locales)`: every English key is in every locale and no locale holds a key English
  lacks; a translation has English's specifiers in number and order; no empty string; no combining
  acute accent; no Simplified glyph in `zh-hant` and no Traditional glyph in `zh-hans`; one width
  of "!" and "?" per Chinese table.
- `Lint.plurals(en, plurals)`: every counted key is in English, every category is CLDR's, every
  form has English's specifiers, and every set of forms has `other` or `many`.
- `Written.check(locales, options?)` and `Written.one(code, where, text, options?)`: valid UTF-8,
  no U+FFFD, no control character, no combining accent; every locale in its own script; Arabic
  that starts with an Arabic letter and holds no Latin word. `options.keep` is a list of Lua
  patterns for Latin a translation keeps on purpose; format specifiers, multipliers ("x2"), "R$",
  "Robux" and "Roblox" are always kept.
- `Usage.check(en, sources, options?)`: `sources` is a list of `{ path, text }`. A string literal
  shaped like a key (a lowercase word, then a capital) whose first word starts some English key
  must be a key, and every English key must appear in a source. `options.data` names the first
  words of keys built from game data, which are left to the game's own spec.

## Working on it

`rokit install`, `lefthook install`, then `sh scripts/run-tests.sh` and
`luneblox run tests/Mutate --yes`. `CLAUDE.md` holds the rules and the release steps.

## Licence

MIT.
