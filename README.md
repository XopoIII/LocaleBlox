# LocaleBlox

**A Roblox game's words in twenty-five languages: Luau tables looked up by key, plural forms, and
the lint that keeps the tables whole.**

LocaleBlox is the locale machinery of a live game as a package. A game keeps its strings in
plain Luau tables, one per language; LocaleBlox picks the table from the player's Roblox locale,
formats a key into a sentence, makes a noun agree with its number, and checks that every language
holds every key with the same placeholders, in its own script. There is no `LocalizationService`,
no cloud table and nothing to upload.

> **Status: 0.3.0.** Every rule is proven by specs that run on every push, and each of 178 small
> slips in them makes the suite fail (`tests/Mutate.luau`). The whole library is plain Luau and
> runs on LuneBlox, the Luau version Roblox runs. One game has run on it live since 0.2.0; before
> each release its own tables and lint are run against the new sources and compared with the old.

## Install

```sh
pesde add xopoiii/localeblox -t roblox -a LocaleBlox
```

or pin it exactly in `pesde.toml`:

```toml
[dependencies]
LocaleBlox = { name = "xopoiii/localeblox", version = "=0.3.0", target = "roblox" }
```

LocaleBlox has no dependencies. It reads no Roblox service, so the same modules load on the
client, on the server and off Roblox. The two modules that write on instances (`Label`,
`Localize`) are handed the instance and the collection service by the game.

## A game's words in a minute

```lua
local LocaleBlox = require(path.to.LocaleBlox)

-- The game's own tables stay in the game: one key a line, English as the source.
local en: LocaleBlox.Table = {
	feed = "Feed",
	movedTo = "%s's camp moved to the %s",
	zoneHarbour = "Harbour",
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
line.Text = text.get("movedTo", ownerName, { key = "zoneHarbour" })
progress.Text = text.count("pieces", carried, total)
```

## What stays in a game

Its tables, its plural forms and its name tables, the names of its data, the JSON codec its
sentences are written with, and the scripts that read its files and call the lint.

## The API

### `Text`

`Text.new(options)` returns a reader. `options.tables` is the game's tables by locale, with English
required; `options.localeId` is any BCP-47 tag; `options.plurals` and `options.names` are optional.
`options.locale` names the table to read when it is already known (a server writing in one
locale, a spec walking every table) and is used as given.

| Function | What it returns |
|---|---|
| `get(key, ...)` | The string for `key`, formatted with `string.format` when arguments follow. An argument `{ key = "..." }` is looked up first, and so is `{ <kind> = "<id>" }` for a kind given in `names`, so a translated sentence never gets an English word in a slot. With no arguments the template is returned as written. Arguments that do not fit the placeholders give the bare template back: the reader never raises. |
| `count(key, n, ...)` | A sentence whose noun agrees with `n`, which is the first format argument. Without forms for the key it is the flat string. A fractional `n` takes the `other` form. A count the sentence cannot take gives the bare template, as in `get`. |
| `data(kind, name, field?)` | `get(Keys.of(kind, name, field))`. |
| `name(kind, id)` | The name of one of the game's things in this locale (`Names`); the id itself when the kind was not given or this locale does not name it. |
| `has(key)` | Whether the key has text in this locale or in English. |
| `locale()`, `localeId()` | The resolved locale, and the id it came from. |
| `isRtl()` | Whether this locale is written right to left. |

Amounts are written by the game (`"12.5K"`) and ride `%s`.

**A sentence that does not fit.** The lint is what keeps a template and its arguments in step
(`Lint.tables`, `Lint.plurals`). Behind it the reader is a safety net: a `%d` handed a word, or an
argument short, shows the template as written rather than raising in the middle of a UI update.
Nothing reports it yet (issue #4).

**Plural forms.** `plurals[locale][key][category]`, the category being CLDR's: `zero`, `one`, `two`,
`few`, `many`, `other`. A missing category falls back to `other`, then `many`, then `one`. A locale
with a table and no forms for a key uses its flat string, which is right for a language whose noun
does not change. A locale with no table at all counts in English, by English's rules.

### `Names`

The display names of a game's things (creatures, items, places): one table a locale, keyed by the
thing's own id. The id is what the game saves and matches and never changes; only what is drawn
goes through here. A locale with no table, and an id its table lacks or leaves empty, show the id,
so a game whose ids are its English names ships no English table.

```lua
local PETS: LocaleBlox.NameTables = { ru = require(names.ru), ja = require(names.ja) }
local text = LocaleBlox.Text.new({ tables = Tables, names = { pet = PETS }, localeId = player.LocaleId })
line.Text = text.get("hatched", ownerName, { pet = "Goldbun" })
title.Text = text.name("pet", "Goldbun")
```

`Names.get(tables, locale, id)` is the lookup; `Names.coverage(tables, ids)` counts how many ids
each locale names, fullest first; `Names.keys(tables)` lists every id any table names with the
locales that name it.

### `Said`, `Label`, `Localize`

Text a server puts on a replicated instance (a sign, a prompt, a billboard) is written as a key
and its arguments, and each client draws it in its own language.

```lua
-- shared: the game's sentences, over its own JSON codec
local said = LocaleBlox.Said.new({
	encode = function(value) return HttpService:JSONEncode(value) end,
	decode = function(text) return HttpService:JSONDecode(text) end,
})

-- server
local label = LocaleBlox.Label.new({ said = said, english = englishReader })
label.set(sign, "Text", "priceOf", { { pet = "Goldbun" }, "12K" })
label.plain(sign, "Text", "1,250") -- no language: drops the sentence

-- client
LocaleBlox.Localize.start({ said = said, text = text, collection = CollectionService })
```

- `Said.new(codec)`: `encode(key, args?)` writes a sentence to one string and `decode(text)` reads
  it back (nil for anything that is not one); `read(reader, encoded)` is the sentence in a reader's
  language, `""` for anything else; `same(keyA, argsA, keyB, argsB)` says whether two sentences
  would encode alike without encoding either, and `copy(args)` keeps a caller's arguments as they
  were. An argument is a string, a number, `{ key = "..." }` or `{ <kind> = "<id>" }`.
- `Label.new({ said, english, tag?, prefix? })`: `set(instance, property, key, args?)` writes the
  English into the property (so it is never blank before a client has run), the sentence into the
  attribute `Said_<property>`, and tags the instance `Localized`. Setting the same sentence again
  does nothing. `english(key, args?)` is the sentence in English; one whose arguments do not fit
  reads as its bare template.
- `Localize.start({ said, text, collection, tag?, prefix? })` rewrites every tagged instance in
  the reader's language, those there and those that come, and again whenever the server says
  something new or its English lands late.

A sentence need not ride an instance: `said.encode` gives a string for any wire, and `said.read`
reads it.

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
`Keys.of("product", "double_pay", "blurb")` is `"productDoublePayBlurb"`.

## The lint

Modules that take text and tables and return a sorted list of problems, each a line a person
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
  `key = "value",` per line one tab deep, and closes with `}` at the start of a line. The type is
  any type written on that line (`Table`, `{ [string]: string }`) or none. `aliases` renames a
  variable to its locale code, which is also how a names file whose table is called `names`
  becomes its locale's. `Parse.specifiers(text)` lists a string's `string.format` specifiers: a
  percent, its flags, and a conversion Luau's `string.format` takes (`c d e E f g G i o q s u x X`
  and `*`), which is the pattern `Parse.SPECIFIER`. A lone `%` of plain text is not one.
- `Lint.tables(locales)`: every English key is in every locale and no locale holds a key English
  lacks; a translation has English's specifiers in number and order; no empty string; no combining
  acute accent; no Simplified glyph in `zh-hant` and no Traditional glyph in `zh-hans`; one width
  of "!" and "?" per Chinese table.
- `Lint.names(names, ids, ui?, locales?, where?)`: every locale asked for has a table, every
  table names every id (a missing or empty name would show the id), no two ids share a name in
  one locale, no name is a word of its own locale's UI, and no table names an id the game does
  not have. Each name's writing is `Written.one`'s to check.
- `Lint.plurals(en, plurals)`: every counted key is in English, every category is CLDR's, every
  form has English's specifiers, and every set of forms has `other` or `many`.
- `Written.check(locales, options?)` and `Written.one(code, where, text, options?)`: valid UTF-8,
  no U+FFFD, no control character, no combining accent; every locale in its own script; Arabic
  that starts with an Arabic letter and holds no Latin word. `options.keep` is a list of Lua
  patterns for Latin a translation keeps on purpose; format specifiers, multipliers ("x2"), "R$",
  "Robux" and "Roblox" are always kept.
- `Usage.check(en, sources, options?)`: `sources` is a list of `{ path, text }`. A string literal
  shaped like a key (a lowercase word, then a capital) whose first word starts some English key
  must be a key, and every English key must appear in a source. The literal may stand in double
  quotes, single quotes or backticks; a comment is not read, so a name written in one is neither
  judged nor a use. `options.data` names the first
  words of keys built from game data, which are left to the game's own spec.

## Working on it

`rokit install`, `lefthook install`, then `sh scripts/run-tests.sh` and
`luneblox run tests/Mutate --yes`. `CLAUDE.md` holds the rules and the release steps.

## Licence

MIT.
