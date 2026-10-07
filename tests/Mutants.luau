--!strict
--- The mutants tests/Mutate runs, a file of them per module of src/ (tests/slips/).
--- Every `from` must occur exactly once in its file.
const Mutant = require("./slips/Mutant")

export type Mutant = Mutant.Mutant

const MUTANTS: { Mutant } = {}
for _, list in
	{
		require("./slips/Locale"),
		require("./slips/Plural"),
		require("./slips/Keys"),
		require("./slips/Text"),
		require("./slips/Names"),
		require("./slips/Said"),
		require("./slips/Label"),
		require("./slips/Parse"),
		require("./slips/Lint"),
		require("./slips/Written"),
		require("./slips/Usage"),
	} :: { { Mutant } }
do
	table.move(list, 1, #list, #MUTANTS + 1, MUTANTS)
end

return MUTANTS
