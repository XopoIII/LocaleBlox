--!strict
--- One reader for every word a client draws, bound to a game's tables and a player's locale.
---
---     const text = Text.new({ tables = Tables, plurals = Plurals, localeId = player.LocaleId })
---     text.get("feed")                          --> "Feed"
---     text.get("movedTo", { key = "worldGarden" })
---     text.count("piecesCarried", 3, 12)        -- the noun agrees with 3
---
--- The locale id is an argument: nothing here reads a player, a service or an attribute. Amounts
--- arrive already written as strings and ride `%s`.
const Keys = require("./Keys")
const Locale = require("./Locale")
const Plural = require("./Plural")

const Text = {}

export type Forms = { [string]: string }
export type Plurals = { [string]: { [string]: Forms } }

export type Options = {
	--- The game's tables by locale; English is required.
	tables: Locale.Tables,
	--- The player's Roblox LocaleId, or any BCP-47 tag.
	localeId: string,
	--- Counted forms by locale, key and CLDR category. A key absent here uses its flat string.
	plurals: Plurals?,
}

export type Reader = {
	--- The string for a key, formatted when arguments follow. An argument `{ key = "..." }` is
	--- looked up first, so a translated sentence never gets an English word in a slot.
	get: (key: string, ...any) -> string,
	--- A sentence whose noun agrees with `n`; `n` is the first format argument.
	count: (key: string, n: number, ...any) -> string,
	--- The text of a piece of game data (`Keys.of`).
	data: (kind: string, name: string, field: string?) -> string,
	--- Whether a key has text in this locale or in English.
	has: (key: string) -> boolean,
	locale: () -> Locale.Locale,
	localeId: () -> string,
	isRtl: () -> boolean,
}

--> A reader over `options.tables` for the locale `options.localeId` resolves to.
function Text.new(options: Options): Reader
	const router = Locale.router(options.tables)
	const localeId = options.localeId
	const locale = Locale.localeFor(localeId)
	const plurals: Plurals = options.plurals or {}
	const english: Locale.Locale = "en"

	-- Arguments that are keys become words of this locale.
	const function resolve(args: { any }, count: number)
		for index = 1, count do
			const arg = args[index]
			if type(arg) == "table" and type(arg.key) == "string" then
				args[index] = router.get(locale, arg.key)
			end
		end
	end

	const function get(key: string, ...: any): string
		const template = router.get(locale, key)
		const count = select("#", ...)
		if count == 0 then
			return template
		end
		const args = table.pack(...)
		resolve(args, count)
		return string.format(template, table.unpack(args, 1, count))
	end

	-- The forms of a key: this locale's, else English's, so an untranslated count still agrees.
	const function forms(key: string): (Forms?, string)
		const own = plurals[locale]
		if own ~= nil and own[key] ~= nil then
			return own[key], locale
		end
		const fallback = plurals[english]
		if fallback ~= nil and fallback[key] ~= nil and options.tables[locale] == nil then
			return fallback[key], english
		end
		return nil, locale
	end

	const function count(key: string, n: number, ...: any): string
		const extra = select("#", ...)
		const args = table.pack(...)
		resolve(args, extra)
		local template: string? = nil
		const found, ruled = forms(key)
		if found ~= nil then
			template = found[Plural.category(ruled, n)] or found.other or found.many or found.one
		end
		return string.format(template or router.get(locale, key), n, table.unpack(args, 1, extra))
	end

	return {
		get = get,
		count = count,
		data = function(kind: string, name: string, field: string?): string
			return get(Keys.of(kind, name, field))
		end,
		has = function(key: string): boolean
			return router.get(locale, key) ~= key
		end,
		locale = function(): Locale.Locale
			return locale
		end,
		localeId = function(): string
			return localeId
		end,
		isRtl = function(): boolean
			return Locale.isRtl(locale)
		end,
	}
end

return Text
