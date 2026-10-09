--!strict
--- The display names of a game's things: a table a locale, keyed by the thing's own id.
local Names = require("@localeblox/Names")
local Spec = require("../Spec")
local Text = require("@localeblox/Text")

local PETS: Names.Tables = {
	ru = { Goldbun = "RU goldbun", Stormpuff = "RU stormpuff", Pipkin = "" },
	ja = { Goldbun = "JA goldbun" },
	["pt-PT"] = { Goldbun = "PT-PT goldbun", Stormpuff = "PT-PT stormpuff", Pipkin = "PT-PT pipkin" },
}
local ITEMS: Names.Tables = { ru = { key = "RU key" } }
local TABLES = {
	en = { hatched = "%s hatched a %s", worth = "A %s worth %s", zoneHarbour = "Harbour" },
	ru = { hatched = "RU %s hatched %s", worth = "RU %s worth %s", zoneHarbour = "RU harbour" },
}

local function reader(localeId: string): Text.Reader
	return Text.new({ tables = TABLES, names = { pet = PETS, item = ITEMS }, localeId = localeId })
end

Spec.test("a name is the locale's own, and the id where the locale has none", function()
	Spec.equal(Names.get(PETS, "ru", "Goldbun"), "RU goldbun")
	Spec.equal(Names.get(PETS, "ja", "Goldbun"), "JA goldbun")
	Spec.equal(Names.get(PETS, "ja", "Stormpuff"), "Stormpuff", "an id the table lacks")
	Spec.equal(Names.get(PETS, "ru", "Pipkin"), "Pipkin", "an empty name")
	Spec.equal(Names.get(PETS, "en", "Goldbun"), "Goldbun", "a locale with no table")
	Spec.equal(Names.get(PETS, "ru", "Nobody"), "Nobody", "an id nobody names")
end)

Spec.test("coverage counts the ids each locale names, fullest first, ties by code", function()
	Spec.equal(Names.coverage(PETS, { "Goldbun", "Stormpuff", "Pipkin" }), {
		{ locale = "pt-PT", have = 3, total = 3 },
		{ locale = "ru", have = 2, total = 3 },
		{ locale = "ja", have = 1, total = 3 },
	})
	Spec.equal(Names.coverage(PETS, { "Goldbun" }), {
		{ locale = "ja", have = 1, total = 1 },
		{ locale = "pt-PT", have = 1, total = 1 },
		{ locale = "ru", have = 1, total = 1 },
	}, "a tie is in code order")
	Spec.equal(Names.coverage({}, { "Goldbun" }), {}, "no tables")
end)

Spec.test("keys lists every id any table names, with the locales that name it", function()
	Spec.equal(Names.keys(PETS), {
		Goldbun = { "ja", "pt-PT", "ru" },
		Stormpuff = { "pt-PT", "ru" },
		Pipkin = { "pt-PT", "ru" },
	})
end)

Spec.test("a reader names a thing of a kind it was given", function()
	Spec.equal(reader("ru-ru").name("pet", "Goldbun"), "RU goldbun")
	Spec.equal(reader("pt-pt").name("pet", "Pipkin"), "PT-PT pipkin", "a regional table")
	Spec.equal(reader("pt-br").name("pet", "Pipkin"), "Pipkin", "the region's own table, not its neighbour's")
	Spec.equal(reader("en-us").name("pet", "Goldbun"), "Goldbun", "English shows the id")
	Spec.equal(reader("ru").name("item", "key"), "RU key", "a second kind")
	Spec.equal(reader("ru").name("item", "Goldbun"), "Goldbun", "an id of another kind")
	Spec.equal(reader("ru").name("place", "Harbour"), "Harbour", "a kind the reader was not given")
end)

Spec.test("an argument that is a thing gets its name in the reader's language", function()
	Spec.equal(reader("ru").get("hatched", "Ann", { pet = "Goldbun" }), "RU Ann hatched RU goldbun")
	Spec.equal(reader("en").get("hatched", "Ann", { pet = "Goldbun" }), "Ann hatched a Goldbun")
	Spec.equal(reader("ja").get("hatched", "Ann", { pet = "Stormpuff" }), "Ann hatched a Stormpuff")
	Spec.equal(reader("ru").get("worth", { item = "key" }, "12K"), "RU RU key worth 12K")
	Spec.equal(
		reader("ru").get("worth", { key = "zoneHarbour" }, { pet = "Goldbun" }),
		"RU RU harbour worth RU goldbun"
	)
end)

Spec.test("a counted sentence resolves a thing among its arguments too", function()
	local text = Text.new({
		tables = { en = { caught = "%d caught by a %s" } },
		names = { pet = PETS },
		localeId = "ru",
	})
	Spec.equal(text.count("caught", 3, { pet = "Goldbun" }), "3 caught by a RU goldbun")
end)

Spec.test("a table argument that is neither a key nor a known thing reads as the bare template", function()
	local plain = Text.new({ tables = TABLES, localeId = "ru" })
	Spec.equal(
		plain.get("hatched", "Ann", { pet = "Goldbun" }),
		"RU %s hatched %s",
		"left as it came, and no format takes it"
	)
	Spec.equal(reader("ru").get("hatched", "Ann", { pet = 5 } :: any), "RU %s hatched %s", "a name must be a string")
end)

Spec.test("a reader given its table reads it, whatever its locale id would resolve to", function()
	local forced = Text.new({ tables = TABLES, names = { pet = PETS }, localeId = "en-us", locale = "ru" })
	Spec.equal(forced.locale(), "ru")
	Spec.equal(forced.localeId(), "en-us", "the id is kept as given")
	Spec.equal(forced.get("zoneHarbour"), "RU harbour")
	Spec.equal(forced.name("pet", "Goldbun"), "RU goldbun")
	local regional = Text.new({ tables = TABLES, names = { pet = PETS }, localeId = "", locale = "pt-PT" })
	Spec.equal(regional.name("pet", "Pipkin"), "PT-PT pipkin")
	Spec.equal(regional.get("zoneHarbour"), "Harbour", "a locale with no text table reads English")
end)

return nil
