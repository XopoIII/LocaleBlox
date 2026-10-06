--!strict
--- The CLDR plural category of a whole count, per locale.
---
--- A game's flat tables stay count-neutral; a counted sentence is overlaid with one form per
--- category (`Text.count`). Russian, Ukrainian and Polish have three integer forms, Arabic six,
--- French counts zero with one. A language whose noun does not change with the number (Chinese,
--- Japanese, Korean, Thai, Vietnamese, Malay, Indonesian, Turkish after a numeral) is "other".
const Plural = {}

export type Category = "zero" | "one" | "two" | "few" | "many" | "other"

const function eastSlavic(n: number): Category
	const m10, m100 = n % 10, n % 100
	if m10 == 1 and m100 ~= 11 then
		return "one"
	end
	if m10 >= 2 and m10 <= 4 and not (m100 >= 12 and m100 <= 14) then
		return "few"
	end
	return "many"
end

const function polish(n: number): Category
	if n == 1 then
		return "one"
	end
	const m10, m100 = n % 10, n % 100
	if m10 >= 2 and m10 <= 4 and not (m100 >= 12 and m100 <= 14) then
		return "few"
	end
	return "many"
end

const function arabic(n: number): Category
	if n == 0 then
		return "zero"
	end
	if n == 1 then
		return "one"
	end
	if n == 2 then
		return "two"
	end
	const m100 = n % 100
	if m100 >= 3 and m100 <= 10 then
		return "few"
	end
	if m100 >= 11 then
		return "many"
	end
	return "other"
end

-- The languages where only a count of exactly one differs from the rest.
const ONE_OTHER: { [string]: boolean } = {
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

--> The category of `n` in `locale`. `n` is taken as a whole, non-negative number.
function Plural.category(locale: string, n: number): Category
	const count = math.floor(math.abs(n))
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

return Plural
