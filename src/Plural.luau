--!strict
--- The CLDR plural category of a whole count, per locale.
---
--- A game's flat tables stay count-neutral; a counted sentence is overlaid with one form per
--- category (`Text.count`). Russian, Ukrainian and Polish have three integer forms, Arabic six,
--- French counts zero with one. A language whose noun does not change with the number (Chinese,
--- Japanese, Korean, Thai, Vietnamese, Malay, Indonesian, Turkish after a numeral) is "other".
local Plural = {}

export type Category = "zero" | "one" | "two" | "few" | "many" | "other"

local function eastSlavic(n: number): Category
	local m10, m100 = n % 10, n % 100
	if m10 == 1 and m100 ~= 11 then
		return "one"
	end
	if m10 >= 2 and m10 <= 4 and not (m100 >= 12 and m100 <= 14) then
		return "few"
	end
	return "many"
end

local function polish(n: number): Category
	if n == 1 then
		return "one"
	end
	local m10, m100 = n % 10, n % 100
	if m10 >= 2 and m10 <= 4 and not (m100 >= 12 and m100 <= 14) then
		return "few"
	end
	return "many"
end

local function arabic(n: number): Category
	if n == 0 then
		return "zero"
	end
	if n == 1 then
		return "one"
	end
	if n == 2 then
		return "two"
	end
	local m100 = n % 100
	if m100 >= 3 and m100 <= 10 then
		return "few"
	end
	if m100 >= 11 then
		return "many"
	end
	return "other"
end

-- The languages where only a count of exactly one differs from the rest.
local ONE_OTHER: { [string]: boolean } = {
	en = true,
	de = true,
	nl = true,
	es = true,
	["es-ES"] = true,
	pt = true,
	["pt-PT"] = true,
	it = true,
	hi = true,
	fil = true,
}

--> The category of `n` in `locale`. A fractional count is always "other": by CLDR a fraction
--> agrees with no noun ("1.5 pieces", never "1.5 piece"). A whole count is taken unsigned.
function Plural.category(locale: string, n: number): Category
	if n % 1 ~= 0 then
		return "other"
	end
	local count = math.abs(n)
	if locale == "ru" or locale == "uk" then
		return eastSlavic(count)
	elseif locale == "pl" then
		return polish(count)
	elseif locale == "ar" then
		return arabic(count)
	elseif locale == "fr" or locale == "fr-CA" then
		return if count == 0 or count == 1 then "one" else "other"
	elseif ONE_OTHER[locale] then
		return if count == 1 then "one" else "other"
	end
	return "other"
end

return table.freeze(Plural)
