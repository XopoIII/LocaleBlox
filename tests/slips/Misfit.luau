--!strict
--- The mutants of the reader's hook (src/Text.luau): each a small slip in how a game is told of a
--- sentence that did not fit, and the rule it breaks.
local Mutant = require("./Mutant")

local TELL = "coroutine.resume(coroutine.create(hook), key, locale, template, tostring(problem))"
local KNOWN = "\t\tif seen[template] then\n\t\t\treturn\n\t\tend\n\t\tseen[template] = true\n"
local OF_KEY = "\t\tlocal seen = told[key]\n\t\tif seen == nil then\n\t\t\tseen = {}\n\t\t\ttold[key] = seen\n\t\tend\n"
local IN_GET = "\t\tif misfit ~= nil then\n\t\t\ttell(misfit, key, template, text)\n\t\tend\n"
local IN_COUNT = "\t\tif misfit ~= nil then\n\t\t\ttell(misfit, key, template, sentence)\n\t\tend\n"

local MUTANTS: { Mutant.Mutant } = {
	{
		file = "src/Text.luau",
		from = IN_GET,
		to = "",
		breaks = "a sentence that does not fit is told",
	},
	{
		file = "src/Text.luau",
		from = IN_COUNT,
		to = "",
		breaks = "a count its sentence cannot take is told",
	},
	{
		file = "src/Text.luau",
		from = IN_GET,
		to = "\t\ttell(misfit :: any, key, template, text)\n",
		breaks = "a reader with no hook reads as before",
	},
	{
		file = "src/Text.luau",
		from = IN_COUNT,
		to = "\t\ttell(misfit :: any, key, template, sentence)\n",
		breaks = "a reader with no hook counts as before",
	},
	{
		file = "src/Text.luau",
		from = TELL,
		to = "coroutine.resume(coroutine.create(hook), template, locale, template, tostring(problem))",
		breaks = "the hook is handed the key",
	},
	{
		file = "src/Text.luau",
		from = TELL,
		to = "coroutine.resume(coroutine.create(hook), key, localeId, template, tostring(problem))",
		breaks = "the hook is handed the locale read, not the id it came from",
	},
	{
		file = "src/Text.luau",
		from = TELL,
		to = "coroutine.resume(coroutine.create(hook), key, locale, key, tostring(problem))",
		breaks = "the hook is handed the template as read",
	},
	{
		file = "src/Text.luau",
		from = TELL,
		to = "coroutine.resume(coroutine.create(hook), key, locale, template, template)",
		breaks = "the hook is handed the format's message",
	},
	{
		file = "src/Text.luau",
		from = TELL,
		to = "coroutine.resume(coroutine.create(hook), key, locale, template, problem)",
		breaks = "the fault is handed over as text",
	},
	{
		file = "src/Text.luau",
		from = TELL,
		to = "coroutine.resume(coroutine.create(hook), key, locale, template, tostring(problem), key)",
		breaks = "the hook is handed four things and no more",
	},
	{
		file = "src/Text.luau",
		from = TELL,
		to = "hook(key, locale, template, tostring(problem))",
		breaks = "a hook that raises costs the reader nothing",
	},
	{
		file = "src/Text.luau",
		from = TELL,
		to = "pcall(hook, key, locale, template, tostring(problem))",
		breaks = "a hook that yields does not hold the reader",
	},
	{
		file = "src/Text.luau",
		from = KNOWN,
		to = "",
		breaks = "a key and a template are told once",
	},
	{
		file = "src/Text.luau",
		from = KNOWN,
		to = "\t\tif seen[1] then\n\t\t\treturn\n\t\tend\n\t\tseen[1] = true\n",
		breaks = "another form of a key told before is told",
	},
	{
		file = "src/Text.luau",
		from = OF_KEY,
		to = '\t\tlocal seen = told[""]\n\t\tif seen == nil then\n\t\t\tseen = {}\n\t\t\ttold[""] = seen\n\t\tend\n',
		breaks = "another key with the same words is told",
	},
	{
		file = "src/Text.luau",
		from = TELL,
		to = "seen[template] = nil\n\t\t" .. TELL .. "\n\t\tseen[template] = true",
		breaks = "a sentence is marked before its hook runs",
	},
	{
		file = "src/Text.luau",
		from = "\tlocal told: { [string]: { [string]: boolean } } = {}\n",
		to = "\tlocal told: { [string]: { [string]: boolean } } = _G :: any\n",
		breaks = "each reader tells for itself",
	},
}

return MUTANTS
