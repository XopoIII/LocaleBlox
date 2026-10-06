--!strict
--- The mutants of src/Locale.luau: each a small slip in a rule, and the rule it breaks.
const Mutant = require("./Mutant")

const MUTANTS: { Mutant.Mutant } = {
	{
		file = "src/Locale.luau",
		from = '\tbe = "ru",\n',
		to = "",
		breaks = "Belarusian reads Russian",
	},
	{
		file = "src/Locale.luau",
		from = '\tkk = "ru",\n',
		to = "",
		breaks = "Kazakh reads Russian",
	},
	{
		file = "src/Locale.luau",
		from = '\ttl = "fil",\n',
		to = "",
		breaks = "Tagalog reads Filipino",
	},
	{
		file = "src/Locale.luau",
		from = '\tuk = "uk",',
		to = '\tuk = "ru",',
		breaks = "Ukrainian has its own table",
	},
	{
		file = "src/Locale.luau",
		from = 'then "zh-hant" else "zh-hans"',
		to = 'then "zh-hans" else "zh-hant"',
		breaks = "Chinese is routed by script",
	},
	{
		file = "src/Locale.luau",
		from = "hant = true, tw = true, hk = true, mo = true",
		to = "hant = true, tw = true, hk = true",
		breaks = "Macau reads Traditional",
	},
	{
		file = "src/Locale.luau",
		from = 'then "es-ES" else "es"',
		to = 'then "es" else "es"',
		breaks = "Spanish of Spain has its own table",
	},
	{
		file = "src/Locale.luau",
		from = 'string.match(lower, "^pt[-_]pt")',
		to = 'string.match(lower, "^pt")',
		breaks = "Brazilian and bare Portuguese read the default table",
	},
	{
		file = "src/Locale.luau",
		from = 'then "fr-CA" else "fr"',
		to = 'then "fr" else "fr"',
		breaks = "French of Canada has its own table",
	},
	{
		file = "src/Locale.luau",
		from = "const lower = string.lower(localeId)",
		to = "const lower = localeId",
		breaks = "case does not matter in a LocaleId",
	},
	{
		file = "src/Locale.luau",
		from = 'return LANGUAGE[language] or "en"',
		to = 'return LANGUAGE[language] or "ru"',
		breaks = "an unknown locale reads English",
	},
	{
		file = "src/Locale.luau",
		from = "return RTL[locale] == true",
		to = "return RTL[locale] ~= true",
		breaks = "only Arabic runs right to left",
	},
	{
		file = "src/Locale.luau",
		from = "return own[key] or en[key] or key",
		to = "return own[key] or key",
		breaks = "a key the locale lacks reads English",
	},
	{
		file = "src/Locale.luau",
		from = '\tassert(en ~= nil, "LocaleBlox: the tables hold no English table")\n',
		to = "",
		breaks = "tables without English are refused, by name",
	},
	{
		file = "src/Locale.luau",
		from = "\t\t\ttable.sort(out)\n\t\t\treturn out\n\t\tend,\n\n\t\tpopulated",
		to = "\t\t\treturn out\n\t\tend,\n\n\t\tpopulated",
		breaks = "keys are sorted",
	},
}

return MUTANTS
