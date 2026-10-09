--!strict
--- LocaleBlox: a game's words in twenty-five languages, as Luau tables looked up by key.
---
---     local LocaleBlox = require(path.to.LocaleBlox)
---     local text = LocaleBlox.Text.new({ tables = Tables, plurals = Plurals, localeId = player.LocaleId })
---     label.Text = text.get("open")
---     label.Text = text.count("itemsCarried", 3, 12)
---
--- A module here reads nothing of the game it is in: the tables, the plural forms, the names and
--- the locale id are arguments. Nothing touches `game`: `Label` and `Localize`, which write on
--- instances, are handed the instance and the collection service. `Parse`, `Lint`, `Written` and
--- `Usage` are the lint, as functions over text and tables, for a game's own scripts and specs.
--- See README.md.
local Keys = require("@self/Keys")
local Label = require("@self/Label")
local Lint = require("@self/Lint")
local Locale = require("@self/Locale")
local Localize = require("@self/Localize")
local Names = require("@self/Names")
local Parse = require("@self/Parse")
local Plural = require("@self/Plural")
local Said = require("@self/Said")
local Text = require("@self/Text")
local Usage = require("@self/Usage")
local Written = require("@self/Written")

export type Locale = Locale.Locale
export type Table = Locale.Table
export type Tables = Locale.Tables
export type Router = Locale.Router
export type Category = Plural.Category
export type Forms = Text.Forms
export type Plurals = Text.Plurals
export type TextOptions = Text.Options
export type Reader = Text.Reader
export type Parsed = Parse.Locales
export type Source = Usage.Source
export type NameTable = Names.Table
export type NameTables = Names.Tables
export type Codec = Said.Codec
export type SaidArg = Said.Arg
export type Sentences = Said.Said
export type Labels = Label.Label
export type LabelOptions = Label.Options
export type LocalizeOptions = Localize.Options

return {
	--- A reader bound to a game's tables and one player's locale.
	Text = Text,
	--- Which table a LocaleId reads, and the lookup with its fallbacks.
	Locale = Locale,
	--- The CLDR plural category of a count.
	Plural = Plural,
	--- The text key of a piece of game data.
	Keys = Keys,
	--- The display names of a game's things, a table a locale.
	Names = Names,
	--- A sentence a server says as a key and its arguments.
	Said = Said,
	--- Server text on a replicated instance, written as a sentence.
	Label = Label,
	--- The client's rewrite of those labels into the reader's language.
	Localize = Localize,
	--- Reads tables out of a Luau source as text.
	Parse = Parse,
	--- Do the tables agree with each other.
	Lint = Lint,
	--- Is every string whole and in its own script.
	Written = Written,
	--- Do the code and the English table name the same keys.
	Usage = Usage,
}
