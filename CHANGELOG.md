# Changelog

Every release is listed here, newest first. The format follows Keep a Changelog, and versions follow
semantic versioning.

## Unreleased

### Changed

- Every module is stock Luau again: `const` is not a Luau keyword, and a file only a dialect
  parsed was a file no Roblox game could load.
- Every module table is frozen.

### Fixed

- `Text.get` and `Text.count`: arguments that do not fit the placeholders give the bare template
  back rather than raising on the client.
- `Plural.category`: a fractional count is "other" in every locale (CLDR: a fraction agrees with
  no noun); it was rounded down before.
- `Parse.specifiers`: a lone `%` of plain text ("Save 50% today") is no longer read as a
  specifier; the conversion letter must be one `string.format` knows.
- `Usage.check` sees keys in single quotes and in backtick strings, not only in double quotes.
- `Localize` drops a label's listeners when its instance is destroyed, instead of holding a dead
  instance's connections.

## 0.2.0 - 2026-10-07

What the first game still kept beside the package, made general: the names of a game's things, and
a server's sentences. Nothing here names a game or one of its kinds of thing.

### Added

- `Names`: display names by locale and id, with `get`, `coverage` and `keys`. A locale with no
  table, and an id its table lacks or leaves empty, show the id.
- `Text.new` takes `names`, by kind: `{ <kind> = "<id>" }` is then an argument of `get` and
  `count`, and `name(kind, id)` a lookup. A table argument that is neither a key nor a known thing
  is left as it came.
- `Text.new` takes `locale`: the table to read, used as given in place of what `localeId` resolves
  to. For a server writing in one locale and for a spec walking every table.
- `Said`: a sentence as a key and its arguments in one string, over the game's own codec, with
  `encode`, `decode`, `read`, `same` and `copy`.
- `Label` and `Localize`: a server's text on a replicated instance as a sentence, and the client's
  rewrite of it. The instance and the collection service are arguments; neither module reads a
  service.
- `Lint.names`: the faults of a kind's name tables.
- `Parse.opens(line)`, and `Parse.source` reads a table whose type is written out
  (`local names: { [string]: string } = {`), which is the shape of a names file.

### Changed

- No file names a game any more: the examples and the specs' words are neutral ones.

### Kept as they were, on purpose

- `es-ES`, `pt-PT` and `fr-CA` have a singular, and a locale with no table counts by English's
  rules. The first game's own copy differed in both; neither showed on its data, and these are
  the languages' rules.

## 0.1.1 - 2026-10-06

### Fixed

- `Lint.tables` and `Written.check` take a game's own `Tables` as well as what `Parse.source`
  read. In 0.1.0 their parameter was keyed by `string`, so a spec that handed them the tables it
  requires failed the type gate under the new solver, and only a cast would pass it. The first
  game to pin the package found it; the consumer file now makes both calls.

## 0.1.0 - 2026-10-06

The locale machinery of a live game as a package: the same routing, the same plural rules and the
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

### Changed from the game's own copy

- The reader is made by `Text.new(options)` from a LocaleId, in place of a module that read
  `Players.LocalPlayer` and a `DevLocale` attribute of Workspace when it loaded.
- The lint is functions over text and tables that return their problems, in place of three scripts
  that read a fixed folder and exited. The Latin a game keeps on purpose and the first words of
  its data keys are options, in place of lists that named that game's.
- The three regional locales count as their languages do: `fr-CA` counts zero with one, and `es-ES`
  and `pt-PT` have a singular. In the game's own copy they had one form.
- A locale that ships no table counts in English by English's rules, when English has forms.
- `Lint.tables` names a Chinese glyph of the wrong script by its code point.
- `Locale.router` refuses tables without English by name, in place of failing at the first lookup.

### Not done

- Nothing in this repository runs in Roblox. Every module is plain Luau and runs on LuneBlox, the
  Luau version Roblox runs. Before this release the sources were mounted once into a test place
  and required in a real server, where every module answered; no game has shipped with it.
- Not ported: `Said`, which carried a server's sentence as a key and arguments in an attribute or a
  tagged instance, and the creature names with their checks. A game sends keys over its own wire.
  (Both came in 0.2.0, made general: `Said`, `Label`, `Localize` and `Names`.)
- `Parse.source` reads one shape of table: one `key = "value",` a line, one tab deep. A value that
  spans lines or is built by an expression is not read.
- `Usage.check` knows a key by its shape, a lowercase word and then a capital. A key that is one
  lowercase word is never found in code and is always reported unused.
- No Wally package, no `.rbxm` and no roblox-ts typings.
