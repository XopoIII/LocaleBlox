--!strict
--- The mutants of src/Written.luau: each a small slip in a rule, and the rule it breaks.
local Mutant = require("./Mutant")

local MUTANTS: { Mutant.Mutant } = {
	{
		file = "src/Written.luau",
		from = 'if encoding(where, text, bad) and code ~= "en" then',
		to = "if encoding(where, text, bad) then",
		breaks = "English is checked for encoding only",
	},
	{
		file = "src/Written.luau",
		from = "\t\tif not has then\n",
		to = "\t\tif false then\n",
		breaks = "a string left in another script is found",
	},
	{
		file = "src/Written.luau",
		from = '\t\t\tif name ~= "latin" then',
		to = "\t\t\tif false then",
		breaks = "another script in a Latin-script table is found",
	},
	{
		file = "src/Written.luau",
		from = 'if found[1] ~= "arabic" then',
		to = "if false then",
		breaks = "Arabic starts with an Arabic letter",
	},
	{
		file = "src/Written.luau",
		from = '\t\tif table.find(found, "latin") ~= nil then',
		to = "\t\tif false then",
		breaks = "Arabic holds no Latin word",
	},
	{
		file = "src/Written.luau",
		from = '\tfor _, pattern in keep do\n\t\trest = string.gsub(rest, pattern, "")\n\tend\n',
		to = "",
		breaks = "a game names the Latin it keeps",
	},
	{
		file = "src/Written.luau",
		from = '"x" .. Parse.SPECIFIER, "x%d+", ',
		to = "",
		breaks = "a multiplier is kept in every language",
	},
	{
		file = "src/Written.luau",
		from = '"x%d+", Parse.SPECIFIER, "R%$"',
		to = '"x%d+", "%%[-+ #0-9%.]*%a", "R%$"',
		breaks = "a specifier is the one the lint reads, not any letter after a percent",
	},
	{
		file = "src/Written.luau",
		from = '"x" .. Parse.SPECIFIER, "x%d+"',
		to = '"x%%[-+ #0-9%.]*%a", "x%d+"',
		breaks = "a multiplier takes any specifier the lint reads",
	},
	{
		file = "src/Written.luau",
		from = ', "R%$", "Robux", "Roblox" }',
		to = " }",
		breaks = "Robux and Roblox are kept in every language",
	},
	{
		file = "src/Written.luau",
		from = "\t\tif point == 0xFFFD then",
		to = "\t\tif false then",
		breaks = "a lost glyph is found",
	},
	{
		file = "src/Written.luau",
		from = "elseif point < 0x20 then",
		to = "elseif point < 0x09 then",
		breaks = "a control character is found",
	},
	{
		file = "src/Written.luau",
		from = "elseif point >= 0x300 and point <= 0x36F then",
		to = "elseif point > 0x301 and point <= 0x36F then",
		breaks = "a combining accent is found",
	},
	{
		file = "src/Written.luau",
		from = "\tif utf8.len(text) == nil then\n\t\tbad(`{where}: not valid UTF-8`)\n\t\treturn false\n\tend\n",
		to = "\tif utf8.len(text) == nil then\n\t\treturn false\n\tend\n",
		breaks = "broken UTF-8 is reported",
	},
	{
		file = "src/Written.luau",
		from = '\tja = { "kana", "han" },',
		to = '\tja = { "kana" },',
		breaks = "kanji alone is Japanese",
	},
	{
		file = "src/Written.luau",
		from = "\ttable.sort(out)\n\treturn out\nend\n\nreturn table.freeze(Written)",
		to = "\treturn out\nend\n\nreturn table.freeze(Written)",
		breaks = "the problems come sorted",
	},
}

return MUTANTS
