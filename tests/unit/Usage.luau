--!strict
--- The code and the English table name the same keys.
const Spec = require("../Spec")
const Usage = require("@localeblox/Usage")

const EN = { feedButton = "Feed", closeButton = "Close", foodSugar = "Sugar", foodCake = "Cake" }

Spec.test("code that names exactly the keys is clean", function()
	Spec.equal(
		Usage.check(EN, {
			{ path = "a.luau", text = 'text.get("feedButton")\nlocal other = "notAKey"\nlocal plain = "feed"' },
			{ path = "b.luau", text = 'text.get("closeButton") text.get("foodSugar") text.get("foodCake")' },
		}),
		{}
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
