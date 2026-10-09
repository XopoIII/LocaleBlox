--!strict
--- The mutants of the frozen module tables: each a module, or the package, handed out writable.
local Mutant = require("./Mutant")

local MUTANTS: { Mutant.Mutant } = {
	{
		file = "src/init.luau",
		from = "return table.freeze({",
		to = "return table.clone({",
		breaks = "the package itself is frozen",
	},
}

for _, name in
	{
		"Keys",
		"Label",
		"Lint",
		"Locale",
		"Localize",
		"Names",
		"Parse",
		"Plural",
		"Said",
		"Text",
		"Usage",
		"Written",
	}
do
	table.insert(MUTANTS, {
		file = `src/{name}.luau`,
		from = `return table.freeze({name})`,
		to = `return {name}`,
		breaks = `every module table is frozen ({name})`,
	})
end

return MUTANTS
