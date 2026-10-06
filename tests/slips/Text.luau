--!strict
--- The mutants of src/Text.luau: each a small slip in a rule, and the rule it breaks.
const Mutant = require("./Mutant")

const MUTANTS: { Mutant.Mutant } = {
	{
		file = "src/Text.luau",
		from = "args[index] = router.get(locale, arg.key)",
		to = "args[index] = arg.key",
		breaks = "an argument that is a key is looked up",
	},
	{
		file = "src/Text.luau",
		from = "\t\tif count == 0 then\n\t\t\treturn template\n\t\tend\n",
		to = "",
		breaks = "a template with no arguments is returned as written",
	},
	{
		file = "src/Text.luau",
		from = "template = found[Plural.category(ruled, n)] or found.other or found.many or found.one",
		to = "template = found.other or found.many or found.one",
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
		from = "return string.format(template or router.get(locale, key), n, table.unpack(args, 1, extra))",
		to = "return string.format(template or router.get(locale, key), table.unpack(args, 1, extra))",
		breaks = "the count is the first format argument",
	},
	{
		file = "src/Text.luau",
		from = "return router.get(locale, key) ~= key",
		to = "return router.get(locale, key) == key",
		breaks = "has is true for a key with text",
	},
	{
		file = "src/Text.luau",
		from = "return get(Keys.of(kind, name, field))",
		to = "return get(Keys.of(kind, name))",
		breaks = "game data reads by its key",
	},
}

return MUTANTS
