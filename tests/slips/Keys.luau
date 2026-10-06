--!strict
--- The mutants of src/Keys.luau: each a small slip in a rule, and the rule it breaks.
const Mutant = require("./Mutant")

const MUTANTS: { Mutant.Mutant } = {
	{
		file = "src/Keys.luau",
		from = 'out = string.gsub(out, "[^%w]", "")',
		to = "out = out",
		breaks = "a key holds letters and digits only",
	},
	{
		file = "src/Keys.luau",
		from = "\t\tkey ..= pascal(field)\n",
		to = "\t\tkey ..= field\n",
		breaks = "a field is capitalised into the key",
	},
}

return MUTANTS
