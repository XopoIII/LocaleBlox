# Changelog

Every release is listed here, newest first. The format follows Keep a Changelog, and versions follow
semantic versioning.

## Unreleased

## 0.1.0 - 2026-10-06

The locale machinery of Grabby Pit as a package: the same routing, the same plural rules and the
same lint, with every seam to the game cut. A module reads nothing of the game it is in.

### Added

- `Text.new`: one reader per client, bound to a game's tables, its plural forms and a LocaleId.
  `get` formats a key and looks up an argument that is itself a key; `count` picks the form that
  agrees with a number; `data` reads a piece of game data by its key; `has`, `locale`, `localeId`
  and `isRtl` say what the reader holds.
- `Locale.localeFor`: a Roblox LocaleId to one of twenty-five locales. Belarusian and Kazakh read
  Russian, Tagalog reads Filipino, Chinese is routed by script, Spanish of Spain, Portuguese of
  Portugal and French of Canada have their own tables, and anything unknown reads English.
- `Locale.router`: the lookup that falls back from the locale to English to the key itself, and
  `Locale.isRtl`, `Locale.ALL`.
- `Plural.category`: the CLDR category of a whole count.
- `Keys.of`: the text key of a piece of game data.
- `Parse.source`, `Parse.specifiers`: tables read out of a Luau source as text.
- `Lint.tables`, `Lint.plurals`: key parity both ways, placeholder parity, no empty string, no
  combining acute accent, the two Chinese scripts kept apart, and the plural overlay held to
  English.
- `Written.check`, `Written.one`: valid encoding, every locale in its own script, Arabic that
  starts with an Arabic letter and holds no Latin word.
- `Usage.check`: the code and the English table name the same keys.

### Changed from Grabby Pit's copy

- The reader is made by `Text.new(options)` from a LocaleId, in place of a module that read
  `Players.LocalPlayer` and a `DevLocale` attribute of Workspace when it loaded.
- The lint is functions over text and tables that return their problems, in place of three scripts
  that read a fixed folder and exited. The Latin a game keeps on purpose and the first words of
  its data keys are options, in place of lists that named Grabby Pit's.
- The three regional locales count as their languages do: `fr-CA` counts zero with one, and `es-ES`
  and `pt-PT` have a singular. In Grabby Pit's copy they had one form.
- A locale that ships no table counts in English by English's rules, when English has forms.
- `Lint.tables` names a Chinese glyph of the wrong script by its code point.
- `Locale.router` refuses tables without English by name, in place of failing at the first lookup.

### Not done

- Nothing in this repository runs in Roblox. Every module is plain Luau and runs on LuneBlox, the
  Luau version Roblox runs; the package has not yet been required in a game.
- Not ported: `Said`, which carried a server's sentence as a key and arguments in an attribute or a
  tagged instance, and the creature names with their checks. A game sends keys over its own wire.
- `Parse.source` reads one shape of table: one `key = "value",` a line, one tab deep. A value that
  spans lines or is built by an expression is not read.
- `Usage.check` knows a key by its shape, a lowercase word and then a capital. A key that is one
  lowercase word is never found in code and is always reported unused.
- No Wally package, no `.rbxm` and no roblox-ts typings.
