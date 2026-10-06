--!strict
--- Which table a player reads, and the lookup that never renders nothing.
---
--- A Roblox `LocaleId` is a BCP-47 tag ("pt-br", "fil-ph", "zh-hant"). `localeFor` resolves it to
--- one of twenty-five locales; `router` binds a game's tables to a lookup that falls back from the
--- locale to English to the key itself.
const Locale = {}

export type Locale =
	"ru"
	| "en"
	| "pt"
	| "es"
	| "id"
	| "de"
	| "fr"
	| "fil"
	| "hi"
	| "vi"
	| "th"
	| "ms"
	| "ja"
	| "ko"
	| "zh-hant"
	| "tr"
	| "pl"
	| "ar"
	| "it"
	| "nl"
	| "uk"
	| "zh-hans"
	| "es-ES"
	| "pt-PT"
	| "fr-CA"

export type Table = { [string]: string }
export type Tables = { [Locale]: Table }

export type Router = {
	--- Resolves a Roblox LocaleId to a locale; empty or unknown reads English.
	localeFor: (localeId: string) -> Locale,
	--- The string for a key: the locale's, else English's, else the key itself.
	get: (locale: Locale, key: string) -> string,
	--- The sorted keys of one locale's table; empty when the game ships none for it.
	keys: (locale: Locale) -> { string },
	--- The locales the game ships a table for, sorted.
	populated: () -> { Locale },
}

--- Every locale, in a fixed order.
Locale.ALL = table.freeze({
	"en",
	"ru",
	"pt",
	"es",
	"id",
	"de",
	"fr",
	"fil",
	"hi",
	"vi",
	"th",
	"ms",
	"ja",
	"ko",
	"zh-hant",
	"tr",
	"pl",
	"ar",
	"it",
	"nl",
	"uk",
	"zh-hans",
	"es-ES",
	"pt-PT",
	"fr-CA",
} :: { Locale })

-- Language subtag to locale. Belarusian and Kazakh read Russian (those markets play in Russian),
-- Ukrainian has its own table, Tagalog reads Filipino. Chinese and the three regional splits are
-- decided in `localeFor`.
const LANGUAGE: { [string]: Locale } = {
	ru = "ru",
	be = "ru",
	kk = "ru",
	uk = "uk",
	id = "id",
	de = "de",
	it = "it",
	nl = "nl",
	pl = "pl",
	tr = "tr",
	fil = "fil",
	tl = "fil",
	ms = "ms",
	hi = "hi",
	vi = "vi",
	th = "th",
	ja = "ja",
	ko = "ko",
	ar = "ar",
}

-- The script tag and the regions written in Traditional Chinese. Every other Chinese tag, a bare
-- "zh" among them, reads Simplified.
const TRADITIONAL: { [string]: boolean } = { hant = true, tw = true, hk = true, mo = true }

-- The locales written right to left.
const RTL: { [string]: boolean } = { ar = true }

--> The locale a Roblox LocaleId reads. Case and the separator ("-" or "_") do not matter.
function Locale.localeFor(localeId: string): Locale
	const lower = string.lower(localeId)
	const language = string.match(lower, "^%a+") or ""
	if language == "zh" then
		const subtag = string.match(lower, "^zh[-_](%a+)")
		return if subtag ~= nil and TRADITIONAL[subtag] then "zh-hant" else "zh-hans"
	elseif language == "es" then
		return if string.match(lower, "^es[-_]es") then "es-ES" else "es"
	elseif language == "pt" then
		return if string.match(lower, "^pt[-_]pt") then "pt-PT" else "pt"
	elseif language == "fr" then
		return if string.match(lower, "^fr[-_]ca") then "fr-CA" else "fr"
	end
	return LANGUAGE[language] or "en"
end

--> Whether a locale is written right to left.
function Locale.isRtl(locale: string): boolean
	return RTL[locale] == true
end

--> Binds the lookups to one game's tables. The game must ship an English table.
function Locale.router(tables: Tables): Router
	const english: Locale = "en"
	const en = tables[english]
	assert(en ~= nil, "LocaleBlox: the tables hold no English table")

	return {
		localeFor = Locale.localeFor,

		get = function(locale: Locale, key: string): string
			const own = tables[locale] or en
			return own[key] or en[key] or key
		end,

		keys = function(locale: Locale): { string }
			const out: { string } = {}
			const own = tables[locale]
			if own ~= nil then
				for key in own do
					table.insert(out, key)
				end
			end
			table.sort(out)
			return out
		end,

		populated = function(): { Locale }
			const out: { Locale } = {}
			for locale in tables do
				table.insert(out, locale)
			end
			table.sort(out)
			return out
		end,
	}
end

return Locale
