--!strict
--- One reader for every word a client draws, bound to a game's tables and a player's locale.
---
---     local text = Text.new({ tables = Tables, plurals = Plurals, localeId = player.LocaleId })
---     text.get("open")                          --> "Open"
---     text.get("movedTo", { key = "zoneHarbour" })
---     text.count("itemsCarried", 3, 12)         -- the noun agrees with 3
---
--- With `names`, an argument may also be a thing of the game by its id, and the sentence gets that
--- thing's name in the reader's language:
---
---     local text = Text.new({ tables = Tables, names = { pet = PetNames }, localeId = id })
---     text.get("hatched", { pet = "Goldbun" })
---     text.name("pet", "Goldbun")
---
--- With `misfit`, the game hears of a sentence whose arguments did not fit its placeholders, which
--- the player sees as the bare template:
---
---     local text = Text.new({ tables = Tables, localeId = id, misfit = function(key, locale, template, problem)
---         report(key, locale, template, problem)
---     end })
---
--- The locale id is an argument: nothing here reads a player, a service or an attribute. Amounts
--- arrive already written as strings and ride `%s`.
local Keys = require("./Keys")
local Locale = require("./Locale")
local Names = require("./Names")
local Plural = require("./Plural")

local Text = {}

export type Forms = { [string]: string }
export type Plurals = { [string]: { [string]: Forms } }

--- What a game is told of a sentence that did not fit: the key asked for, the locale the reader
--- reads in, the template as it was read (a plural form, the English a missing string fell back to,
--- or the key itself) and `string.format`'s own message. The arguments are not among them: they
--- may hold a player's name.
export type Misfit = (key: string, locale: Locale.Locale, template: string, problem: string) -> ()

export type Options = {
	--- The game's tables by locale; English is required.
	tables: Locale.Tables,
	--- The player's Roblox LocaleId, or any BCP-47 tag.
	localeId: string,
	--- The table to read, when it is already known: a server writing in one locale, a spec walking
	--- every table. It is used as given, in place of what `localeId` would resolve to.
	locale: Locale.Locale?,
	--- Counted forms by locale, key and CLDR category. A key absent here uses its flat string.
	plurals: Plurals?,
	--- The names of the game's things, by kind: `{ pet = PetNames }` makes `{ pet = "<id>" }` an
	--- argument and `name("pet", "<id>")` a lookup (`Names`).
	names: { [string]: Names.Tables }?,
	--- Called when a sentence's arguments do not fit its placeholders, once for each key and
	--- template this reader meets: a label drawn every frame tells of its bad sentence once. The
	--- reader gives the bare template back whatever this does. It runs in its own coroutine, so one
	--- that raises or yields costs the caller nothing.
	misfit: Misfit?,
}

export type Reader = {
	--- The string for a key, formatted when arguments follow. An argument `{ key = "..." }` is
	--- looked up first, and so is `{ <kind> = "<id>" }` for a kind given in `names`, so a translated
	--- sentence never gets an English word in a slot. Arguments that do not fit the placeholders
	--- give the bare template back rather than raising, and `options.misfit` is told.
	get: (key: string, ...any) -> string,
	--- A sentence whose noun agrees with `n`; `n` is the first format argument. A fractional `n`
	--- takes the "other" form (CLDR: a fraction agrees with no noun).
	count: (key: string, n: number, ...any) -> string,
	--- The text of a piece of game data (`Keys.of`).
	data: (kind: string, name: string, field: string?) -> string,
	--- The name of one of the game's things in this locale; the id itself when the kind is not
	--- known or this locale does not name it.
	name: (kind: string, id: string) -> string,
	--- Whether a key has text in this locale or in English.
	has: (key: string) -> boolean,
	locale: () -> Locale.Locale,
	localeId: () -> string,
	isRtl: () -> boolean,
}

--> A reader over `options.tables` for the locale `options.localeId` resolves to.
function Text.new(options: Options): Reader
	local router = Locale.router(options.tables)
	local localeId = options.localeId
	local given = options.locale
	local locale: Locale.Locale = if given ~= nil then given else Locale.localeFor(localeId)
	local plurals: Plurals = options.plurals or {}
	local names: { [string]: Names.Tables } = options.names or {}
	local english: Locale.Locale = "en"
	local misfit = options.misfit
	-- The templates of each key the game has been told of.
	local told: { [string]: { [string]: boolean } } = {}

	-- Tells the game of a sentence that did not fit, the first time this key reads as this
	-- template. It is marked before the game is told, so a hook that reads the same sentence, or
	-- raises, is not called for it again. The hook runs in a coroutine of its own: its error stays
	-- there, and when it yields the reader goes on without it.
	local function tell(hook: Misfit, key: string, template: string, problem: unknown)
		local seen = told[key]
		if seen == nil then
			seen = {}
			told[key] = seen
		end
		if seen[template] then
			return
		end
		seen[template] = true
		-- The message is `string.format`'s, a string; an argument whose `__tostring` raised
		-- something else is written out, so the hook is always handed text.
		coroutine.resume(coroutine.create(hook), key, locale, template, tostring(problem))
	end

	local function name(kind: string, id: string): string
		local tables = names[kind]
		if tables == nil then
			return id
		end
		return Names.get(tables, locale, id)
	end

	-- A table argument as a word of this locale: a key's text or a thing's name. Nil for a table
	-- that is neither, which is left as it came.
	local function word(arg: { [any]: any }): string?
		if type(arg.key) == "string" then
			return router.get(locale, arg.key)
		end
		for kind in names do
			local id = arg[kind]
			if type(id) == "string" then
				return name(kind, id)
			end
		end
		return nil
	end

	-- Arguments that are keys or things become words of this locale.
	local function resolve(args: { any }, count: number)
		for index = 1, count do
			local arg = args[index]
			if type(arg) == "table" then
				args[index] = word(arg) or arg
			end
		end
	end

	local function get(key: string, ...: any): string
		local template = router.get(locale, key)
		local count = select("#", ...)
		if count == 0 then
			-- The common call is a key alone: no format is run, and the template's escapes
			-- stay as written.
			return template
		end
		-- A sentence whose arguments do not fit its placeholders reads as its bare template
		-- rather than raising on the client: a missing key with a `%` in it, a translation a
		-- lint did not see. The lint (`Lint`) is the gate; this is the safety net.
		--
		-- Up to three arguments are the calls a game makes most, and are formatted without a
		-- table made to hold them.
		local ok: boolean, text: string
		if count == 1 then
			local only = ...
			if type(only) == "table" then
				only = word(only) or only
			end
			ok, text = pcall(string.format, template, only)
		elseif count == 2 then
			local first, second = ...
			if type(first) == "table" then
				first = word(first) or first
			end
			if type(second) == "table" then
				second = word(second) or second
			end
			ok, text = pcall(string.format, template, first, second)
		elseif count == 3 then
			local one, two, three = ...
			if type(one) == "table" then
				one = word(one) or one
			end
			if type(two) == "table" then
				two = word(two) or two
			end
			if type(three) == "table" then
				three = word(three) or three
			end
			ok, text = pcall(string.format, template, one, two, three)
		else
			local args = table.pack(...)
			resolve(args, count)
			ok, text = pcall(string.format, template, table.unpack(args, 1, count))
		end
		if ok then
			return text
		end
		if misfit ~= nil then
			tell(misfit, key, template, text)
		end
		return template
	end

	-- The forms of a key: this locale's, else English's, so an untranslated count still agrees.
	local function forms(key: string): (Forms?, string)
		local own = plurals[locale]
		if own ~= nil and own[key] ~= nil then
			return own[key], locale
		end
		local fallback = plurals[english]
		if fallback ~= nil and fallback[key] ~= nil and options.tables[locale] == nil then
			return fallback[key], english
		end
		return nil, locale
	end

	local function count(key: string, n: number, ...: any): string
		local extra = select("#", ...)
		local form: string? = nil
		local found, ruled = forms(key)
		if found ~= nil then
			form = found[Plural.category(ruled, n)] or found.other or found.many or found.one
		end
		local template = form or router.get(locale, key)
		-- As in `get`: a count its sentence cannot take reads as the bare template.
		local fits: boolean, sentence: string
		if extra == 0 then
			fits, sentence = pcall(string.format, template, n)
		elseif extra == 1 then
			local other = ...
			if type(other) == "table" then
				other = word(other) or other
			end
			fits, sentence = pcall(string.format, template, n, other)
		elseif extra == 2 then
			local nearer, further = ...
			if type(nearer) == "table" then
				nearer = word(nearer) or nearer
			end
			if type(further) == "table" then
				further = word(further) or further
			end
			fits, sentence = pcall(string.format, template, n, nearer, further)
		else
			local args = table.pack(...)
			resolve(args, extra)
			fits, sentence = pcall(string.format, template, n, table.unpack(args, 1, extra))
		end
		if fits then
			return sentence
		end
		if misfit ~= nil then
			tell(misfit, key, template, sentence)
		end
		return template
	end

	return {
		get = get,
		count = count,
		data = function(kind: string, id: string, field: string?): string
			return get(Keys.of(kind, id, field))
		end,
		name = name,
		has = function(key: string): boolean
			return router.get(locale, key) ~= key
		end,
		locale = function(): Locale.Locale
			return locale
		end,
		localeId = function(): string
			return localeId
		end,
		isRtl = function(): boolean
			return Locale.isRtl(locale)
		end,
	}
end

return table.freeze(Text)
