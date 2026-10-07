--!strict
--- A sentence a server says, as a key and its arguments rather than finished words, so each client
--- puts it in its own reader's language.
---
---     const said = Said.new({ encode = encodeJson, decode = decodeJson })
---     const wire = said.encode("hatched", { { name = "Goldbun" }, 3 })   -- server
---     label.Text = said.read(text, wire)                                 -- client
---
--- It travels as one string: an attribute, a field of a packet. An argument is a string, a number,
--- or a small table the reader resolves: `{ key = "..." }` for another key, `{ <kind> = "<id>" }` for
--- a name of a kind the game gave its reader (`Text`).
---
--- The codec is the game's: on Roblox, `HttpService`'s JSON pair. Nothing here reads a service.
const Text = require("./Text")

const Said = {}

--> How a sentence is written to a string and read back. `decode` may raise on a string that is not
--> one of its own.
export type Codec = {
	encode: (value: any) -> string,
	decode: (text: string) -> any,
}

export type Arg = string | number | { [string]: string }

export type Said = {
	--> The sentence as one string.
	encode: (key: string, args: { Arg }?) -> string,
	--> The key and arguments of an encoded sentence, or nil and no arguments for anything else.
	decode: (text: any) -> (string?, { any }),
	--> Whether two sentences are certainly the same, so the one already said need not be encoded
	--> again to find out. Only ever true when `encode` would give both one string.
	same: (keyA: string, argsA: { Arg }?, keyB: string, argsB: { Arg }?) -> boolean,
	--> A copy of `args` for `same` to compare with later: a caller that reuses or changes its table
	--> cannot change what was said.
	copy: (args: { Arg }?) -> { Arg }?,
	--> An encoded sentence in a reader's language; "" for anything that is not one.
	read: (reader: Text.Reader, encoded: any) -> string,
}

-- Two table arguments are one when they hold the same fields.
const function sameFields(a: { [any]: any }, b: { [any]: any }): boolean
	for field, value in a do
		if b[field] ~= value then
			return false
		end
	end
	for field in b do
		if a[field] == nil then
			return false
		end
	end
	return true
end

const function sameArg(a: any, b: any): boolean
	if type(a) ~= type(b) then
		return false
	elseif type(a) == "table" then
		return sameFields(a, b)
	elseif type(a) == "number" then
		-- 0 and -0 are equal but need not encode alike.
		return a == b and (a ~= 0 or 1 / a == 1 / b)
	end
	return a == b
end

--> One game's sentences over its codec.
function Said.new(codec: Codec): Said
	const self = {} :: Said

	function self.encode(key: string, args: { Arg }?): string
		return codec.encode({ k = key, a = args or {} })
	end

	function self.decode(text: any): (string?, { any })
		if type(text) ~= "string" or text == "" then
			return nil, {}
		end
		const ok, value = pcall(codec.decode, text)
		if not ok or type(value) ~= "table" or type(value.k) ~= "string" then
			return nil, {}
		end
		return value.k, if type(value.a) == "table" then value.a else {}
	end

	function self.same(keyA: string, argsA: { Arg }?, keyB: string, argsB: { Arg }?): boolean
		if keyA ~= keyB then
			return false
		end
		const a: { Arg } = argsA or {}
		const b: { Arg } = argsB or {}
		if #a ~= #b then
			return false
		end
		for index = 1, #a do
			if not sameArg(a[index], b[index]) then
				return false
			end
		end
		return true
	end

	function self.copy(args: { Arg }?): { Arg }?
		if args == nil then
			return nil
		end
		const out: { Arg } = {}
		for index, arg in args do
			out[index] = if type(arg) == "table" then table.clone(arg) else arg
		end
		return out
	end

	function self.read(reader: Text.Reader, encoded: any): string
		const key, args = self.decode(encoded)
		if key == nil then
			return ""
		end
		return reader.get(key, table.unpack(args))
	end

	return self
end

return Said
