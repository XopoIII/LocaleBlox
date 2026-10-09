--!strict
--- A game's use of the whole public API, as the README shows it. It is checked by the type gate
--- under both solvers (`scripts/type-check.sh`).
---
--- When the API changes, this file changes with it, and the README's example after it.
local LocaleBlox = require("@localeblox")

-- The game's own tables stay in the game.
local en: LocaleBlox.Table = {
	feed = "Feed",
	movedTo = "%s's camp moved to the %s",
	zoneHarbour = "Harbour",
	pieces = "%d / %d pieces carried off",
	foodSugarCube = "Sugar cube",
}
local ru: LocaleBlox.Table = {
	feed = "RU feed",
	movedTo = "RU %s moved to %s",
	zoneHarbour = "RU harbour",
	pieces = "RU %d of %d",
	foodSugarCube = "RU sugar",
}
local tables: LocaleBlox.Tables = { en = en, ru = ru }
local plurals: LocaleBlox.Plurals = {
	en = { pieces = { one = "%d / %d piece carried off", other = "%d / %d pieces carried off" } },
}

-- One reader per client, from the player's LocaleId.
local text: LocaleBlox.Reader = LocaleBlox.Text.new({ tables = tables, plurals = plurals, localeId = "ru-ru" })
local _feed: string = text.get("feed")
local _moved: string = text.get("movedTo", "Ann", { key = "zoneHarbour" })
local _pieces: string = text.count("pieces", 3, 12)
local _food: string = text.data("food", "sugar_cube")
local _known: boolean = text.has("feed")
local _locale: LocaleBlox.Locale = text.locale()
local _id: string = text.localeId()
local _mirror: boolean = text.isRtl()

-- The names of the game's things, a table a locale, and a reader that resolves them.
local pets: LocaleBlox.NameTables = { ru = { Goldbun = "RU goldbun" } }
local named: LocaleBlox.Reader = LocaleBlox.Text.new({
	tables = tables,
	names = { pet = pets },
	localeId = "ru-ru",
	locale = "ru",
})
local _hatched: string = named.get("movedTo", { pet = "Goldbun" }, { key = "zoneHarbour" })
local _pet: string = named.name("pet", "Goldbun")
local _plain: string = LocaleBlox.Names.get(pets, "ru", "Goldbun")
local _coverage: number = #LocaleBlox.Names.coverage(pets, { "Goldbun" })
local _named: { [string]: { LocaleBlox.Locale } } = LocaleBlox.Names.keys(pets)

-- A server's sentence, its label on an instance, and the client's rewrite. On Roblox the codec is
-- HttpService's JSON pair and the collection is CollectionService.
local codec: LocaleBlox.Codec = {
	encode = function(_value: any): string
		return "{}"
	end,
	decode = function(_text: string): any
		return {}
	end,
}
local said: LocaleBlox.Sentences = LocaleBlox.Said.new(codec)
local args: { LocaleBlox.SaidArg } = { "Ann", { pet = "Goldbun" }, 3 }
local wire: string = said.encode("movedTo", args)
local _read: string = said.read(named, wire)
local _same: boolean = said.same("movedTo", args, "movedTo", said.copy(args))
local _saidKey: string?, _saidArgs: { any } = said.decode(wire)
local labelOptions: LocaleBlox.LabelOptions = { said = said, english = text, tag = "Localized", prefix = "Said_" }
local label: LocaleBlox.Labels = LocaleBlox.Label.new(labelOptions)
local _english: string = label.english("movedTo", args)
local sign = Instance.new("TextLabel")
label.set(sign, "Text", "movedTo", args)
label.plain(sign, "Text", "1,250")
local localizeOptions: LocaleBlox.LocalizeOptions = {
	said = said,
	text = named,
	collection = game:GetService("CollectionService"),
}
LocaleBlox.Localize.start(localizeOptions)

-- The pieces on their own.
local router: LocaleBlox.Router = LocaleBlox.Locale.router(tables)
local locale: LocaleBlox.Locale = LocaleBlox.Locale.localeFor("zh-tw")
local _word: string = router.get(locale, "feed")
local _keys: { string } = router.keys("en")
local _shipped: { LocaleBlox.Locale } = router.populated()
local _all: number = #LocaleBlox.Locale.ALL
local _rtl: boolean = LocaleBlox.Locale.isRtl("ar")
local _category: LocaleBlox.Category = LocaleBlox.Plural.category("ru", 21)
local _key: string = LocaleBlox.Keys.of("food", "sugar_cube", "hint")

-- The lint, for the game's own scripts and specs.
local parsed: LocaleBlox.Parsed = {}
LocaleBlox.Parse.source('local en = {\n\tfeed = "Feed",\n}', parsed, { zhHans = "zh-hans" })
local _specifiers: { string } = LocaleBlox.Parse.specifiers("%d / %d")
local sources: { LocaleBlox.Source } = { { path = "src/client/Hud.luau", text = 'text.get("feed")' } }
local problems: { string } = {}
for _, found in
	{
		LocaleBlox.Lint.tables(parsed),
		LocaleBlox.Lint.plurals(en, plurals),
		LocaleBlox.Lint.names(pets, { "Goldbun" }, tables, { "ru" }, "petnames"),
		LocaleBlox.Written.check(parsed, { keep = { "MAX" } }),
		LocaleBlox.Written.one("ru", "ru.feed", "Feed"),
		LocaleBlox.Usage.check(en, sources, { data = { "food", "zone" } }),
		-- and on the tables a game requires, as its spec does in Roblox
		LocaleBlox.Lint.tables(tables),
		LocaleBlox.Written.check(tables),
	}
do
	table.move(found, 1, #found, #problems + 1, problems)
end
