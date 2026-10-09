--!strict
--- The text key of a piece of game data.
---
--- A game's data keeps its own names as logic keys (a food's id, a product's key); what the player
--- reads is looked up by a key built from them:
---
---     Keys.of("food", "sugar_cube")            --> "foodSugarCube"
---     Keys.of("product", "double_pay", "blurb")  --> "productDoublePayBlurb"
local Keys = {}

-- "double_pay" -> "DoublePay", "Half-Moon" -> "HalfMoon", "sea king" -> "SeaKing".
local function pascal(name: string): string
	local out = string.gsub(name, "[^%w]+(%w)", string.upper)
	out = string.gsub(out, "[^%w]", "")
	return (string.gsub(out, "^%l", string.upper))
end

--> The key for `name` of `kind`, and for one `field` of it when given.
function Keys.of(kind: string, name: string, field: string?): string
	local key = kind .. pascal(name)
	if field ~= nil then
		key ..= pascal(field)
	end
	return key
end

return table.freeze(Keys)
