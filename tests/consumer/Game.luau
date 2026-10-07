--!strict
--- A game's use of the whole public API, as the README shows it. It is checked by the type gate
--- under both solvers (`scripts/type-check.sh`).
---
--- When the API changes, this file changes with it, and the README's example after it.
const LocaleBlox = require("@localeblox")

-- The game's own tables stay in the game.
const en: LocaleBlox.Table = {
	feed = "Feed",
	movedTo = "%s's camp moved to the %s",
	zoneHarbour = "Harbour",
	pieces = "%d / %d pieces carried off",
	foodSugarCube = "Sugar cube",
}
const ru: LocaleBlox.Table = {
	feed = "RU feed",
	movedTo = "RU %s moved to %s",
	zoneHarbour = "RU harbour",
	pieces = "RU %d of %d",
	foodSugarCube = "RU sugar",
}
const tables: LocaleBlox.Tables = { en = en, ru = ru }
const plurals: LocaleBlox.Plurals = {
	en = { pieces = { one = "%d / %d piece carried off", other = "%d / %d pieces carried off" } },
}

-- One reader per client, from the player's LocaleId.
const text: LocaleBlox.Reader = LocaleBlox.Text.new({ tables = tables, plurals = plurals, localeId = "ru-ru" })
const _feed: string = text.get("feed")
const _moved: string = text.get("movedTo", "Ann", { key = "zoneHarbour" })
const _pieces: string = text.count("pieces", 3, 12)
const _food: string = text.data("food", "sugar_cube")
const _known: boolean = text.has("feed")
const _locale: LocaleBlox.Locale = text.locale()
const _id: string = text.localeId()
const _mirror: boolean = text.isRtl()

-- The names of the game's things, a table a locale, and a reader that resolves them.
const pets: LocaleBlox.NameTables = { ru = { Goldbun = "RU goldbun" } }
const named: LocaleBlox.Reader = LocaleBlox.Text.new({
	tables = tables,
	names = { pet = pets },
	localeId = "ru-ru",
	locale = "ru",
})
const _hatched: string = named.get("movedTo", { pet = "Goldbun" }, { key = "zoneHarbour" })
const _pet: string = named.name("pet", "Goldbun")
const _plain: string = LocaleBlox.Names.get(pets, "ru", "Goldbun")
const _coverage: number = #LocaleBlox.Names.coverage(pets, { "Goldbun" })
const _named: { [string]: { LocaleBlox.Locale } } = LocaleBlox.Names.keys(pets)

-- A server's sentence, its label on an instance, and the client's rewrite. On Roblox the codec is
-- HttpService's JSON pair and the collection is CollectionService.
const codec: LocaleBlox.Codec = {
	encode = function(_value: any): string
		return "{}"
	end,
	decode = function(_text: string): any
		return {}
	end,
}
const said: LocaleBlox.Sentences = LocaleBlox.Said.new(codec)
const args: { LocaleBlox.SaidArg } = { "Ann", { pet = "Goldbun" }, 3 }
const wire: string = said.encode("movedTo", args)
const _read: string = said.read(named, wire)
const _same: boolean = said.same("movedTo", args, "movedTo", said.copy(args))
const _saidKey: string?, _saidArgs: { any } = said.decode(wire)
const labelOptions: LocaleBlox.LabelOptions = { said = said, english = text, tag = "Localized", prefix = "Said_" }
const label: LocaleBlox.Labels = LocaleBlox.Label.new(labelOptions)
const _english: string = label.english("movedTo", args)
const sign = Instance.new("TextLabel")
label.set(sign, "Text", "movedTo", args)
label.plain(sign, "Text", "1,250")
const localizeOptions: LocaleBlox.LocalizeOptions = {
	said = said,
	text = named,
	collection = game:GetService("CollectionService"),
}
LocaleBlox.Localize.start(localizeOptions)

-- The pieces on their own.
const router: LocaleBlox.Router = LocaleBlox.Locale.router(tables)
const locale: LocaleBlox.Locale = LocaleBlox.Locale.localeFor("zh-tw")
const _word: string = router.get(locale, "feed")
const _keys: { string } = router.keys("en")
const _shipped: { LocaleBlox.Locale } = router.populated()
const _all: number = #LocaleBlox.Locale.ALL
const _rtl: boolean = LocaleBlox.Locale.isRtl("ar")
const _category: LocaleBlox.Category = LocaleBlox.Plural.category("ru", 21)
const _key: string = LocaleBlox.Keys.of("food", "sugar_cube", "hint")

-- The lint, for the game's own scripts and specs.
const parsed: LocaleBlox.Parsed = {}
LocaleBlox.Parse.source('local en = {\n\tfeed = "Feed",\n}', parsed, { zhHans = "zh-hans" })
const _specifiers: { string } = LocaleBlox.Parse.specifiers("%d / %d")
const sources: { LocaleBlox.Source } = { { path = "src/client/Hud.luau", text = 'text.get("feed")' } }
const problems: { string } = {}
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
