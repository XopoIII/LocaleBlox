--!strict
--- The code and the English table name the same keys.
local Spec = require("../Spec")
local Usage = require("@localeblox/Usage")

local EN = { feedButton = "Feed", closeButton = "Close", foodSugar = "Sugar", foodCake = "Cake" }
local THREE = 'get("feedButton") get("closeButton") get("foodSugar")'
local ALL = THREE .. ' get("foodCake")'

Spec.test("code that names exactly the keys is clean", function()
	Spec.equal(
		Usage.check(EN, {
			{ path = "a.luau", text = 'text.get("feedButton")\nlocal other = "notAKey"\nlocal plain = "feed"' },
			{ path = "b.luau", text = 'text.get("closeButton") text.get("foodSugar") text.get("foodCake")' },
		}),
		{}
	)
end)

Spec.test("a key may stand in single quotes or a backtick string", function()
	Spec.equal(
		Usage.check(EN, {
			{ path = "a.luau", text = "get('feedButton') get(`closeButton`) get(`foodSugar`) get(\"foodCake\")" },
		}),
		{}
	)
	Spec.equal(Usage.check(EN, { { path = "a.luau", text = ALL .. " get('feedButon') get(`foodPie`)" } }), {
		'a.luau: "feedButon" looks like a text key, and English has none',
		'a.luau: "foodPie" looks like a text key, and English has none',
	}, "and is judged there as in double quotes")
	Spec.equal(
		Usage.check(EN, { { path = "a.luau", text = THREE .. " x = \"foodCake' y = 'feedButon` z = `feedBadge\"" } }),
		{ "en.foodCake: no code uses this key" },
		"a literal closes with the quote that opened it"
	)
end)

Spec.test("a comment is not code: a name in one is neither judged nor a use", function()
	local line = ALL .. " -- see `feedButon`, 'feedBadge' and \"feedOther\"\n"
	Spec.equal(Usage.check(EN, { { path = "a.luau", text = line } }), {})
	Spec.equal(Usage.check(EN, { { path = "a.luau", text = "--- Re-exports `feedState`.\n" .. ALL } }), {})
	Spec.equal(Usage.check(EN, { { path = "a.luau", text = ALL .. "\n-- `feedLast`" } }), {}, "no line end after it")
	Spec.equal(
		Usage.check(EN, { { path = "a.luau", text = THREE .. ' -- get("foodCake")\n' } }),
		{ "en.foodCake: no code uses this key" },
		"a key only a comment names is unused"
	)
	Spec.equal(
		Usage.check(EN, { { path = "a.luau", text = THREE .. ' -- soon\nget("foodCake") get("feedButon")' } }),
		{ 'a.luau: "feedButon" looks like a text key, and English has none' },
		"the line after a comment is code again"
	)
	Spec.equal(
		Usage.check(EN, { { path = "a.luau", text = THREE .. ' x = a - b get("foodCake") y = -1 get("feedButon")' } }),
		{ 'a.luau: "feedButon" looks like a text key, and English has none' },
		"one dash is a minus"
	)
end)

Spec.test("a block comment is not code, to its own closing bracket", function()
	Spec.equal(
		Usage.check(EN, {
			{ path = "a.luau", text = THREE .. ' --[[ "feedButon"\n `feedBadge` ]] get("foodCake") get("feedLast")' },
		}),
		{ 'a.luau: "feedLast" looks like a text key, and English has none' }
	)
	Spec.equal(
		Usage.check(EN, {
			{
				path = "a.luau",
				text = THREE .. ' --[==[ "feedButon" ]] `feedBadge` ]==] get("foodCake") get("feedLast")',
			},
		}),
		{ 'a.luau: "feedLast" looks like a text key, and English has none' },
		"a levelled block closes at its own level"
	)
	Spec.equal(
		Usage.check(EN, { { path = "a.luau", text = THREE .. ' --[[ never closed\n get("foodCake") "feedButon"' } }),
		{ "en.foodCake: no code uses this key" },
		"one never closed runs to the end"
	)
	Spec.equal(
		Usage.check(EN, { { path = "a.luau", text = THREE .. ' --[ "feedButon" ]]\nget("foodCake")' } }),
		{},
		"one bracket opens no block: the comment ends with its line"
	)
end)

Spec.test("two dashes inside a string open no comment", function()
	Spec.equal(
		Usage.check(EN, { { path = "a.luau", text = THREE .. ' local dash = "--" get("foodCake") get("feedButon")' } }),
		{ 'a.luau: "feedButon" looks like a text key, and English has none' },
		"two dashes inside a quoted string open no comment"
	)
	Spec.equal(
		Usage.check(EN, { { path = "a.luau", text = THREE .. " local dash = '--' get('foodCake')" } }),
		{},
		"in single quotes"
	)
	Spec.equal(
		Usage.check(EN, { { path = "a.luau", text = THREE .. " local dash = `a\n--{x}` get('foodCake')" } }),
		{},
		"a backtick string runs over a line end"
	)
	Spec.equal(
		Usage.check(EN, { { path = "a.luau", text = THREE .. ' local dash = [[ -- ]] get("foodCake")' } }),
		{},
		"two dashes inside a long string open no comment"
	)
	Spec.equal(
		Usage.check(EN, { { path = "a.luau", text = THREE .. ' local dash = [=[ ]] -- ]=] get("foodCake")' } }),
		{},
		"a levelled long string closes at its own level"
	)
	Spec.equal(
		Usage.check(EN, { { path = "a.luau", text = THREE .. ' local t = x[1] -- "feedButon"\nget("foodCake")' } }),
		{},
		"an index is no long string"
	)
	Spec.equal(
		Usage.check(EN, { { path = "a.luau", text = THREE .. ' local say = "a\\"--" get("foodCake")' } }),
		{},
		"an escaped quote closes no string"
	)
	Spec.equal(
		Usage.check(EN, { { path = "a.luau", text = THREE .. ' local say = "a\\\\" -- "feedButon"\nget("foodCake")' } }),
		{},
		"an escaped backslash escapes nothing after it"
	)
	Spec.equal(
		Usage.check(EN, { { path = "a.luau", text = THREE .. " local it's = 1\n-- `feedButon`\nget('foodCake')" } }),
		{},
		"an unclosed quote ends with its line"
	)
	Spec.equal(
		Usage.check(EN, { { path = "a.luau", text = THREE .. ' local open = "\n-- `feedButon`\nget("foodCake")' } }),
		{},
		"an unclosed double quote ends with its line"
	)
	Spec.equal(
		Usage.check(
			EN,
			{ { path = "a.luau", text = THREE .. ' get("foodCake") x = "--[[" get("feedButon") y = "]]"' } }
		),
		{ 'a.luau: "feedButon" looks like a text key, and English has none' },
		"nor a block"
	)
end)

Spec.test("a key-shaped literal that English lacks is named with its file", function()
	Spec.equal(
		Usage.check(EN, {
			{ path = "a.luau", text = 'get("feedButton") get("closeButton") get("foodSugar") get("foodCake")' },
			{ path = "b.luau", text = 'get("feedButon")' },
		}),
		{ 'b.luau: "feedButon" looks like a text key, and English has none' }
	)
end)

Spec.test("an English key no code names is unused", function()
	Spec.equal(
		Usage.check(EN, { { path = "a.luau", text = 'get("feedButton") get("closeButton") get("foodSugar")' } }),
		{
			"en.foodCake: no code uses this key",
		}
	)
end)

Spec.test("keys built from game data are left to the game", function()
	Spec.equal(
		Usage.check(EN, { { path = "a.luau", text = 'get("feedButton") get("closeButton") Keys.of("food", id)' } }, {
			data = { "food" },
		}),
		{}
	)
	Spec.equal(
		Usage.check(EN, { { path = "a.luau", text = 'get("feedButton") get("closeButton") get("foodPie")' } }, {
			data = { "food" },
		}),
		{},
		"a literal of a data kind is not judged"
	)
end)

return nil
