--!strict
--- The plural category of a count, in every language with rules of its own.
const Plural = require("@localeblox/Plural")
const Spec = require("../Spec")

const COUNTS = { 0, 1, 2, 5, 11, 21, 101 }

const function row(locale: string): { string }
	const out: { string } = {}
	for _, n in COUNTS do
		table.insert(out, Plural.category(locale, n))
	end
	return out
end

Spec.test("Russian and Ukrainian: one, few, many by the last digits", function()
	const expected = { "many", "one", "few", "many", "many", "one", "one" }
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
	const expected = { "one", "one", "other", "other", "other", "other", "other" }
	Spec.equal(row("fr"), expected, "fr")
	Spec.equal(row("fr-CA"), expected, "fr-CA")
end)

Spec.test("one and other: only exactly one differs", function()
	const expected = { "other", "one", "other", "other", "other", "other", "other" }
	for _, locale in { "en", "de", "nl", "es", "es-ES", "pt", "pt-PT", "it", "hi", "fil" } do
		Spec.equal(row(locale), expected, locale)
	end
end)

Spec.test("a language whose noun does not change has one form", function()
	const expected = { "other", "other", "other", "other", "other", "other", "other" }
	for _, locale in { "ja", "ko", "zh-hant", "zh-hans", "th", "vi", "ms", "id", "tr", "xx" } do
		Spec.equal(row(locale), expected, locale)
	end
end)

Spec.test("a count is taken whole and without its sign", function()
	Spec.equal(Plural.category("en", 1.9), "one")
	Spec.equal(Plural.category("en", -1), "one")
	Spec.equal(Plural.category("ru", -22.5), "few")
end)

return nil
