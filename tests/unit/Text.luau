--!strict
--- The reader: a key to a string, in the player's locale.
const Text = require("@localeblox/Text")
const Spec = require("../Spec")

const TABLES = {
	en = {
		feed = "Feed",
		level = "Lv %d",
		movedTo = "%s's camp moved to the %s",
		zoneHarbour = "Harbour",
		pieces = "%d / %d pieces carried off",
		minutes = "%d min",
		foodSugarCube = "Sugar cube",
		upgradeSpeedHint = "faster trips",
	},
	ru = {
		feed = "RU feed",
		movedTo = "RU %s moved to %s",
		zoneHarbour = "RU harbour",
		pieces = "RU %d of %d flat",
		minutes = "RU %d min",
	},
	de = {
		feed = "DE feed",
		pieces = "DE %d of %d flat",
	},
}

const PLURALS = {
	en = { pieces = { one = "%d / %d piece carried off", other = "%d / %d pieces carried off" } },
	ru = { pieces = { one = "RU %d of %d one", few = "RU %d of %d few", many = "RU %d of %d many" } },
}

const function reader(localeId: string): Text.Reader
	return Text.new({ tables = TABLES, plurals = PLURALS, localeId = localeId })
end

Spec.test("a key reads in the player's locale", function()
	Spec.equal(reader("ru-ru").get("feed"), "RU feed")
	Spec.equal(reader("en-us").get("feed"), "Feed")
	Spec.equal(reader("de-de").get("feed"), "DE feed")
	Spec.equal(reader("be").get("feed"), "RU feed", "Belarusian reads Russian")
end)

Spec.test("a missing string falls back to English, then to the key", function()
	Spec.equal(reader("ru").get("level", 3), "Lv 3", "a key Russian lacks")
	Spec.equal(reader("ja").get("feed"), "Feed", "a locale with no table")
	Spec.equal(reader("ru").get("nothing"), "nothing")
end)

Spec.test("arguments are formatted, and a key among them is looked up first", function()
	Spec.equal(reader("en").get("movedTo", "Ann", { key = "zoneHarbour" }), "Ann's camp moved to the Harbour")
	Spec.equal(reader("ru").get("movedTo", "Ann", { key = "zoneHarbour" }), "RU Ann moved to RU harbour")
	Spec.equal(reader("en").get("level", 12), "Lv 12")
end)

Spec.test("a template with no arguments is returned as written", function()
	Spec.equal(reader("en").get("level"), "Lv %d")
end)

Spec.test("a counted sentence agrees with its number", function()
	const ru = reader("ru")
	Spec.equal(ru.count("pieces", 1, 12), "RU 1 of 12 one")
	Spec.equal(ru.count("pieces", 3, 12), "RU 3 of 12 few")
	Spec.equal(ru.count("pieces", 5, 12), "RU 5 of 12 many")
	Spec.equal(ru.count("pieces", 21, 30), "RU 21 of 30 one")
	const en = reader("en")
	Spec.equal(en.count("pieces", 1, 12), "1 / 12 piece carried off")
	Spec.equal(en.count("pieces", 0, 12), "0 / 12 pieces carried off")
	Spec.equal(en.count("pieces", 2, 12), "2 / 12 pieces carried off")
end)

Spec.test("a count with no forms uses the flat string of its locale", function()
	Spec.equal(reader("ru").count("minutes", 5), "RU 5 min")
	Spec.equal(reader("de").count("pieces", 1, 12), "DE 1 of 12 flat", "German ships no forms")
	Spec.equal(reader("en").count("minutes", 1), "1 min")
end)

Spec.test("a locale with no table counts in English, by English's rules", function()
	const ja = reader("ja")
	Spec.equal(ja.count("pieces", 1, 12), "1 / 12 piece carried off")
	Spec.equal(ja.count("pieces", 5, 12), "5 / 12 pieces carried off")
end)

Spec.test("a category the forms lack falls back to other, then many", function()
	const text = Text.new({
		tables = { en = { coins = "%d coins" }, ar = { coins = "AR %d flat" }, pl = { coins = "PL %d flat" } },
		plurals = {
			ar = { coins = { one = "AR %d one", other = "AR %d other" } },
			pl = { coins = { one = "PL %d one", many = "PL %d many" } },
		},
		localeId = "ar",
	})
	Spec.equal(text.count("coins", 1), "AR 1 one")
	Spec.equal(text.count("coins", 2), "AR 2 other", "no two form")
	const pl = Text.new({
		tables = { en = { coins = "%d coins" }, pl = { coins = "PL %d flat" } },
		plurals = { pl = { coins = { one = "PL %d one", many = "PL %d many" } } },
		localeId = "pl",
	})
	Spec.equal(pl.count("coins", 3), "PL 3 many", "no few and no other form")
	const both = Text.new({
		tables = { en = { coins = "%d coins" }, pl = { coins = "PL %d flat" } },
		plurals = { pl = { coins = { one = "PL %d one", many = "PL %d many", other = "PL %d other" } } },
		localeId = "pl",
	})
	Spec.equal(both.count("coins", 3), "PL 3 other", "other comes before many")
end)

Spec.test("game data reads by its key", function()
	const en = reader("en")
	Spec.equal(en.data("food", "sugar_cube"), "Sugar cube")
	Spec.equal(en.data("zone", "harbour"), "Harbour")
	Spec.equal(en.data("upgrade", "speed", "hint"), "faster trips")
	Spec.equal(en.data("food", "unknown"), "foodUnknown", "the key itself when there is no text")
end)

Spec.test("has says whether a key has text", function()
	const ru = reader("ru")
	Spec.equal(ru.has("feed"), true)
	Spec.equal(ru.has("level"), true, "through English")
	Spec.equal(ru.has("nothing"), false)
end)

Spec.test("the reader says which locale it reads and whether it runs right to left", function()
	const ar = reader("ar-sa")
	Spec.equal(ar.locale(), "ar")
	Spec.equal(ar.localeId(), "ar-sa")
	Spec.equal(ar.isRtl(), true)
	const ru = reader("kk-kz")
	Spec.equal(ru.locale(), "ru")
	Spec.equal(ru.localeId(), "kk-kz")
	Spec.equal(ru.isRtl(), false)
end)

Spec.test("a reader with no plural forms still counts", function()
	const text = Text.new({ tables = { en = { coins = "%d coins" } }, localeId = "en" })
	Spec.equal(text.count("coins", 1), "1 coins")
end)

return nil
