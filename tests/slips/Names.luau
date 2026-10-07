--!strict
--- The mutants of src/Names.luau and of the reader's use of it: each a small slip, and the rule it breaks.
const Mutant = require("./Mutant")

const MUTANTS: { Mutant.Mutant } = {
	{
		file = "src/Names.luau",
		from = 'if name ~= nil and name ~= "" then\n\t\treturn name\n\tend\n\treturn id',
		to = "if name ~= nil then\n\t\treturn name\n\tend\n\treturn id",
		breaks = "an empty name shows the id",
	},
	{
		file = "src/Names.luau",
		from = "const name = if own ~= nil then own[id] else nil",
		to = "const name = if own ~= nil then id else nil",
		breaks = "a name is the locale's own",
	},
	{
		file = "src/Names.luau",
		from = 'if name ~= nil and name ~= "" then\n\t\t\t\thave += 1',
		to = "if name ~= nil then\n\t\t\t\thave += 1",
		breaks = "an empty name is not counted as named",
	},
	{
		file = "src/Names.luau",
		from = "return a.have > b.have",
		to = "return a.have < b.have",
		breaks = "coverage is fullest first",
	},
	{
		file = "src/Names.luau",
		from = "return a.locale < b.locale",
		to = "return a.locale > b.locale",
		breaks = "a tie is in code order",
	},
	{
		file = "src/Names.luau",
		from = "table.insert(out, { locale = locale, have = have, total = #ids })",
		to = "table.insert(out, { locale = locale, have = have, total = have })",
		breaks = "coverage says how many ids were asked about",
	},
	{
		file = "src/Names.luau",
		from = "\tfor _, locales in out do\n\t\ttable.sort(locales)\n\tend\n",
		to = "",
		breaks = "the locales that name an id are in order",
	},
	{
		file = "src/Text.luau",
		from = "return Names.get(tables, locale, id)",
		to = "return Names.get(tables, english, id)",
		breaks = "a reader names a thing in its own locale",
	},
	{
		file = "src/Text.luau",
		from = "\t\tif tables == nil then\n\t\t\treturn id\n\t\tend\n",
		to = "\t\tif tables == nil then\n\t\t\treturn kind\n\t\tend\n",
		breaks = "a kind the reader was not given shows the id",
	},
	{
		file = "src/Text.luau",
		from = 'if type(id) == "string" then\n\t\t\t\treturn name(kind, id)',
		to = "if id ~= nil then\n\t\t\t\treturn name(kind, id)",
		breaks = "a thing's id is a string",
	},
	{
		file = "src/Text.luau",
		from = "args[index] = word(arg) or arg",
		to = "args[index] = word(arg) or tostring(arg)",
		breaks = "a table that is neither a key nor a thing is left as it came",
	},
	{
		file = "src/Text.luau",
		from = "const locale: Locale.Locale = if given ~= nil then given else Locale.localeFor(localeId)",
		to = "const locale: Locale.Locale = Locale.localeFor(localeId)",
		breaks = "a reader given its table reads it",
	},
	{
		file = "src/Text.luau",
		from = "\t\tresolve(args, extra)\n",
		to = "",
		breaks = "a counted sentence resolves its arguments",
	},
}

return MUTANTS
