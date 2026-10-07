--!strict
--- The mutants of src/Parse.luau: each a small slip in a rule, and the rule it breaks.
const Mutant = require("./Mutant")

const MUTANTS: { Mutant.Mutant } = {
	{
		file = "src/Parse.luau",
		from = "const code = if aliases ~= nil and aliases[name] ~= nil then aliases[name] else name",
		to = "const code = name",
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
		from = 'const clean = string.gsub(text, "%%%%", "")',
		to = "const clean = text",
		breaks = "an escaped percent is not a specifier",
	},
	{
		file = "src/Parse.luau",
		from = 'or string.match(line, "^const(%s.*)$")',
		to = 'or string.match(line, "^konst(%s.*)$")',
		breaks = "a table declared with const is read",
	},
	{
		file = "src/Parse.luau",
		from = 'const TYPED = "^%s+([%w_]+)%s*:[^=]-=%s*{%s*$"',
		to = 'const TYPED = "^%s+([%w_]+)%s*:[%w_%.]-=%s*{%s*$"',
		breaks = "a table's type may be any type written on its opening line",
	},
	{
		file = "src/Parse.luau",
		from = 'const TYPED = "^%s+([%w_]+)%s*:[^=]-=%s*{%s*$"',
		to = 'const TYPED = "^%s+([%w_]+)%s*:.-=%s*{%s*$"',
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
