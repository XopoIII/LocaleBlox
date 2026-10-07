--!strict
--- Reads locale tables out of a Luau source as text.
---
--- A game's lint runs off Roblox and cannot always `require` its tables, so it reads them as text.
--- That fixes their shape: a table opens with `local name: Type = {` (or `const`) on a line of its
--- own, holds one `\tkey = "value",` per line, and closes with `}` at the start of a line. A value
--- is taken as written, escapes included. A carriage return before the line end is ignored. The
--- type may be any type written on that one line (`Table`, `Locale.Table`, `{ [string]: string }`),
--- or absent.
const Parse = {}

export type Locales = { [string]: { [string]: string } }

-- A table's opening line with no type, and with one: the type is whatever stands between the colon
-- and the equals sign.
const BARE = "^%s+([%w_]+)%s*=%s*{%s*$"
const TYPED = "^%s+([%w_]+)%s*:[^=]-=%s*{%s*$"

--> The name of the table a line opens, or nil when it opens none.
function Parse.opens(line: string): string?
	const rest = string.match(line, "^local(%s.*)$") or string.match(line, "^const(%s.*)$")
	if rest == nil then
		return nil
	end
	return string.match(rest, BARE) or string.match(rest, TYPED)
end

--> Adds every table of `source` to `out`, as `out[code][key] = value`. A table's variable name is
--> its locale code unless `aliases` renames it (`zhHans` to "zh-hans").
function Parse.source(source: string, out: Locales, aliases: { [string]: string }?)
	local current: string? = nil
	for line in string.gmatch(source .. "\n", "(.-)\n") do
		const name = Parse.opens(line)
		if name ~= nil then
			const code = if aliases ~= nil and aliases[name] ~= nil then aliases[name] else name
			current = code
			out[code] = out[code] or {}
			continue
		end
		if string.match(line, "^}") then
			current = nil
			continue
		end
		if current ~= nil then
			const key, value = string.match(line, '^\t([%w_]+)%s*=%s*"(.*)",%s*$')
			if key ~= nil and value ~= nil then
				out[current][key] = value
			end
		end
	end
end

--> The `string.format` specifiers of a string, in order. An escaped `%%` is not one.
function Parse.specifiers(text: string): { string }
	const clean = string.gsub(text, "%%%%", "")
	const out: { string } = {}
	for specifier in string.gmatch(clean, "%%[-+ #0-9%.]*%a") do
		table.insert(out, specifier)
	end
	return out
end

return Parse
