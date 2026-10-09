--!strict
--- The mutants of src/Lint.luau: each a small slip in a rule, and the rule it breaks.
local Mutant = require("./Mutant")

local MUTANTS: { Mutant.Mutant } = {
	{
		file = "src/Lint.luau",
		from = "\tif #a ~= #b then\n\t\treturn false\n\tend\n",
		to = "",
		breaks = "a translation with more placeholders than English is found",
	},
	{
		file = "src/Lint.luau",
		from = "if a[index] ~= b[index] then",
		to = "if false then",
		breaks = "placeholders match in kind and order",
	},
	{
		file = "src/Lint.luau",
		from = '\t\t\tif value == nil then\n\t\t\t\tbad(`{code}: missing key "{key}"`)\n\t\t\telseif',
		to = "\t\t\tif value == nil then\n\t\t\t\tcontinue\n\t\t\telseif",
		breaks = "every locale holds every English key",
	},
	{
		file = "src/Lint.luau",
		from = "\t\t\tif en[key] == nil then\n",
		to = "\t\t\tif false then\n",
		breaks = "no locale holds a key English lacks",
	},
	{
		file = "src/Lint.luau",
		from = '\t\tif value == "" then\n\t\t\tbad(`en.{key}: empty string`)\n\t\tend\n',
		to = "",
		breaks = "an empty English string is a problem",
	},
	{
		file = "src/Lint.luau",
		from = '\t\t\tif value == "" then\n\t\t\t\tbad(`{code}.{key}: empty string`)\n\t\t\tend\n',
		to = "",
		breaks = "an empty translation is a problem",
	},
	{
		file = "src/Lint.luau",
		from = "if contains(value, COMBINING_ACUTE) then",
		to = "if false then",
		breaks = "a combining acute accent is a problem",
	},
	{
		file = "src/Lint.luau",
		from = 'local points = if code == "zh-hant" then SIMPLIFIED else TRADITIONAL',
		to = 'local points = if code == "zh-hant" then TRADITIONAL else SIMPLIFIED',
		breaks = "the Traditional table holds no Simplified glyph, and the reverse",
	},
	{
		file = "src/Lint.luau",
		from = "if full ~= nil and half ~= nil then",
		to = "if false then",
		breaks = "a Chinese table uses one width of punctuation",
	},
	{
		file = "src/Lint.luau",
		from = 'if code == "zh-hant" or code == "zh-hans" then\n\t\t\tchinese',
		to = "if true then\n\t\t\tchinese",
		breaks = "only Chinese tables are held to the Chinese rules",
	},
	{
		file = "src/Lint.luau",
		from = "\ttable.sort(keys)\n",
		to = "",
		breaks = "the punctuation samples are the first keys in order",
	},
	{
		file = "src/Lint.luau",
		from = "\t\t\t\tif not CATEGORIES[category] then",
		to = "\t\t\t\tif false then",
		breaks = "a plural form is filed under a CLDR category",
	},
	{
		file = "src/Lint.luau",
		from = "if forms.other == nil and forms.many == nil then",
		to = "if forms.other == nil and forms.many == nil and forms.few == nil then",
		breaks = "plural forms have a form to fall back on",
	},
	{
		file = "src/Lint.luau",
		from = "elseif not sameSpecifiers(wanted, Parse.specifiers(form)) then",
		to = "elseif false then",
		breaks = "a plural form has English's placeholders",
	},
	{
		file = "src/Lint.luau",
		from = "\t\t\tif source == nil then\n\t\t\t\ttable.insert(out, `{code}.{key}: counted key is not in English`)\n\t\t\t\tcontinue\n\t\t\tend\n",
		to = "\t\t\tif source == nil then\n\t\t\t\tcontinue\n\t\t\tend\n",
		breaks = "a counted key exists in English",
	},
}

return MUTANTS
