--!strict
--- The mutants of src/Said.luau: each a small slip in a rule, and the rule it breaks.
local Mutant = require("./Mutant")

local MUTANTS: { Mutant.Mutant } = {
	{
		file = "src/Said.luau",
		from = "return codec.encode({ k = key, a = args or {} })",
		to = "return codec.encode({ k = key, a = args })",
		breaks = "no arguments is an empty list",
	},
	{
		file = "src/Said.luau",
		from = 'if type(text) ~= "string" or text == "" then',
		to = 'if text == "" then',
		breaks = "only a string can be a sentence",
	},
	{
		file = "src/Said.luau",
		from = 'if not ok or type(value) ~= "table" or type(value.k) ~= "string" then',
		to = 'if not ok or type(value) ~= "table" then',
		breaks = "a sentence has a key that is a string",
	},
	{
		file = "src/Said.luau",
		from = 'if not ok or type(value) ~= "table" or type(value.k) ~= "string" then',
		to = 'if type(value) ~= "table" or type(value.k) ~= "string" then',
		breaks = "a string the codec cannot read is no sentence",
	},
	{
		file = "src/Said.luau",
		from = 'return value.k, if type(value.a) == "table" then value.a else {}',
		to = "return value.k, value.a",
		breaks = "arguments of the wrong kind are no arguments",
	},
	{
		file = "src/Said.luau",
		from = "\t\tif keyA ~= keyB then\n\t\t\treturn false\n\t\tend\n",
		to = "",
		breaks = "another key is another sentence",
	},
	{
		file = "src/Said.luau",
		from = "\t\tif #a ~= #b then\n\t\t\treturn false\n\t\tend\n",
		to = "",
		breaks = "more arguments is another sentence",
	},
	{
		file = "src/Said.luau",
		from = "\tif type(a) ~= type(b) then\n\t\treturn false\n",
		to = "\tif false then\n\t\treturn false\n",
		breaks = "a number is not its text, and a table is not a string",
	},
	{
		file = "src/Said.luau",
		from = "return a == b and (a ~= 0 or 1 / a == 1 / b)",
		to = "return a == b",
		breaks = "zero and minus zero need not encode alike",
	},
	{
		file = "src/Said.luau",
		from = "\tfor field in b do\n\t\tif a[field] == nil then\n\t\t\treturn false\n\t\tend\n\tend\n",
		to = "",
		breaks = "a field more is another argument",
	},
	{
		file = "src/Said.luau",
		from = "\tfor field, value in a do\n\t\tif b[field] ~= value then\n\t\t\treturn false\n\t\tend\n\tend\n",
		to = "",
		breaks = "another id is another argument",
	},
	{
		file = "src/Said.luau",
		from = 'out[index] = if type(arg) == "table" then table.clone(arg) else arg',
		to = "out[index] = arg",
		breaks = "a copy is the caller's arguments as they were",
	},
	{
		file = "src/Said.luau",
		from = "\t\tif args == nil then\n\t\t\treturn nil\n\t\tend\n",
		to = "\t\tif args == nil then\n\t\t\treturn {}\n\t\tend\n",
		breaks = "no arguments stay none",
	},
	{
		file = "src/Said.luau",
		from = '\t\tif key == nil then\n\t\t\treturn ""\n\t\tend\n',
		to = "\t\tif key == nil then\n\t\t\treturn tostring(encoded)\n\t\tend\n",
		breaks = "what is not a sentence reads as nothing",
	},
	{
		file = "src/Said.luau",
		from = "return reader.get(key, table.unpack(args))",
		to = "return reader.get(key)",
		breaks = "a sentence is read with its arguments",
	},
}

return MUTANTS
