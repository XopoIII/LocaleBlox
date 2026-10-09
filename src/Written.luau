--!strict
--- Is every string whole, and written in its own script? Returns the problems found, sorted.
---
--- - encoding: valid UTF-8, no U+FFFD, no control character, no combining accent;
--- - script: Russian and Ukrainian are Cyrillic, Arabic Arabic, Hindi Devanagari, Thai Thai,
---   Japanese kana or kanji, Korean Hangul, Chinese Han, and a Latin-script table carries no other
---   script, so an untranslated or cross-pasted string shows up;
--- - right to left: an Arabic string starts with an Arabic letter and holds no Latin word.
---
--- Latin kept on purpose in every language is named by the game as `keep` patterns; format
--- specifiers, multipliers ("x2"), "R$", "Robux" and "Roblox" are always kept.
local Written = {}

type Range = { number }
export type Locales = { [string]: { [string]: string } }
export type Options = {
	--- Lua patterns for Latin text a translation may keep (a brand, a key cap).
	keep: { string }?,
}

local SCRIPTS: { [string]: { Range } } = {
	latin = { { 0x41, 0x5A }, { 0x61, 0x7A }, { 0xC0, 0x24F }, { 0x1E00, 0x1EFF } },
	cyrillic = { { 0x400, 0x4FF } },
	arabic = { { 0x600, 0x6FF }, { 0x750, 0x77F }, { 0xFB50, 0xFDFF }, { 0xFE70, 0xFEFF } },
	devanagari = { { 0x900, 0x97F } },
	thai = { { 0xE00, 0xE7F } },
	hangul = { { 0xAC00, 0xD7AF }, { 0x1100, 0x11FF }, { 0x3130, 0x318F } },
	kana = { { 0x3040, 0x30FF } },
	han = { { 0x4E00, 0x9FFF }, { 0x3400, 0x4DBF }, { 0xF900, 0xFAFF } },
}

-- The scripts a locale must be written in; an unlisted locale is Latin.
local NATIVE: { [string]: { string } } = {
	ru = { "cyrillic" },
	uk = { "cyrillic" },
	ar = { "arabic" },
	hi = { "devanagari" },
	th = { "thai" },
	ja = { "kana", "han" },
	ko = { "hangul" },
	["zh-hant"] = { "han" },
	["zh-hans"] = { "han" },
}

-- Multipliers go first, so "x%s" is taken whole before its specifier is.
local ALWAYS_KEPT = { "x%%[-+ #0-9%.]*%a", "x%d+", "%%[-+ #0-9%.]*%a", "R%$", "Robux", "Roblox" }

local function scriptOf(point: number): string?
	for name, ranges in SCRIPTS do
		for _, range in ranges do
			if point >= range[1] and point <= range[2] then
				return name
			end
		end
	end
	return nil
end

-- The scripts of the letters of `text`, in order, once the kept patterns are taken out.
local function letters(text: string, keep: { string }): { string }
	local rest = text
	for _, pattern in keep do
		rest = string.gsub(rest, pattern, "")
	end
	for _, pattern in ALWAYS_KEPT do
		rest = string.gsub(rest, pattern, "")
	end
	local out: { string } = {}
	for _, point in utf8.codes(rest) do
		local name = scriptOf(point)
		if name ~= nil then
			table.insert(out, name)
		end
	end
	return out
end

local function encoding(where: string, text: string, bad: (string) -> ()): boolean
	if utf8.len(text) == nil then
		bad(`{where}: not valid UTF-8`)
		return false
	end
	for _, point in utf8.codes(text) do
		if point == 0xFFFD then
			bad(`{where}: U+FFFD, a glyph was lost on the way in`)
		elseif point < 0x20 then
			bad(`{where}: control character U+{string.format("%04X", point)}`)
		elseif point >= 0x300 and point <= 0x36F then
			bad(`{where}: combining accent U+{string.format("%04X", point)}, write the precomposed letter`)
		end
	end
	return true
end

local function script(code: string, where: string, text: string, keep: { string }, bad: (string) -> ())
	local found = letters(text, keep)
	if #found == 0 then
		return
	end
	local native = NATIVE[code]
	if native ~= nil then
		local has = false
		for _, name in found do
			if table.find(native, name) ~= nil then
				has = true
				break
			end
		end
		if not has then
			bad(`{where}: no {table.concat(native, "/")} letter (untranslated?)`)
		end
	else
		for _, name in found do
			if name ~= "latin" then
				bad(`{where}: {name} letters in a Latin-script table`)
				break
			end
		end
	end
	if code == "ar" then
		if found[1] ~= "arabic" then
			bad(`{where}: does not start with an Arabic letter, it would read left to right`)
		end
		if table.find(found, "latin") ~= nil then
			bad(`{where}: Latin words inside right-to-left text`)
		end
	end
end

--> The problems of one string of locale `code`, named `where` in each line.
function Written.one(code: string, where: string, text: string, options: Options?): { string }
	local out: { string } = {}
	local function bad(message: string)
		table.insert(out, message)
	end
	if encoding(where, text, bad) and code ~= "en" then
		script(code, where, text, if options ~= nil and options.keep ~= nil then options.keep else {}, bad)
	end
	return out
end

--> The problems of every string of every locale. The tables are keyed by locale code: a game's
--> own `Tables`, or what `Parse.source` read.
function Written.check<Code>(locales: { [Code]: { [string]: string } }, options: Options?): { string }
	local out: { string } = {}
	for given, own in locales do
		local code = tostring(given)
		for key, value in own do
			for _, problem in Written.one(code, `{code}.{key}`, value, options) do
				table.insert(out, problem)
			end
		end
	end
	table.sort(out)
	return out
end

return table.freeze(Written)
