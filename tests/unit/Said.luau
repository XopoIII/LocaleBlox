--!strict
--- A sentence a server says as a key and its arguments, and a client reads in its own language.
local serde = require("@lune/serde")

local Said = require("@localeblox/Said")
local Spec = require("../Spec")
local Text = require("@localeblox/Text")

local said = Said.new({
	encode = function(value: any): string
		return serde.encode("json", value)
	end,
	decode = function(text: string): any
		return serde.decode("json", text)
	end,
})

local TABLES = {
	en = { hatched = "%s hatched a %s on day %d", plain = "Nothing to say", zoneHarbour = "Harbour" },
	ru = { hatched = "RU %s hatched %s day %d", plain = "RU nothing", zoneHarbour = "RU harbour" },
}
local PETS = { ru = { Goldbun = "RU goldbun" } }
local ru = Text.new({ tables = TABLES, names = { pet = PETS }, localeId = "ru" })
local en = Text.new({ tables = TABLES, names = { pet = PETS }, localeId = "en" })

Spec.test("a sentence goes to a string and comes back as its key and arguments", function()
	local wire = said.encode("hatched", { "Ann", { pet = "Goldbun" }, 3 })
	Spec.equal(type(wire), "string")
	local key, args = said.decode(wire)
	Spec.equal(key, "hatched")
	Spec.equal(args, { "Ann", { pet = "Goldbun" }, 3 })
	local bare, none = said.decode(said.encode("plain"))
	Spec.equal(bare, "plain")
	Spec.equal(none, {}, "no arguments is an empty list")
	Spec.equal(said.encode("plain"), said.encode("plain", {}), "and encodes as one")
end)

Spec.test("anything that is not a sentence decodes to nothing", function()
	for _, text in { "", "not json", "[1,2]", '{"a":[1]}', '{"k":5}', "5", "null" } do
		local key, args = said.decode(text)
		Spec.equal(key, nil, text)
		Spec.equal(args, {}, text)
	end
	local key = said.decode(nil)
	Spec.equal(key, nil, "nil")
	Spec.equal(said.decode(5), nil, "a number")
	Spec.equal(said.decode({ k = "plain" }), nil, "a table")
	local kept, args = said.decode('{"k":"plain","a":"oops"}')
	Spec.equal(kept, "plain", "a key with arguments of the wrong kind keeps its key")
	Spec.equal(args, {})
end)

Spec.test("only a string is ever handed to the codec, and what it raises is never a sentence", function()
	local asked = 0
	local lenient = Said.new({
		encode = function(_value: any): string
			return "x"
		end,
		-- A codec that would make a sentence of anything.
		decode = function(_text: string): any
			asked += 1
			return { k = "leak", a = {} }
		end,
	})
	Spec.equal(lenient.decode(5), nil, "a number")
	Spec.equal(lenient.decode({ k = "plain" }), nil, "a table")
	Spec.equal(lenient.decode(true), nil, "a boolean")
	Spec.equal(lenient.decode(""), nil, "an empty string")
	Spec.equal(asked, 0, "the codec was not asked")
	Spec.equal(lenient.decode("anything"), "leak", "a string is its to read")
	Spec.equal(asked, 1)

	local raising = Said.new({
		encode = function(_value: any): string
			return "x"
		end,
		decode = function(_text: string): any
			error({ k = "raised", a = {} })
		end,
	})
	Spec.equal(raising.decode("anything"), nil, "an error shaped like a sentence is still an error")
end)

Spec.test("a client reads a sentence in its own language, names and keys resolved", function()
	local wire = said.encode("hatched", { { key = "zoneHarbour" }, { pet = "Goldbun" }, 3 })
	Spec.equal(said.read(ru, wire), "RU RU harbour hatched RU goldbun day 3")
	Spec.equal(said.read(en, wire), "Harbour hatched a Goldbun on day 3")
	Spec.equal(said.read(ru, said.encode("plain")), "RU nothing")
	Spec.equal(said.read(ru, "not a sentence"), "", "nothing to read")
	Spec.equal(said.read(ru, nil), "")
end)

Spec.test("two sentences are the same only when they would encode alike", function()
	Spec.equal(said.same("a", nil, "a", nil), true)
	Spec.equal(said.same("a", nil, "a", {}), true, "no arguments is no arguments")
	Spec.equal(said.same("a", nil, "b", nil), false, "another key")
	Spec.equal(said.same("a", { 1, "x" }, "a", { 1, "x" }), true)
	Spec.equal(said.same("a", { 1, "x" }, "a", { 1 }), false, "fewer arguments")
	Spec.equal(said.same("a", { 1 }, "a", { 1, "x" }), false, "more arguments")
	Spec.equal(said.same("a", { 1 }, "a", { "1" }), false, "a number is not its text")
	Spec.equal(said.same("a", { 1 }, "a", { 2 }), false)
	Spec.equal(said.same("a", { "x" }, "a", { "y" }), false)
	Spec.equal(said.same("a", { 0 }, "a", { -0 }), false, "zero and minus zero need not encode alike")
	Spec.equal(said.same("a", { 0 }, "a", { 0 }), true)
	Spec.equal(said.same("a", { -0 }, "a", { -0 }), true)
end)

Spec.test("table arguments are the same when they hold the same fields", function()
	Spec.equal(said.same("a", { { pet = "Goldbun" } }, "a", { { pet = "Goldbun" } }), true)
	Spec.equal(said.same("a", { { pet = "Goldbun" } }, "a", { { pet = "Pipkin" } }), false, "another id")
	Spec.equal(said.same("a", { { pet = "Goldbun" } }, "a", { { item = "Goldbun" } }), false, "another kind")
	Spec.equal(said.same("a", { { key = "x" } }, "a", { { key = "x", pet = "y" } }), false, "a field more")
	Spec.equal(said.same("a", { { key = "x", pet = "y" } }, "a", { { key = "x" } }), false, "a field fewer")
	Spec.equal(said.same("a", { { key = "x" } }, "a", { "x" }), false, "a table is not a string")
	Spec.equal(said.same("a", { {} }, "a", { "x" }), false, "nor is an empty one")
	Spec.equal(said.same("a", { "x" }, "a", { {} }), false, "either way round")
end)

Spec.test("a copy is the caller's arguments as they were", function()
	local inner = { pet = "Goldbun" }
	local args: { Said.Arg } = { "Ann", inner, 3 }
	local kept = said.copy(args)
	inner.pet = "Pipkin"
	args[1] = "Bob"
	table.insert(args, 4)
	Spec.equal(kept, { "Ann", { pet = "Goldbun" }, 3 })
	Spec.equal(said.same("a", kept, "a", { "Ann", { pet = "Goldbun" }, 3 }), true)
	Spec.equal(said.copy(nil), nil, "no arguments stay none")
	Spec.equal(said.copy({}), {})
end)

return nil
