--!strict
--- Do a game's tables agree with each other? Every function returns the problems it found, sorted,
--- as lines a person can act on; an empty list is a clean result.
---
--- - keys: every English key is in every locale, and no locale holds a key English lacks;
--- - placeholders: a translation has English's `string.format` specifiers, in number and order
---   (a mismatch hands `string.format` the wrong argument and errors on the client);
--- - no empty string, no combining acute accent;
--- - Chinese: no Simplified glyph in the Traditional table and the reverse, and one width of
---   "!" and "?" per table.
---
--- It does not judge whether a translation reads well.
local Parse = require("./Parse")

local Lint = {}

type Table = { [string]: string }
export type Locales = { [string]: Table }
export type Forms = { [string]: string }
export type Plurals = { [string]: { [string]: Forms } }

local FULLWIDTH_BANG, FULLWIDTH_QUERY = utf8.char(0xFF01), utf8.char(0xFF1F)
local COMBINING_ACUTE = utf8.char(0x301)

-- Glyphs that exist in one Chinese script only, by code point: the Simplified forms, and the
-- Traditional forms of the same words in the same order.
-- stylua: ignore
local SIMPLIFIED = {
	0x4EEC, 0x95E8, 0x5F00, 0x5173, 0x53D1, 0x65F6, 0x7535, 0x89C1, 0x8BF4, 0x8BED, 0x4E70, 0x5356,
	0x56FD, 0x5B66, 0x5B9E, 0x6218, 0x56FE, 0x56E2, 0x5458, 0x4E66, 0x8D39, 0x987A, 0x949F, 0x4E1C,
}
-- stylua: ignore
local TRADITIONAL = {
	0x5011, 0x9580, 0x958B, 0x95DC, 0x767C, 0x6642, 0x96FB, 0x898B, 0x8AAA, 0x8A9E, 0x8CB7, 0x8CE3,
	0x570B, 0x5B78, 0x5BE6, 0x6230, 0x5716, 0x5718, 0x54E1, 0x66F8, 0x8CBB, 0x9806, 0x9418, 0x6771,
}

local CATEGORIES: { [string]: boolean } = {
	zero = true,
	one = true,
	two = true,
	few = true,
	many = true,
	other = true,
}

local function contains(haystack: string, needle: string): boolean
	return string.find(haystack, needle, 1, true) ~= nil
end

local function sameSpecifiers(a: { string }, b: { string }): boolean
	if #a ~= #b then
		return false
	end
	for index = 1, #a do
		if a[index] ~= b[index] then
			return false
		end
	end
	return true
end

-- The first glyph of `points` found in `text`, as a "U+XXXX" label.
local function foreign(text: string, points: { number }): string?
	for _, point in points do
		if contains(text, utf8.char(point)) then
			return string.format("U+%04X", point)
		end
	end
	return nil
end

local function chinese(code: string, own: Table, bad: (string) -> ())
	local points = if code == "zh-hant" then SIMPLIFIED else TRADITIONAL
	local wrong = if code == "zh-hant" then "Simplified" else "Traditional"
	local full: string? = nil
	local half: string? = nil
	local keys: { string } = {}
	for key in own do
		table.insert(keys, key)
	end
	table.sort(keys)
	for _, key in keys do
		local value = own[key]
		local glyph = foreign(value, points)
		if glyph ~= nil then
			bad(`{code}.{key}: {wrong} glyph {glyph} in this table`)
		end
		if full == nil and (contains(value, FULLWIDTH_BANG) or contains(value, FULLWIDTH_QUERY)) then
			full = key
		end
		if half == nil and (contains(value, "!") or contains(value, "?")) then
			half = key
		end
	end
	if full ~= nil and half ~= nil then
		bad(`{code}: mixes full-width (as in {full}) and half-width (as in {half}) "!" and "?"`)
	end
end

--> The disagreements between every locale and the English table. The tables are keyed by locale
--> code: a game's own `Tables`, or what `Parse.source` read.
function Lint.tables<Code>(given: { [Code]: Table }): { string }
	local locales: Locales = {}
	for code, own in given do
		locales[tostring(code)] = own
	end
	local out: { string } = {}
	local function bad(message: string)
		table.insert(out, message)
	end

	local en = locales.en
	if en == nil then
		return { "en: there is no English table" }
	end
	for key, value in en do
		if value == "" then
			bad(`en.{key}: empty string`)
		end
	end

	for code, own in locales do
		if code == "en" then
			continue
		end
		for key, source in en do
			local value = own[key]
			if value == nil then
				bad(`{code}: missing key "{key}"`)
			elseif not sameSpecifiers(Parse.specifiers(source), Parse.specifiers(value)) then
				local theirs = table.concat(Parse.specifiers(value), ",")
				local ours = table.concat(Parse.specifiers(source), ",")
				bad(`{code}.{key}: placeholders [{theirs}] are not English's [{ours}]`)
			end
		end
		for key, value in own do
			if en[key] == nil then
				bad(`{code}: key "{key}" is not in English`)
			end
			if value == "" then
				bad(`{code}.{key}: empty string`)
			end
			if contains(value, COMBINING_ACUTE) then
				bad(`{code}.{key}: combining acute accent U+0301`)
			end
		end
		if code == "zh-hant" or code == "zh-hans" then
			chinese(code, own, bad)
		end
	end

	table.sort(out)
	return out
end

--> The faults of a plural overlay against the English table: a counted key English lacks, a
--> category that is not CLDR's, a form whose placeholders are not English's, an empty form, and a
--> set of forms without "other" or "many" to fall back on.
function Lint.plurals(en: Table, plurals: Plurals): { string }
	local out: { string } = {}
	for code, byKey in plurals do
		for key, forms in byKey do
			local source = en[key]
			if source == nil then
				table.insert(out, `{code}.{key}: counted key is not in English`)
				continue
			end
			local wanted = Parse.specifiers(source)
			for category, form in forms do
				if not CATEGORIES[category] then
					table.insert(out, `{code}.{key}.{category}: not a plural category`)
				end
				if form == "" then
					table.insert(out, `{code}.{key}.{category}: empty string`)
				elseif not sameSpecifiers(wanted, Parse.specifiers(form)) then
					table.insert(out, `{code}.{key}.{category}: placeholders are not English's`)
				end
			end
			if forms.other == nil and forms.many == nil then
				table.insert(out, `{code}.{key}: no "other" or "many" form to fall back on`)
			end
		end
	end
	table.sort(out)
	return out
end

--> The faults of a kind's name tables: a locale with no table, an id a table does not name (it
--> would show the id), two ids one name in one locale, a name that is a UI word of its locale, and
--> a table entry that is no id of the game.
-->
--> `names` is the kind's names by locale code and id (`Names.Tables`, or what `Parse.source` read),
--> `ids` every id the game has of that kind, and `ui` the game's text tables by locale code: a name
--> that is also a word of the UI in its own locale reads as that word, not as a name. `locales`
--> lists the locale codes that must each have a table (absent: only the tables given are looked
--> at), and `where` is what a problem is said to be in ("names" by default).
function Lint.names<Code, UiCode>(
	given: { [Code]: Table },
	ids: { string },
	words: { [UiCode]: Table }?,
	locales: { string }?,
	where: string?
): { string }
	local place = where or "names"
	local asked: { string } = locales or {}
	local names: Locales = {}
	for code, own in given do
		names[tostring(code)] = own
	end
	local ui: Locales = {}
	if words ~= nil then
		for code, own in words do
			ui[tostring(code)] = own
		end
	end
	local known: { [string]: boolean } = {}
	for _, id in ids do
		known[id] = true
	end

	local out: { string } = {}
	for _, code in asked do
		if names[code] == nil then
			table.insert(out, `{place}/{code}: no table`)
		end
	end
	for code, own in names do
		local taken: { [string]: string } = {}
		local uiWords: { [string]: string } = {}
		local ownWords = ui[code]
		if ownWords ~= nil then
			for key, value in ownWords do
				uiWords[string.lower(value)] = key
			end
		end
		for _, id in ids do
			local name = own[id]
			if name == nil or name == "" then
				table.insert(out, `{place}/{code}.{id}: missing (it would show its id)`)
				continue
			end
			if taken[name] ~= nil then
				table.insert(out, `{place}/{code}.{id}: "{name}" is also {taken[name]}'s name`)
			end
			taken[name] = id
			local word = uiWords[string.lower(name)]
			if word ~= nil then
				table.insert(out, `{place}/{code}.{id}: "{name}" is the same word as {code}.{word}`)
			end
		end
		for id in own do
			if not known[id] then
				table.insert(out, `{place}/{code}.{id}: no such id`)
			end
		end
	end
	table.sort(out)
	return out
end

return table.freeze(Lint)
