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
const Parse = require("./Parse")

const Lint = {}

type Table = { [string]: string }
export type Locales = { [string]: Table }
export type Forms = { [string]: string }
export type Plurals = { [string]: { [string]: Forms } }

const FULLWIDTH_BANG, FULLWIDTH_QUERY = utf8.char(0xFF01), utf8.char(0xFF1F)
const COMBINING_ACUTE = utf8.char(0x301)

-- Glyphs that exist in one Chinese script only, by code point: the Simplified forms, and the
-- Traditional forms of the same words in the same order.
-- stylua: ignore
const SIMPLIFIED = {
	0x4EEC, 0x95E8, 0x5F00, 0x5173, 0x53D1, 0x65F6, 0x7535, 0x89C1, 0x8BF4, 0x8BED, 0x4E70, 0x5356,
	0x56FD, 0x5B66, 0x5B9E, 0x6218, 0x56FE, 0x56E2, 0x5458, 0x4E66, 0x8D39, 0x987A, 0x949F, 0x4E1C,
}
-- stylua: ignore
const TRADITIONAL = {
	0x5011, 0x9580, 0x958B, 0x95DC, 0x767C, 0x6642, 0x96FB, 0x898B, 0x8AAA, 0x8A9E, 0x8CB7, 0x8CE3,
	0x570B, 0x5B78, 0x5BE6, 0x6230, 0x5716, 0x5718, 0x54E1, 0x66F8, 0x8CBB, 0x9806, 0x9418, 0x6771,
}

const CATEGORIES: { [string]: boolean } = {
	zero = true,
	one = true,
	two = true,
	few = true,
	many = true,
	other = true,
}

const function contains(haystack: string, needle: string): boolean
	return string.find(haystack, needle, 1, true) ~= nil
end

const function sameSpecifiers(a: { string }, b: { string }): boolean
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
const function foreign(text: string, points: { number }): string?
	for _, point in points do
		if contains(text, utf8.char(point)) then
			return string.format("U+%04X", point)
		end
	end
	return nil
end

const function chinese(code: string, own: Table, bad: (string) -> ())
	const points = if code == "zh-hant" then SIMPLIFIED else TRADITIONAL
	const wrong = if code == "zh-hant" then "Simplified" else "Traditional"
	local full: string? = nil
	local half: string? = nil
	const keys: { string } = {}
	for key in own do
		table.insert(keys, key)
	end
	table.sort(keys)
	for _, key in keys do
		const value = own[key]
		const glyph = foreign(value, points)
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

--> The disagreements between every locale of `locales` and its English table.
function Lint.tables(locales: Locales): { string }
	const out: { string } = {}
	const function bad(message: string)
		table.insert(out, message)
	end

	const en = locales.en
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
			const value = own[key]
			if value == nil then
				bad(`{code}: missing key "{key}"`)
			elseif not sameSpecifiers(Parse.specifiers(source), Parse.specifiers(value)) then
				const theirs = table.concat(Parse.specifiers(value), ",")
				const ours = table.concat(Parse.specifiers(source), ",")
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
	const out: { string } = {}
	for code, byKey in plurals do
		for key, forms in byKey do
			const source = en[key]
			if source == nil then
				table.insert(out, `{code}.{key}: counted key is not in English`)
				continue
			end
			const wanted = Parse.specifiers(source)
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

return Lint
