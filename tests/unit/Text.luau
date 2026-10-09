--!strict
--- The reader: a key to a string, in the player's locale.
local Spec = require("../Spec")
local Text = require("@localeblox/Text")

local TABLES = {
	en = {
		feed = "Feed",
		level = "Lv %d",
		movedTo = "%s's camp moved to the %s",
		zoneHarbour = "Harbour",
		pieces = "%d / %d pieces carried off",
		minutes = "%d min",
		foodSugarCube = "Sugar cube",
		upgradeSpeedHint = "faster trips",
		full = "100%% full",
		greet = "Hi %s",
		trio = "%s, %s and %s",
		owned = "%d of %s",
		shared = "%d of %s and %s",
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

local PLURALS = {
	en = { pieces = { one = "%d / %d piece carried off", other = "%d / %d pieces carried off" } },
	ru = { pieces = { one = "RU %d of %d one", few = "RU %d of %d few", many = "RU %d of %d many" } },
}

local function reader(localeId: string): Text.Reader
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
	Spec.equal(reader("en").get("movedTo", { key = "feed" }, "Harbour"), "Feed's camp moved to the Harbour")
	Spec.equal(
		reader("ru").get("movedTo", { key = "feed" }, { key = "zoneHarbour" }),
		"RU RU feed moved to RU harbour",
		"every key among them"
	)
end)

Spec.test("a key is looked up wherever it stands, among one argument, two, three and more", function()
	local ru = reader("ru")
	Spec.equal(ru.get("greet", { key = "feed" }), "Hi RU feed")
	Spec.equal(ru.get("greet", "Ann"), "Hi Ann")
	Spec.equal(ru.get("movedTo", { key = "feed" }, "x"), "RU RU feed moved to x")
	Spec.equal(ru.get("movedTo", "x", { key = "feed" }), "RU x moved to RU feed")
	Spec.equal(ru.get("trio", { key = "feed" }, "b", "c"), "RU feed, b and c")
	Spec.equal(ru.get("trio", "a", { key = "feed" }, "c"), "a, RU feed and c")
	Spec.equal(ru.get("trio", "a", "b", { key = "feed" }), "a, b and RU feed")
	Spec.equal(ru.get("trio", "a", "b", "c"), "a, b and c")
	Spec.equal(ru.count("owned", 2, { key = "feed" }), "2 of RU feed")
	Spec.equal(ru.count("owned", 2, "Ann"), "2 of Ann")
	Spec.equal(ru.count("shared", 2, { key = "feed" }, "Ann"), "2 of RU feed and Ann")
	Spec.equal(ru.count("shared", 2, "Ann", { key = "feed" }), "2 of Ann and RU feed")
end)

Spec.test("an argument the format cannot take gives the bare template, in every place", function()
	local en = reader("en")
	Spec.equal(en.get("greet", nil), "Hi %s", "nil is no string")
	Spec.equal(en.get("movedTo", nil, "Harbour"), "%s's camp moved to the %s")
	Spec.equal(en.get("movedTo", "Ann", nil), "%s's camp moved to the %s")
	Spec.equal(en.get("trio", "a", "b"), "%s, %s and %s", "one short of three")
	Spec.equal(en.get("trio", "a", nil, "c"), "%s, %s and %s")
	Spec.equal(en.count("owned", 2), "%d of %s")
	Spec.equal(en.count("owned", 2, nil), "%d of %s")
	Spec.equal(en.count("shared", 2, "Ann"), "%d of %s and %s")
	-- A table that is no word is left as it came, and no format takes a table.
	Spec.equal(en.get("greet", {}), "Hi %s", "alone")
	Spec.equal(en.get("greet", { key = 5 }), "Hi %s", "a key is a string")
	Spec.equal(en.get("movedTo", {}, "x"), "%s's camp moved to the %s", "first of two")
	Spec.equal(en.get("movedTo", "x", {}), "%s's camp moved to the %s", "second of two")
	Spec.equal(en.get("trio", "a", {}, "c"), "%s, %s and %s", "among three")
	Spec.equal(en.count("owned", 2, {}), "%d of %s", "after a count")
	Spec.equal(en.count("shared", 2, "Ann", {}), "%d of %s and %s", "after a count and one more")
end)

Spec.test("a template with no arguments is returned as written", function()
	Spec.equal(reader("en").get("level"), "Lv %d")
	Spec.equal(reader("en").get("full"), "100%% full", "an escaped percent stays as written")
end)

Spec.test("a sentence whose arguments do not fit reads as its bare template", function()
	Spec.equal(reader("en").get("movedTo", "Ann"), "%s's camp moved to the %s", "too few arguments")
	Spec.equal(reader("en").get("level", "many"), "Lv %d", "a %d handed a string")
	Spec.equal(reader("en").get("movedTo", { key = "zoneHarbour" }), "%s's camp moved to the %s", "a word too few")
	Spec.equal(reader("en").get("level", { key = "zoneHarbour" }), "Lv %d", "a %d handed a word")
	Spec.equal(reader("en").get("feed", 1, 2), "Feed", "arguments a sentence has no place for are no fault")
end)

Spec.test("a count its sentence cannot take reads as its bare template", function()
	Spec.equal(reader("en").count("pieces", 1), "%d / %d piece carried off", "a count short an argument")
	Spec.equal(reader("en").count("pieces", 2), "%d / %d pieces carried off", "the form is the number's")
	Spec.equal(reader("ru").count("minutes", 5, 6), "RU 5 min", "an argument too many is no fault")
end)

Spec.test("a counted sentence agrees with its number", function()
	local ru = reader("ru")
	Spec.equal(ru.count("pieces", 1, 12), "RU 1 of 12 one")
	Spec.equal(ru.count("pieces", 3, 12), "RU 3 of 12 few")
	Spec.equal(ru.count("pieces", 5, 12), "RU 5 of 12 many")
	Spec.equal(ru.count("pieces", 21, 30), "RU 21 of 30 one")
	local en = reader("en")
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
	local ja = reader("ja")
	Spec.equal(ja.count("pieces", 1, 12), "1 / 12 piece carried off")
	Spec.equal(ja.count("pieces", 5, 12), "5 / 12 pieces carried off")
end)

Spec.test("a category the forms lack falls back to other, then many", function()
	local text = Text.new({
		tables = { en = { coins = "%d coins" }, ar = { coins = "AR %d flat" }, pl = { coins = "PL %d flat" } },
		plurals = {
			ar = { coins = { one = "AR %d one", other = "AR %d other" } },
			pl = { coins = { one = "PL %d one", many = "PL %d many" } },
		},
		localeId = "ar",
	})
	Spec.equal(text.count("coins", 1), "AR 1 one")
	Spec.equal(text.count("coins", 2), "AR 2 other", "no two form")
	local pl = Text.new({
		tables = { en = { coins = "%d coins" }, pl = { coins = "PL %d flat" } },
		plurals = { pl = { coins = { one = "PL %d one", many = "PL %d many" } } },
		localeId = "pl",
	})
	Spec.equal(pl.count("coins", 3), "PL 3 many", "no few and no other form")
	local both = Text.new({
		tables = { en = { coins = "%d coins" }, pl = { coins = "PL %d flat" } },
		plurals = { pl = { coins = { one = "PL %d one", many = "PL %d many", other = "PL %d other" } } },
		localeId = "pl",
	})
	Spec.equal(both.count("coins", 3), "PL 3 other", "other comes before many")
end)

Spec.test("game data reads by its key", function()
	local en = reader("en")
	Spec.equal(en.data("food", "sugar_cube"), "Sugar cube")
	Spec.equal(en.data("zone", "harbour"), "Harbour")
	Spec.equal(en.data("upgrade", "speed", "hint"), "faster trips")
	Spec.equal(en.data("food", "unknown"), "foodUnknown", "the key itself when there is no text")
end)

Spec.test("has says whether a key has text", function()
	local ru = reader("ru")
	Spec.equal(ru.has("feed"), true)
	Spec.equal(ru.has("level"), true, "through English")
	Spec.equal(ru.has("nothing"), false)
end)

Spec.test("the reader says which locale it reads and whether it runs right to left", function()
	local ar = reader("ar-sa")
	Spec.equal(ar.locale(), "ar")
	Spec.equal(ar.localeId(), "ar-sa")
	Spec.equal(ar.isRtl(), true)
	local ru = reader("kk-kz")
	Spec.equal(ru.locale(), "ru")
	Spec.equal(ru.localeId(), "kk-kz")
	Spec.equal(ru.isRtl(), false)
end)

Spec.test("a reader with no plural forms still counts", function()
	local text = Text.new({ tables = { en = { coins = "%d coins" } }, localeId = "en" })
	Spec.equal(text.count("coins", 1), "1 coins")
end)

return nil
