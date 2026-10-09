--!strict
--- The mutants of src/Parse.luau: each a small slip in a rule, and the rule it breaks.
local Mutant = require("./Mutant")

local MUTANTS: { Mutant.Mutant } = {
	{
		file = "src/Parse.luau",
		from = "local code = if aliases ~= nil and aliases[name] ~= nil then aliases[name] else name",
		to = "local code = name",
		breaks = "an alias renames a table to its locale code",
	},
	{
		file = "src/Parse.luau",
		from = '\t\tif string.match(line, "^}") then\n\t\t\tcurrent = nil\n\t\t\tcontinue\n\t\tend\n',
		to = "",
		breaks = "a line outside any table is not read into the last one",
	},
	{
		file = "src/Parse.luau",
		from = 'local clean = string.gsub(text, "%%%%", "")',
		to = "local clean = text",
		breaks = "an escaped percent is not a specifier",
	},
	{
		file = "src/Parse.luau",
		from = 'for specifier in string.gmatch(clean, "%%[-+ #0-9%.]*[cdeEfgGiopqsuxX]") do',
		to = 'for specifier in string.gmatch(clean, "%%[-+ #0-9%.]*%a") do',
		breaks = "a lone percent of plain text is not a specifier",
	},
	{
		file = "src/Parse.luau",
		from = 'local TYPED = "^%s+([%w_]+)%s*:[^=]-=%s*{%s*$"',
		to = 'local TYPED = "^%s+([%w_]+)%s*:[%w_%.]-=%s*{%s*$"',
		breaks = "a table's type may be any type written on its opening line",
	},
	{
		file = "src/Parse.luau",
		from = 'local TYPED = "^%s+([%w_]+)%s*:[^=]-=%s*{%s*$"',
		to = 'local TYPED = "^%s+([%w_]+)%s*:.-=%s*{%s*$"',
		breaks = "a comparison is not a declaration",
	},
	{
		file = "src/Parse.luau",
		from = "return string.match(rest, BARE) or string.match(rest, TYPED)",
		to = "return string.match(rest, TYPED)",
		breaks = "a table with no type is read",
	},
}

return MUTANTS
