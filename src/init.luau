--!strict
--- LocaleBlox: a game's words in twenty-five languages, as Luau tables looked up by key.
---
---     const LocaleBlox = require(path.to.LocaleBlox)
---     const text = LocaleBlox.Text.new({ tables = Tables, plurals = Plurals, localeId = player.LocaleId })
---     label.Text = text.get("feed")
---     label.Text = text.count("piecesCarried", 3, 12)
---
--- A module here reads nothing of the game it is in: the tables, the plural forms and the locale
--- id are arguments. Nothing touches `game`. `Parse`, `Lint`, `Written` and `Usage` are the lint,
--- as functions over text and tables, for a game's own scripts and specs. See README.md.
const Keys = require("@self/Keys")
const Lint = require("@self/Lint")
const Locale = require("@self/Locale")
const Parse = require("@self/Parse")
const Plural = require("@self/Plural")
const Text = require("@self/Text")
const Usage = require("@self/Usage")
const Written = require("@self/Written")

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

return {
	--- A reader bound to a game's tables and one player's locale.
	Text = Text,
	--- Which table a LocaleId reads, and the lookup with its fallbacks.
	Locale = Locale,
	--- The CLDR plural category of a count.
	Plural = Plural,
	--- The text key of a piece of game data.
	Keys = Keys,
	--- Reads tables out of a Luau source as text.
	Parse = Parse,
	--- Do the tables agree with each other.
	Lint = Lint,
	--- Is every string whole and in its own script.
	Written = Written,
	--- Do the code and the English table name the same keys.
	Usage = Usage,
}
