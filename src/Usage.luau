--!strict
--- Do the code and the English table name the same keys? Returns the problems found, sorted.
---
--- A key is a lowercase word followed by a capital ("feedButton", "foodSugarCube"). A string
--- literal of that shape — in double quotes, single quotes or a backtick string — whose first
--- word starts some English key must itself be a key, and every English key must appear in the
--- code as a literal. A comment is not code: a name written in one, in backticks or in quotes, is
--- neither judged nor counted as a use. Keys built at run time from game data
--- (`Keys.of("food", id)`) never appear whole: the game names their first words as `data`, and
--- those are left to the game's own spec, which walks its data.
local Usage = {}

export type Source = { path: string, text: string }
export type Options = {
	--- First words of keys that are built from game data, not written out.
	data: { string }?,
}

-- A key and the quote that closes it, by the quote that opened it: double, single, or the
-- backticks of a string without interpolation.
local KEYS: { [string]: string } = {
	['"'] = '^(%l+%u%w*)"',
	["'"] = "^(%l+%u%w*)'",
	["`"] = "^(%l+%u%w*)`",
}

local function firstWord(key: string): string
	return string.match(key, "^%l+") or ""
end

-- The last character of the long bracket that opens at `from` (`[[`, `[==[`), or nil when none
-- opens there. One that is never closed runs to the end of the text.
local function long(text: string, from: number): number?
	local level = string.match(text, "^%[(=*)%[", from)
	if level == nil then
		return nil
	end
	local _, close = string.find(text, `]{level}]`, from + #level + 2, true)
	return close or #text
end

-- What ends a quoted string, by the quote that opened it: that quote, or the end of the line. A
-- backslash is looked at too, since it takes the character after it. Only a backtick string runs
-- over a line end.
local ENDS: { [number]: string } = {
	[string.byte('"')] = '[\\"\n]',
	[string.byte("'")] = "[\\'\n]",
	[string.byte("`")] = "[\\`]",
}
local BACKSLASH = string.byte("\\")

-- The last character of the quoted string that opens at `from`.
local function quoted(text: string, from: number): number
	local ends = ENDS[string.byte(text, from)]
	local at = from + 1
	while true do
		local stop = string.find(text, ends, at)
		if stop == nil then
			return #text
		elseif string.byte(text, stop) ~= BACKSLASH then
			return stop
		end
		-- An escaped quote closes nothing.
		at = stop + 2
	end
end

-- Where `needle` next stands in `text` at or after `from`, as plain text; past any end when it
-- does not.
local function seek(text: string, needle: string, from: number): number
	return string.find(text, needle, from, true) or math.huge
end

-- `text` with every comment taken out: `--` to the end of its line, and a `--[[ ]]` or
-- `--[=[ ]=]` block. Strings are walked, so that a `--` inside one is kept as the text it is.
local function code(text: string): string
	local out: { string } = {}
	-- Where the kept text starts, where the walk is, and the next comment, quote of each kind and
	-- long bracket at or after it; each is looked for again only once the walk has passed it.
	local kept, at = 1, 1
	local dashes, double, single, tick, square, levelled = 0, 0, 0, 0, 0, 0
	while true do
		if dashes < at then
			dashes = seek(text, "--", at)
		end
		if dashes == math.huge then
			break
		end
		if double < at then
			double = seek(text, '"', at)
		end
		if single < at then
			single = seek(text, "'", at)
		end
		if tick < at then
			tick = seek(text, "`", at)
		end
		if square < at then
			square = seek(text, "[[", at)
		end
		if levelled < at then
			levelled = seek(text, "[=", at)
		end
		local quote = math.min(double, single, tick)
		local bracket = math.min(square, levelled)
		if dashes < quote and dashes < bracket then
			local line = string.find(text, "\n", dashes, true)
			local last = long(text, dashes + 2) or (if line ~= nil then line - 1 else #text)
			table.insert(out, string.sub(text, kept, dashes - 1))
			kept, at = last + 1, last + 1
		elseif bracket < quote then
			at = (long(text, bracket) or bracket) + 1
		else
			at = quoted(text, quote) + 1
		end
	end
	table.insert(out, string.sub(text, kept))
	return table.concat(out)
end

--> The key-shaped literals of `sources` that English lacks, and the English keys no source names.
function Usage.check(en: { [string]: string }, sources: { Source }, options: Options?): { string }
	local data: { string } = if options ~= nil and options.data ~= nil then options.data else {}
	local words: { [string]: boolean } = {}
	for key in en do
		words[firstWord(key)] = true
	end

	local out: { string } = {}
	local used: { [string]: boolean } = {}
	for _, source in sources do
		local text = code(source.text)
		for quote, key in KEYS do
			local at = 1
			while true do
				local open = string.find(text, quote, at, true)
				if open == nil then
					break
				end
				local _, close, literal = string.find(text, key, open + 1)
				at = (close or open) + 1
				if literal == nil then
					continue
				end
				local word = firstWord(literal)
				if en[literal] ~= nil then
					used[literal] = true
				elseif words[word] and table.find(data, word) == nil then
					table.insert(out, `{source.path}: "{literal}" looks like a text key, and English has none`)
				end
			end
		end
	end
	for key in en do
		if not used[key] and table.find(data, firstWord(key)) == nil then
			table.insert(out, `en.{key}: no code uses this key`)
		end
	end
	table.sort(out)
	return out
end

return table.freeze(Usage)
