--!strict
--- The mutants of src/Usage.luau: each a small slip in a rule, and the rule it breaks.
local Mutant = require("./Mutant")

local MUTANTS: { Mutant.Mutant } = {
	{
		file = "src/Usage.luau",
		from = "elseif words[word] and table.find(data, word) == nil then",
		to = "elseif words[word] then",
		breaks = "a literal of a data kind is not judged",
	},
	{
		file = "src/Usage.luau",
		from = "elseif words[word] and",
		to = "elseif",
		breaks = "only a literal that starts like a key is judged",
	},
	{
		file = "src/Usage.luau",
		from = "if not used[key] and table.find(data, firstWord(key)) == nil then",
		to = "if not used[key] then",
		breaks = "keys built from game data are left to the game",
	},
	{
		file = "src/Usage.luau",
		from = "\t\t\t\tused[literal] = true\n",
		to = "",
		breaks = "a key the code names is used",
	},
	{
		file = "src/Usage.luau",
		from = [[	["'"] = "^(%l+%u%w*)'",
]],
		to = "",
		breaks = "a key may stand in single quotes",
	},
	{
		file = "src/Usage.luau",
		from = [[	['"'] = '^(%l+%u%w*)"',
]],
		to = "",
		breaks = "a key may stand in double quotes",
	},
	{
		file = "src/Usage.luau",
		from = [[["'"] = "^(%l+%u%w*)'",]],
		to = [[["'"] = "^(%l+%u%w*)['`]",]],
		breaks = "a literal closes with the quote that opened it",
	},
	{
		file = "src/Usage.luau",
		from = "local text = code(source.text)",
		to = "local text = source.text",
		breaks = "a comment is not code",
	},
	{
		file = "src/Usage.luau",
		from = "local last = long(text, dashes + 2) or (if line ~= nil then line - 1 else #text)",
		to = "local last = if line ~= nil then line - 1 else #text",
		breaks = "a block comment runs to its own closing bracket",
	},
	{
		file = "src/Usage.luau",
		from = "local _, close = string.find(text, `]{level}]`, from + #level + 2, true)",
		to = 'local _, close = string.find(text, "]]", from + #level + 2, true)',
		breaks = "a levelled block closes at its own level",
	},
	{
		file = "src/Usage.luau",
		from = "at = quoted(text, quote) + 1",
		to = "at = quote + 1",
		breaks = "two dashes inside a quoted string open no comment",
	},
	{
		file = "src/Usage.luau",
		from = "at = (long(text, bracket) or bracket) + 1",
		to = "at = bracket + 1",
		breaks = "two dashes inside a long string open no comment",
	},
	{
		file = "src/Usage.luau",
		from = "\t\tat = stop + 2\n",
		to = "\t\tat = stop + 1\n",
		breaks = "an escaped quote closes no string",
	},
	{
		file = "src/Usage.luau",
		from = [=[[string.byte("`")] = "[\\`]",]=],
		to = [=[[string.byte("`")] = "[\\`\n]",]=],
		breaks = "a backtick string runs over a line end",
	},
	{
		file = "src/Usage.luau",
		from = [=[[string.byte("'")] = "[\\'\n]",]=],
		to = [=[[string.byte("'")] = "[\\']",]=],
		breaks = "an unclosed quote ends with its line",
	},
	{
		file = "src/Usage.luau",
		from = [=[[string.byte('"')] = '[\\"\n]',]=],
		to = [=[[string.byte('"')] = '[\\"]',]=],
		breaks = "an unclosed double quote ends with its line",
	},
	{
		file = "src/Usage.luau",
		from = [[	["`"] = "^(%l+%u%w*)`",
]],
		to = "",
		breaks = "a key may stand in a backtick string",
	},
}

return MUTANTS
