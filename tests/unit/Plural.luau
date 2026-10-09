--!strict
--- The plural category of a count, in every language with rules of its own.
local Plural = require("@localeblox/Plural")
local Spec = require("../Spec")

local COUNTS = { 0, 1, 2, 5, 11, 21, 101 }

local function row(locale: string): { string }
	local out: { string } = {}
	for _, n in COUNTS do
		table.insert(out, Plural.category(locale, n))
	end
	return out
end

Spec.test("Russian and Ukrainian: one, few, many by the last digits", function()
	local expected = { "many", "one", "few", "many", "many", "one", "one" }
	Spec.equal(row("ru"), expected, "ru")
	Spec.equal(row("uk"), expected, "uk")
	Spec.equal(Plural.category("ru", 3), "few")
	Spec.equal(Plural.category("ru", 4), "few")
	Spec.equal(Plural.category("ru", 12), "many")
	Spec.equal(Plural.category("ru", 14), "many")
	Spec.equal(Plural.category("ru", 22), "few")
	Spec.equal(Plural.category("ru", 111), "many")
	Spec.equal(Plural.category("ru", 112), "many")
	Spec.equal(Plural.category("ru", 124), "few")
end)

Spec.test("Polish: one only at exactly one", function()
	Spec.equal(row("pl"), { "many", "one", "few", "many", "many", "many", "many" })
	Spec.equal(Plural.category("pl", 4), "few")
	Spec.equal(Plural.category("pl", 12), "many")
	Spec.equal(Plural.category("pl", 22), "few")
	Spec.equal(Plural.category("pl", 112), "many")
end)

Spec.test("Arabic: six categories", function()
	Spec.equal(row("ar"), { "zero", "one", "two", "few", "many", "many", "other" })
	Spec.equal(Plural.category("ar", 3), "few")
	Spec.equal(Plural.category("ar", 10), "few")
	Spec.equal(Plural.category("ar", 99), "many")
	Spec.equal(Plural.category("ar", 100), "other")
	Spec.equal(Plural.category("ar", 102), "other")
	Spec.equal(Plural.category("ar", 103), "few")
end)

Spec.test("French counts zero with one, and so does French of Canada", function()
	local expected = { "one", "one", "other", "other", "other", "other", "other" }
	Spec.equal(row("fr"), expected, "fr")
	Spec.equal(row("fr-CA"), expected, "fr-CA")
end)

Spec.test("one and other: only exactly one differs", function()
	local expected = { "other", "one", "other", "other", "other", "other", "other" }
	for _, locale in { "en", "de", "nl", "es", "es-ES", "pt", "pt-PT", "it", "hi", "fil" } do
		Spec.equal(row(locale), expected, locale)
	end
end)

Spec.test("a language whose noun does not change has one form", function()
	local expected = { "other", "other", "other", "other", "other", "other", "other" }
	for _, locale in { "ja", "ko", "zh-hant", "zh-hans", "th", "vi", "ms", "id", "tr", "xx" } do
		Spec.equal(row(locale), expected, locale)
	end
end)

Spec.test("a fractional count is always other, a whole one unsigned", function()
	Spec.equal(Plural.category("en", 1.9), "other", "1.9 pieces, never 1.9 piece")
	Spec.equal(Plural.category("en", 1.0), "one", "a whole one in a float's coat")
	Spec.equal(Plural.category("en", -1), "one")
	Spec.equal(Plural.category("ru", -22.5), "other")
	Spec.equal(Plural.category("ru", -22), "few")
end)

return nil
