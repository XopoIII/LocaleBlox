# Changelog

Every release is listed here, newest first. The format follows Keep a Changelog, and versions follow
semantic versioning.

## 0.3.0 - 2026-10-09

A reader that never raises, a lint that reads code as code, and the same words as 0.2.0: on the
first game's twenty-five tables every answer of the two versions was compared, and none differ.

### Changed

- `Text.get` and `Text.count` never raise. Arguments that do not fit the placeholders (a `%d`
  handed a word, an argument short, a `nil`) give the bare template back; in 0.2.0 the call
  raised. A game that caught that error to learn of a bad sentence no longer hears of it: nothing
  reports the failure yet (issue #4), and the lint stays the gate.
- `Plural.category`: a fractional count is "other" in every locale (CLDR: a fraction agrees with
  no noun); it was rounded down before. Whole counts are as they were.
- `Usage.check` reads code as code. A key may stand in single quotes or backticks as well as in
  double quotes, and a comment is not read: `--` to the end of its line, and a `--[[ ]]` or
  `--[=[ ]=]` block. A name in a comment is no longer judged, and a key that only a comment names
  is no longer counted as used. Two dashes inside a string open no comment.
- `Parse.specifiers`, and the specifiers `Written` leaves out of its script check, are the ones
  Luau's `string.format` takes: a conversion of `c d e E f g G i o q s u x X`, or `*`. A lone `%`
  of plain text ("Save 50% today") is no longer a specifier, and neither is `%p` or any other
  letter the VM refuses; `%*` now is one. In 0.2.0 both took any letter after a percent.
- Every module table is frozen, and so is the table the package returns. A reader is still the
  caller's own table.
- The sources are written with `local` for every binding; 0.2.0 used `const`. Luau reads both,
  and 0.2.0 ran in a live game as it was, so nothing changes for a game that installs the
  package. `Parse.opens` and `Parse.source` read a table declared with either word.

### Added

- `Parse.SPECIFIER`: the Lua pattern of one `string.format` specifier, the one `Parse`, `Lint`
  and `Written` share.

### Fixed

- `Localize` drops a label's listeners when its instance is destroyed, instead of holding a dead
  instance's connections.

### Faster

- A sentence with up to three arguments, and a count with up to two beside it, are formatted
  without a table made to hold the arguments. With more, the call is 0.2.0's with the guard
  around it. The lookup of a key alone is as it was.
- `Usage.check` walks a source once with plain searches; over the first game's 534 files it costs
  what 0.2.0's did, with the comments now left out.

### Known, not fixed

- A sentence that does not fit shows its bare template and nothing reports it (issue #4).
- `Usage.check` walks strings to tell a comment from text, and does not follow a backtick string
  nested inside another's `{}`; a `--` after such a nesting may be read on the wrong side.

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
