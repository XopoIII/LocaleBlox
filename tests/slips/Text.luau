--!strict
--- The mutants of src/Text.luau: each a small slip in a rule, and the rule it breaks.
local Mutant = require("./Mutant")

local MUTANTS: { Mutant.Mutant } = {
	{
		file = "src/Text.luau",
		from = "return router.get(locale, arg.key)",
		to = "return arg.key",
		breaks = "an argument that is a key is looked up",
	},
	{
		file = "src/Text.luau",
		from = "\t\t\treturn template\n\t\tend\n",
		to = "\t\t\treturn string.format(template)\n\t\tend\n",
		breaks = "a template with no arguments is returned as written",
	},
	{
		file = "src/Text.luau",
		from = "form = found[Plural.category(ruled, n)] or found.other or found.many or found.one",
		to = "form = found.other or found.many or found.one",
		breaks = "a counted sentence takes the form of its number",
	},
	{
		file = "src/Text.luau",
		from = "found[Plural.category(ruled, n)] or found.other or found.many",
		to = "found[Plural.category(ruled, n)] or found.many or found.other",
		breaks = "a missing category falls back to other first",
	},
	{
		file = "src/Text.luau",
		from = "and options.tables[locale] == nil then",
		to = "then",
		breaks = "a locale that ships a table but no forms keeps its flat string",
	},
	{
		file = "src/Text.luau",
		from = "\t\t\treturn fallback[key], english\n",
		to = "\t\t\treturn fallback[key], locale\n",
		breaks = "English forms are chosen by English's rules",
	},
	{
		file = "src/Text.luau",
		from = "pcall(string.format, template, n)",
		to = "pcall(string.format, template)",
		breaks = "the count is the first format argument",
	},
	{
		file = "src/Text.luau",
		from = "pcall(string.format, template, n, other)",
		to = "pcall(string.format, template, other)",
		breaks = "the count is the first format argument, before one more",
	},
	{
		file = "src/Text.luau",
		from = "pcall(string.format, template, n, table.unpack(args, 1, extra))",
		to = "pcall(string.format, template, table.unpack(args, 1, extra))",
		breaks = "the count is the first format argument, before two more",
	},
	{
		file = "src/Text.luau",
		from = "only = word(only) or only",
		to = "only = only",
		breaks = "a lone argument that is a key is looked up",
	},
	{
		file = "src/Text.luau",
		from = "first = word(first) or first",
		to = "first = first",
		breaks = "the first of two arguments is looked up",
	},
	{
		file = "src/Text.luau",
		from = "second = word(second) or second",
		to = "second = second",
		breaks = "the second of two arguments is looked up",
	},
	{
		file = "src/Text.luau",
		from = "other = word(other) or other",
		to = "other = other",
		breaks = "a counted sentence looks up its one argument",
	},
	{
		file = "src/Text.luau",
		from = "only = word(only) or only",
		to = "only = word(only) or tostring(only)",
		breaks = "a table that is no word is left as it came, alone",
	},
	{
		file = "src/Text.luau",
		from = "first = word(first) or first",
		to = "first = word(first) or tostring(first)",
		breaks = "a table that is no word is left as it came, first of two",
	},
	{
		file = "src/Text.luau",
		from = "second = word(second) or second",
		to = "second = word(second) or tostring(second)",
		breaks = "a table that is no word is left as it came, second of two",
	},
	{
		file = "src/Text.luau",
		from = "other = word(other) or other",
		to = "other = word(other) or tostring(other)",
		breaks = "a table that is no word is left as it came, after a count",
	},
	{
		file = "src/Text.luau",
		from = "\t\t\tresolve(args, count)\n",
		to = "",
		breaks = "three arguments and more are looked up",
	},
	{
		file = "src/Text.luau",
		from = "\t\t\tresolve(args, extra)\n",
		to = "",
		breaks = "a counted sentence looks up two arguments and more",
	},
	{
		file = "src/Text.luau",
		from = "return if ok then text else template",
		to = "return text",
		breaks = "a sentence whose arguments do not fit reads as its bare template",
	},
	{
		file = "src/Text.luau",
		from = "return if fits then sentence else template",
		to = "return sentence",
		breaks = "a count its sentence cannot take reads as its bare template",
	},
	{
		file = "src/Text.luau",
		from = "return router.get(locale, key) ~= key",
		to = "return router.get(locale, key) == key",
		breaks = "has is true for a key with text",
	},
	{
		file = "src/Text.luau",
		from = "return get(Keys.of(kind, id, field))",
		to = "return get(Keys.of(kind, id))",
		breaks = "game data reads by its key",
	},
}

return MUTANTS
