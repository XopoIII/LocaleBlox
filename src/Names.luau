--!strict
--- The display names of a game's things: creatures, items, places.
---
--- A name is not a text key. The thing's own id is what the game saves, matches and logs, and it
--- never changes; only what is drawn goes through here. Each locale has one table, keyed by the id,
--- so a new thing lands with a line in every table and nothing else moves.
---
---     const NAMES: Names.Tables = { ru = require(names.ru), ja = require(names.ja) }
---     Names.get(NAMES, "ru", "Goldbun")   --> the Russian name
---     Names.get(NAMES, "en", "Goldbun")   --> "Goldbun": no table, so the id itself
---
--- A locale with no table, and an id its table lacks or leaves empty, show the id. A game whose ids
--- are its English names therefore ships no English table.
const Locale = require("./Locale")

const Names = {}

--> One locale's names by id.
export type Table = { [string]: string }
--> A kind's names by locale.
export type Tables = { [Locale.Locale]: Table }

export type Coverage = {
	locale: Locale.Locale,
	--> How many of the ids asked about this locale names.
	have: number,
	--> How many ids were asked about.
	total: number,
}

--> The name to draw for `id` in `locale`: the table's own, or the id.
function Names.get(tables: Tables, locale: Locale.Locale, id: string): string
	const own = tables[locale]
	const name = if own ~= nil then own[id] else nil
	if name ~= nil and name ~= "" then
		return name
	end
	return id
end

--> How many of `ids` each locale names, fullest first, ties by locale code.
function Names.coverage(tables: Tables, ids: { string }): { Coverage }
	const out: { Coverage } = {}
	for locale, own in tables do
		local have = 0
		for _, id in ids do
			const name = own[id]
			if name ~= nil and name ~= "" then
				have += 1
			end
		end
		table.insert(out, { locale = locale, have = have, total = #ids })
	end
	table.sort(out, function(a: Coverage, b: Coverage): boolean
		if a.have == b.have then
			return a.locale < b.locale
		end
		return a.have > b.have
	end)
	return out
end

--> Every id any table names, with the locales that name it, in order. An id that matches nothing
--> of the game is a translation nobody will ever see.
function Names.keys(tables: Tables): { [string]: { Locale.Locale } }
	const out: { [string]: { Locale.Locale } } = {}
	for locale, own in tables do
		for id in own do
			local seen = out[id]
			if seen == nil then
				seen = {}
				out[id] = seen
			end
			table.insert(seen, locale)
		end
	end
	for _, locales in out do
		table.sort(locales)
	end
	return out
end

return Names
