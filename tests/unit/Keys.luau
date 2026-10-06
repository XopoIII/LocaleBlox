--!strict
--- The text key of a piece of game data.
const Keys = require("@localeblox/Keys")
const Spec = require("../Spec")

Spec.test("a kind and a name make a camel-cased key", function()
	Spec.equal(Keys.of("food", "sugar"), "foodSugar")
	Spec.equal(Keys.of("food", "sugar_cube"), "foodSugarCube")
	Spec.equal(Keys.of("rank", "Maw-Touched"), "rankMawTouched")
	Spec.equal(Keys.of("rank", "pit lord"), "rankPitLord")
	Spec.equal(Keys.of("food", "jack-o'-lantern"), "foodJackOLantern")
	Spec.equal(Keys.of("world", "World2"), "worldWorld2")
	Spec.equal(Keys.of("food", "sugar!"), "foodSugar", "a trailing mark is dropped")
end)

Spec.test("a field is added the same way, and only when given", function()
	Spec.equal(Keys.of("product", "pay_rush", "blurb"), "productPayRushBlurb")
	Spec.equal(Keys.of("upgrade", "speed", "hint"), "upgradeSpeedHint")
	Spec.equal(Keys.of("upgrade", "speed"), "upgradeSpeed")
end)

return nil
