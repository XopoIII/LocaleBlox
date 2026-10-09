--!strict
--- The reader's hook: a game is told of a sentence whose arguments did not fit its placeholders.
local serde = require("@lune/serde")

local Label = require("@localeblox/Label")
local Said = require("@localeblox/Said")
local Spec = require("../Spec")
local Text = require("@localeblox/Text")

local TABLES = {
	en = {
		feed = "Feed",
		level = "Lv %d",
		greet = "Hi %s",
		greeting = "Hi %s",
		movedTo = "%s's camp moved to the %s",
		trio = "%s, %s and %s",
		four = "%s, %s, %s and %s",
		minutes = "%d min",
		owned = "%d of %s",
		shared = "%d of %s and %s",
		crowd = "%d of %s, %s and %s",
		pieces = "%d / %d pieces carried off",
		seen = "Seen %*",
	},
	ru = {
		feed = "RU feed",
		movedTo = "RU %s moved to %s",
		pieces = "RU %d of %d flat",
	},
}

local PLURALS = {
	ru = { pieces = { one = "RU %d of %d one", few = "RU %d of %d few", many = "RU %d of %d many" } },
}

-- What the hook was handed, a call a row: the key, the locale, the template and the message.
type Told = { { string } }

local function reader(localeId: string, told: Told): Text.Reader
	return Text.new({
		tables = TABLES,
		plurals = PLURALS,
		localeId = localeId,
		misfit = function(...: any)
			-- Every argument is kept, so one too many would show.
			table.insert(told, { ... })
		end,
	})
end

local SHORT = "missing argument #3"
local function wrong(place: number, wanted: string, got: string): string
	return `invalid argument #{place} to 'format' ({wanted} expected, got {got})`
end

Spec.test("a sentence that does not fit tells its key, the reader's locale, its template and the fault", function()
	local told: Told = {}
	local ru = reader("ru-ru", told)
	Spec.equal(ru.get("movedTo", "Ann"), "RU %s moved to %s")
	Spec.equal(told, { { "movedTo", "ru", "RU %s moved to %s", SHORT } }, "its own table's template")
	Spec.equal(ru.get("level", "many"), "Lv %d")
	Spec.equal(told[2], { "level", "ru", "Lv %d", wrong(2, "number", "string") }, "the English it fell back to")
	Spec.equal(ru.get("%d left", "few"), "%d left")
	Spec.equal(told[3], { "%d left", "ru", "%d left", wrong(2, "number", "string") }, "a key with no text")
	Spec.equal(#told, 3)
end)

Spec.test("every way of calling get tells, whatever the number of arguments", function()
	local told: Told = {}
	local en = reader("en", told)
	Spec.equal(en.get("greet", nil), "Hi %s")
	Spec.equal(en.get("movedTo", "Ann", {}), "%s's camp moved to the %s")
	Spec.equal(en.get("trio", "a", "b", {}), "%s, %s and %s")
	Spec.equal(en.get("four", "a", "b", "c", {}), "%s, %s, %s and %s")
	Spec.equal(told, {
		{ "greet", "en", "Hi %s", wrong(2, "string", "nil") },
		{ "movedTo", "en", "%s's camp moved to the %s", wrong(3, "string", "table") },
		{ "trio", "en", "%s, %s and %s", wrong(4, "string", "table") },
		{ "four", "en", "%s, %s, %s and %s", wrong(5, "string", "table") },
	})
end)

Spec.test("a count its sentence cannot take tells the form that was read", function()
	local told: Told = {}
	local ru = reader("ru", told)
	Spec.equal(ru.count("pieces", 3), "RU %d of %d few")
	Spec.equal(ru.count("owned", 2, {}), "%d of %s")
	Spec.equal(ru.count("shared", 2, "Ann", {}), "%d of %s and %s")
	Spec.equal(ru.count("crowd", 2, "a", "b", {}), "%d of %s, %s and %s")
	Spec.equal(told, {
		{ "pieces", "ru", "RU %d of %d few", SHORT },
		{ "owned", "ru", "%d of %s", wrong(3, "string", "table") },
		{ "shared", "ru", "%d of %s and %s", wrong(4, "string", "table") },
		{ "crowd", "ru", "%d of %s, %s and %s", wrong(5, "string", "table") },
	})
end)

Spec.test("a sentence that fits tells nothing, and neither does a key alone", function()
	local told: Told = {}
	local ru = reader("ru", told)
	Spec.equal(ru.get("feed"), "RU feed")
	Spec.equal(ru.get("level"), "Lv %d", "a template with a placeholder, asked for bare")
	Spec.equal(ru.get("level", 3), "Lv 3")
	Spec.equal(ru.get("movedTo", "Ann", { key = "feed" }), "RU Ann moved to RU feed")
	Spec.equal(ru.get("trio", "a", "b", "c"), "a, b and c")
	Spec.equal(ru.get("four", "a", "b", "c", "d"), "a, b, c and d")
	Spec.equal(ru.get("feed", 1, 2), "RU feed", "arguments a sentence has no place for are no fault")
	Spec.equal(ru.count("minutes", 5), "5 min")
	Spec.equal(ru.count("pieces", 1, 12), "RU 1 of 12 one")
	Spec.equal(ru.count("shared", 2, "Ann", "Bo"), "2 of Ann and Bo")
	Spec.equal(ru.count("crowd", 2, "a", "b", "c"), "2 of a, b and c")
	Spec.equal(ru.data("zone", "nowhere"), "zoneNowhere")
	Spec.equal(ru.has("nothing"), false)
	Spec.equal(told, {})
end)

Spec.test("a reader tells of a key and a template once, however often it is read", function()
	local told: Told = {}
	local ru = reader("ru", told)
	for _ = 1, 3 do
		Spec.equal(ru.get("movedTo", "Ann"), "RU %s moved to %s")
		Spec.equal(ru.get("movedTo", {}, {}), "RU %s moved to %s", "another fault of the same sentence")
		Spec.equal(ru.count("pieces", 3), "RU %d of %d few")
	end
	Spec.equal(told, {
		{ "movedTo", "ru", "RU %s moved to %s", SHORT },
		{ "pieces", "ru", "RU %d of %d few", SHORT },
	})
	Spec.equal(ru.count("pieces", 5), "RU %d of %d many")
	Spec.equal(told[3], { "pieces", "ru", "RU %d of %d many", SHORT }, "another form of a key told before")
	Spec.equal(ru.get("greet", nil), "Hi %s")
	Spec.equal(ru.get("greeting", nil), "Hi %s")
	Spec.equal(told[4], { "greet", "ru", "Hi %s", wrong(2, "string", "nil") })
	Spec.equal(told[5], { "greeting", "ru", "Hi %s", wrong(2, "string", "nil") }, "another key with the same words")
	Spec.equal(ru.get("movedTo", "Ann", "Bo"), "RU Ann moved to Bo", "a fit after a fault reads whole")
	Spec.equal(ru.get("movedTo", "Ann"), "RU %s moved to %s")
	Spec.equal(#told, 5)
end)

Spec.test("each reader tells for itself", function()
	local first: Told, second: Told = {}, {}
	local one, other = reader("ru", first), reader("ru", second)
	Spec.equal(one.get("movedTo", "Ann"), "RU %s moved to %s")
	Spec.equal(other.get("movedTo", "Ann"), "RU %s moved to %s")
	Spec.equal(other.get("movedTo", "Ann"), "RU %s moved to %s")
	Spec.equal(first, { { "movedTo", "ru", "RU %s moved to %s", SHORT } })
	Spec.equal(second, { { "movedTo", "ru", "RU %s moved to %s", SHORT } })
end)

Spec.test("a hook that raises costs the reader nothing, and is not asked again", function()
	local calls = 0
	local text = Text.new({
		tables = TABLES,
		localeId = "en",
		misfit = function()
			calls += 1
			error("the game's reporting is down")
		end,
	})
	Spec.equal(text.get("level", "many"), "Lv %d")
	Spec.equal(text.count("owned", 2), "%d of %s")
	Spec.equal(calls, 2, "it ran for each")
	Spec.equal(text.get("level", "many"), "Lv %d")
	Spec.equal(text.count("owned", 2), "%d of %s")
	Spec.equal(calls, 2)
	Spec.equal(text.get("level", 4), "Lv 4", "and the reader reads on")
end)

Spec.test("a hook that yields does not hold the reader", function()
	local waiting: thread? = nil
	local finished = 0
	local text = Text.new({
		tables = TABLES,
		localeId = "en",
		misfit = function()
			waiting = coroutine.running()
			coroutine.yield()
			finished += 1
		end,
	})
	-- The reader is called from a thread of the spec's own: had the hook's yield reached it, it
	-- would be left suspended with nothing read.
	local read: { string } = {}
	local caller = coroutine.create(function()
		table.insert(read, text.get("level", "many"))
		table.insert(read, text.count("owned", 2))
		table.insert(read, text.get("level", 4))
	end)
	Spec.equal(coroutine.resume(caller), true)
	Spec.equal(coroutine.status(caller), "dead", "the caller ran to its end")
	Spec.equal(read, { "Lv %d", "%d of %s", "Lv 4" })
	Spec.equal(finished, 0, "the hooks are still waiting")
	local thread = waiting :: thread
	Spec.truthy(thread ~= caller and thread ~= coroutine.running(), "the hook has a thread of its own")
	Spec.equal(coroutine.status(thread), "suspended")
	Spec.equal(coroutine.resume(thread), true, "whoever it waited for can wake it")
	Spec.equal(coroutine.status(thread), "dead")
	Spec.equal(finished, 1)
end)

Spec.test("a hook that reads the sentence it was told of is not told again", function()
	local calls = 0
	local inner: { string } = {}
	local text: Text.Reader
	text = Text.new({
		tables = TABLES,
		localeId = "en",
		misfit = function(key: string)
			calls += 1
			table.insert(inner, text.get(key, "many"))
		end,
	})
	Spec.equal(text.get("level", "many"), "Lv %d")
	Spec.equal(calls, 1)
	Spec.equal(inner, { "Lv %d" })
end)

Spec.test("the fault is handed over as text, whatever was raised", function()
	local told: Told = {}
	local en = reader("en", told)
	local broken = setmetatable({}, {
		__tostring = function(): string
			error(42, 0)
		end,
	})
	Spec.equal(en.get("seen", broken), "Seen %*")
	Spec.equal(told, { { "seen", "en", "Seen %*", "42" } })
	Spec.equal(type(told[1][4]), "string", "a number raised is written out")
end)

Spec.test("a label's English and a sentence read for a client tell through their reader", function()
	local said = Said.new({
		encode = function(value: any): string
			return serde.encode("json", value)
		end,
		decode = function(text: string): any
			return serde.decode("json", text)
		end,
	})
	local server: Told, client: Told = {}, {}
	local label = Label.new({ said = said, english = reader("en", server) })
	Spec.equal(label.english("movedTo", { "Ann" }), "%s's camp moved to the %s")
	Spec.equal(label.english("level"), "Lv %d", "no arguments, nothing to fit")
	Spec.equal(label.english("level", {}), "Lv %d")
	Spec.equal(server, { { "movedTo", "en", "%s's camp moved to the %s", SHORT } })
	local ru = reader("ru", client)
	Spec.equal(said.read(ru, said.encode("movedTo", { "Ann" })), "RU %s moved to %s")
	Spec.equal(said.read(ru, said.encode("movedTo", { "Ann", { key = "feed" } })), "RU Ann moved to RU feed")
	Spec.equal(said.read(ru, "not a sentence"), "")
	Spec.equal(client, { { "movedTo", "ru", "RU %s moved to %s", SHORT } })
end)

return nil
