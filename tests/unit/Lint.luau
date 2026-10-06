--!strict
--- The tables agree with each other, or the lint says where they do not.
const Lint = require("@localeblox/Lint")
const Locale = require("@localeblox/Locale")
const Spec = require("../Spec")

const SIMPLIFIED_DOOR, TRADITIONAL_DOOR = utf8.char(0x95E8), utf8.char(0x9580)
const HAN = utf8.char(0x86C1)
const FULL_BANG = utf8.char(0xFF01)

Spec.test("tables that agree are clean", function()
	Spec.equal(
		Lint.tables({
			en = { feed = "Feed", level = "Lv %d", moved = "%s to %s" },
			ru = { feed = "RU", level = "RU %d", moved = "RU %s, %s" },
			["zh-hant"] = {
				feed = HAN .. TRADITIONAL_DOOR,
				level = "%d" .. HAN,
				moved = "%s" .. HAN .. "%s" .. FULL_BANG,
			},
			["zh-hans"] = { feed = HAN .. SIMPLIFIED_DOOR, level = "%d" .. HAN, moved = "%s" .. HAN .. "%s!" },
		}),
		{}
	)
end)

Spec.test("tables keyed by a locale type are read as tables keyed by a string are", function()
	const tables: Locale.Tables = { en = { feed = "Feed", close = "Close" }, ru = { feed = "RU" } }
	Spec.equal(Lint.tables(tables), { 'ru: missing key "close"' })
end)

Spec.test("no English table is one problem", function()
	Spec.equal(Lint.tables({ ru = { feed = "RU" } }), { "en: there is no English table" })
end)

Spec.test("a missing key and a key English lacks are both named", function()
	Spec.equal(Lint.tables({ en = { feed = "Feed", close = "Close" }, ru = { feed = "RU", extra = "RU" } }), {
		'ru: key "extra" is not in English',
		'ru: missing key "close"',
	})
end)

Spec.test("placeholders must match English in number, kind and order", function()
	Spec.equal(Lint.tables({ en = { a = "%d of %s" }, ru = { a = "%s of %d" } }), {
		"ru.a: placeholders [%s,%d] are not English's [%d,%s]",
	})
	Spec.equal(Lint.tables({ en = { a = "%d" }, ru = { a = "none" } }), {
		"ru.a: placeholders [] are not English's [%d]",
	})
	Spec.equal(Lint.tables({ en = { a = "Feed" }, ru = { a = "%s" } }), {
		"ru.a: placeholders [%s] are not English's []",
	})
	Spec.equal(Lint.tables({ en = { a = "%d%%" }, ru = { a = "%d %%" } }), {}, "an escaped percent is not one")
end)

Spec.test("an empty string is a problem in any table", function()
	Spec.equal(Lint.tables({ en = { a = "", b = "B" }, ru = { a = "RU", b = "" } }), {
		"en.a: empty string",
		"ru.b: empty string",
	})
end)

Spec.test("a combining acute accent is a problem", function()
	Spec.equal(Lint.tables({ en = { a = "A" }, ru = { a = "a" .. utf8.char(0x301) } }), {
		"ru.a: combining acute accent U+0301",
	})
end)

Spec.test("a glyph of the other Chinese script is named by its code point", function()
	Spec.equal(Lint.tables({ en = { a = "A" }, ["zh-hant"] = { a = SIMPLIFIED_DOOR } }), {
		"zh-hant.a: Simplified glyph U+95E8 in this table",
	})
	Spec.equal(Lint.tables({ en = { a = "A" }, ["zh-hans"] = { a = TRADITIONAL_DOOR } }), {
		"zh-hans.a: Traditional glyph U+9580 in this table",
	})
	Spec.equal(Lint.tables({ en = { a = "A" }, ja = { a = SIMPLIFIED_DOOR } }), {}, "only Chinese is checked")
end)

Spec.test("a Chinese table uses one width of ! and ?", function()
	Spec.equal(
		Lint.tables({
			en = { m = "M", b = "B", k = "K", c = "C", z = "Z", f = "F" },
			["zh-hans"] = {
				m = HAN .. FULL_BANG,
				b = HAN .. FULL_BANG,
				k = HAN .. "?",
				c = HAN .. "?",
				z = HAN .. "!",
				f = HAN .. utf8.char(0xFF1F),
			},
		}),
		{ 'zh-hans: mixes full-width (as in b) and half-width (as in c) "!" and "?"' }
	)
	Spec.equal(Lint.tables({ en = { a = "A", b = "B" }, ru = { a = "RU" .. FULL_BANG, b = "RU?" } }), {}, "not Russian")
end)

Spec.test("plural forms that agree with English are clean", function()
	Spec.equal(
		Lint.plurals({ ants = "%d ants" }, {
			en = { ants = { one = "%d ant", other = "%d ants" } },
			ru = { ants = { one = "%d a", few = "%d b", many = "%d c" } },
		}),
		{}
	)
end)

Spec.test("plural forms are held to English's key, placeholders and categories", function()
	Spec.equal(
		Lint.plurals({ ants = "%d ants" }, {
			ru = {
				ants = { one = "one", few = "", many = "%d c", several = "%d d" },
				bees = { one = "%d", other = "%d" },
			},
			pl = { ants = { one = "%d a", few = "%d b" } },
		}),
		{
			'pl.ants: no "other" or "many" form to fall back on',
			"ru.ants.few: empty string",
			"ru.ants.one: placeholders are not English's",
			"ru.ants.several: not a plural category",
			"ru.bees: counted key is not in English",
		}
	)
end)

return nil
