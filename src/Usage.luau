--!strict
--- Do the code and the English table name the same keys? Returns the problems found, sorted.
---
--- A key is a lowercase word followed by a capital ("feedButton", "foodSugarCube"). A string
--- literal of that shape — in double quotes, single quotes or a backtick string — whose first
--- word starts some English key must itself be a key, and every English key must appear in the
--- code as a literal. Keys built at run time from game data
--- (`Keys.of("food", id)`) never appear whole: the game names their first words as `data`, and
--- those are left to the game's own spec, which walks its data.
local Usage = {}

export type Source = { path: string, text: string }
export type Options = {
	--- First words of keys that are built from game data, not written out.
	data: { string }?,
}

local function firstWord(key: string): string
	return string.match(key, "^%l+") or ""
end

--> The key-shaped literals of `sources` that English lacks, and the English keys no source names.
function Usage.check(en: { [string]: string }, sources: { Source }, options: Options?): { string }
	local data: { string } = if options ~= nil and options.data ~= nil then options.data else {}
	local words: { [string]: boolean } = {}
	for key in en do
		words[firstWord(key)] = true
	end

	-- A key may stand in double quotes, single quotes or a backtick string without interpolation.
	local QUOTES = { '"(%l+%u[%w]*)"', "'(%l+%u[%w]*)'", "`(%l+%u[%w]*)`" }

	local out: { string } = {}
	local used: { [string]: boolean } = {}
	for _, source in sources do
		for _, quote in QUOTES do
			for literal in string.gmatch(source.text, quote) do
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
