--!strict
--- The mutants of src/Usage.luau: each a small slip in a rule, and the rule it breaks.
const Mutant = require("./Mutant")

const MUTANTS: { Mutant.Mutant } = {
	{
		file = "src/Usage.luau",
		from = "elseif words[word] and table.find(data, word) == nil then",
		to = "elseif words[word] then",
		breaks = "a literal of a data kind is not judged",
	},
	{
		file = "src/Usage.luau",
		from = "elseif words[word] and",
		to = "elseif",
		breaks = "only a literal that starts like a key is judged",
	},
	{
		file = "src/Usage.luau",
		from = "if not used[key] and table.find(data, firstWord(key)) == nil then",
		to = "if not used[key] then",
		breaks = "keys built from game data are left to the game",
	},
	{
		file = "src/Usage.luau",
		from = "\t\t\t\tused[literal] = true\n",
		to = "",
		breaks = "a key the code names is used",
	},
}

return MUTANTS
