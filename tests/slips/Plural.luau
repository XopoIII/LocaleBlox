--!strict
--- The mutants of src/Plural.luau: each a small slip in a rule, and the rule it breaks.
const Mutant = require("./Mutant")

const MUTANTS: { Mutant.Mutant } = {
	{
		file = "src/Plural.luau",
		from = "if m10 == 1 and m100 ~= 11 then",
		to = "if m10 == 1 then",
		breaks = "eleven is many in Russian, not one",
	},
	{
		file = "src/Plural.luau",
		from = 'const m10, m100 = n % 10, n % 100\n\tif m10 == 1 and m100 ~= 11 then\n\t\treturn "one"\n\tend\n\tif m10 >= 2 and m10 <= 4 and not (m100 >= 12 and m100 <= 14) then',
		to = 'const m10, m100 = n % 10, n % 100\n\tif m10 == 1 and m100 ~= 11 then\n\t\treturn "one"\n\tend\n\tif m10 >= 2 and m10 <= 4 then',
		breaks = "twelve to fourteen are many in Russian",
	},
	{
		file = "src/Plural.luau",
		from = 'if n == 1 then\n\t\treturn "one"\n\tend\n\tconst m10, m100 = n % 10, n % 100\n\tif m10 >= 2 and m10 <= 4 and not (m100 >= 12 and m100 <= 14) then',
		to = 'if n % 10 == 1 then\n\t\treturn "one"\n\tend\n\tconst m10, m100 = n % 10, n % 100\n\tif m10 >= 2 and m10 <= 4 and not (m100 >= 12 and m100 <= 14) then',
		breaks = "Polish has one only at exactly one",
	},
	{
		file = "src/Plural.luau",
		from = 'if n == 2 then\n\t\treturn "two"\n\tend\n',
		to = "",
		breaks = "Arabic has a form for two",
	},
	{
		file = "src/Plural.luau",
		from = "if m100 >= 3 and m100 <= 10 then",
		to = "if m100 >= 3 and m100 < 10 then",
		breaks = "ten is few in Arabic",
	},
	{
		file = "src/Plural.luau",
		from = "if m100 >= 11 then",
		to = "if m100 >= 0 then",
		breaks = "a hundred is other in Arabic",
	},
	{
		file = "src/Plural.luau",
		from = 'return if count == 0 or count == 1 then "one" else "other"',
		to = 'return if count == 1 then "one" else "other"',
		breaks = "French counts zero with one",
	},
	{
		file = "src/Plural.luau",
		from = 'locale == "fr" or locale == "fr-CA"',
		to = 'locale == "fr"',
		breaks = "French of Canada counts as French does",
	},
	{
		file = "src/Plural.luau",
		from = '\t["pt-PT"] = true,\n',
		to = "",
		breaks = "Portuguese of Portugal has a singular",
	},
	{
		file = "src/Plural.luau",
		from = "const count = math.floor(math.abs(n))",
		to = "const count = math.floor(n)",
		breaks = "a count is taken without its sign",
	},
}

return MUTANTS
