--!strict
--- Every string is whole and in its own script.
local Locale = require("@localeblox/Locale")
local Spec = require("../Spec")
local Written = require("@localeblox/Written")

local CYRILLIC = utf8.char(0x416, 0x443, 0x43A)
local ARABIC = utf8.char(0x646, 0x645, 0x644)
local THAI = utf8.char(0xE21, 0xE14)
local KANA = utf8.char(0x30A2, 0x30EA)
local HAN = utf8.char(0x86C1)
local HANGUL = utf8.char(0xAC1C, 0xBBF8)
local DEVANAGARI = utf8.char(0x91A, 0x940)
local E_ACUTE = utf8.char(0xE9)

Spec.test("each script in its own table is clean", function()
	Spec.equal(
		Written.check({
			en = { a = "Feed" },
			de = { a = "F" .. utf8.char(0xFC) .. "ttern" },
			fr = { a = "Ferm" .. E_ACUTE },
			ru = { a = CYRILLIC },
			uk = { a = CYRILLIC },
			ar = { a = ARABIC },
			th = { a = THAI },
			ja = { a = KANA },
			ko = { a = HANGUL },
			hi = { a = DEVANAGARI },
			["zh-hant"] = { a = HAN },
			["zh-hans"] = { a = HAN },
		}),
		{}
	)
	Spec.equal(Written.one("ja", "ja.a", HAN), {}, "kanji alone is Japanese")
end)

Spec.test("a string left in English is found in a table of another script", function()
	Spec.equal(Written.one("ru", "ru.a", "Feed"), { "ru.a: no cyrillic letter (untranslated?)" })
	Spec.equal(Written.one("ja", "ja.a", "Feed"), { "ja.a: no kana/han letter (untranslated?)" })
	Spec.equal(Written.one("th", "th.a", CYRILLIC), { "th.a: no thai letter (untranslated?)" })
	Spec.equal(Written.one("ru", "ru.a", CYRILLIC .. " Feed"), {}, "mixed is allowed outside Arabic")
end)

Spec.test("another script in a Latin-script table is found", function()
	Spec.equal(Written.one("de", "de.a", CYRILLIC), { "de.a: cyrillic letters in a Latin-script table" })
	Spec.equal(Written.one("pt-PT", "pt-PT.a", "Feed " .. HAN), { "pt-PT.a: han letters in a Latin-script table" })
end)

Spec.test("English is checked for encoding only", function()
	Spec.equal(Written.one("en", "en.a", CYRILLIC), {})
end)

Spec.test("a string with no letters is clean anywhere", function()
	Spec.equal(Written.one("ru", "ru.a", "%d / %d"), {})
	Spec.equal(Written.one("ar", "ar.a", "12:00"), {})
	Spec.equal(Written.one("ja", "ja.a", "x2"), {}, "a multiplier is kept")
	Spec.equal(Written.one("ru", "ru.a", "x%s R$ Robux Roblox %s"), {}, "the tokens kept everywhere")
end)

Spec.test("a specifier is the one the lint reads, not any letter after a percent", function()
	Spec.equal(Written.one("ar", "ar.a", ARABIC .. " 50% Robux"), {}, "a percent of plain text takes no letter")
	Spec.equal(Written.one("ru", "ru.a", CYRILLIC .. " 50% Roblox"), {})
	Spec.equal(
		Written.one("ar", "ar.a", ARABIC .. " %p"),
		{ "ar.a: Latin words inside right-to-left text" },
		"string.format has no %p: the letter is a letter"
	)
	Spec.equal(Written.one("ar", "ar.a", ARABIC .. " %* %5.1f %-3d %q"), {}, "every conversion it has is kept")
	Spec.equal(Written.one("ar", "ar.a", ARABIC .. " x%*"), {}, "a multiplier takes any specifier the lint reads")
	Spec.equal(Written.one("ar", "ar.a", ARABIC .. " x%.1f"), {})
end)

Spec.test("Arabic starts with an Arabic letter and holds no Latin word", function()
	Spec.equal(Written.one("ar", "ar.a", ARABIC .. " %d"), {})
	Spec.equal(Written.one("ar", "ar.a", "%d " .. ARABIC), {}, "a number may lead")
	Spec.equal(Written.one("ar", "ar.a", "Lv " .. ARABIC), {
		"ar.a: does not start with an Arabic letter, it would read left to right",
		"ar.a: Latin words inside right-to-left text",
	})
	Spec.equal(Written.one("ar", "ar.a", ARABIC .. " Lv"), { "ar.a: Latin words inside right-to-left text" })
	Spec.equal(Written.one("ar", "ar.a", ARABIC .. " Robux"), {}, "a kept token is not a Latin word")
end)

Spec.test("a game names the Latin it keeps on purpose", function()
	Spec.equal(Written.one("ar", "ar.a", ARABIC .. " MAX"), { "ar.a: Latin words inside right-to-left text" })
	Spec.equal(Written.one("ar", "ar.a", ARABIC .. " MAX", { keep = { "MAX" } }), {})
	Spec.equal(Written.one("ru", "ru.a", "MAX", { keep = { "MAX" } }), {}, "nothing left to judge")
	Spec.equal(Written.one("ru", "ru.a", "MAX"), { "ru.a: no cyrillic letter (untranslated?)" })
end)

Spec.test("broken encoding is found", function()
	Spec.equal(Written.one("en", "en.a", "a\255b"), { "en.a: not valid UTF-8" })
	Spec.equal(Written.one("en", "en.a", "a" .. utf8.char(0xFFFD)), { "en.a: U+FFFD, a glyph was lost on the way in" })
	Spec.equal(Written.one("en", "en.a", "a\tb"), { "en.a: control character U+0009" })
	Spec.equal(Written.one("fr", "fr.a", "e" .. utf8.char(0x301)), {
		"fr.a: combining accent U+0301, write the precomposed letter",
	})
	Spec.equal(Written.one("fr", "fr.a", E_ACUTE), {}, "the precomposed letter is fine")
end)

Spec.test("tables keyed by a locale type are checked as tables keyed by a string are", function()
	local tables: Locale.Tables = { en = { a = "Feed" }, ru = { a = "Feed" } }
	Spec.equal(Written.check(tables), { "ru.a: no cyrillic letter (untranslated?)" })
end)

Spec.test("check names every string of every locale, sorted", function()
	Spec.equal(
		Written.check({
			en = { a = "Feed" },
			ru = { z = "Feed", m = "Feed", a = "Feed", q = "Feed", c = "Feed" },
			th = { k = "Feed", b = "Feed" },
			de = { a = CYRILLIC },
		}),
		{
			"de.a: cyrillic letters in a Latin-script table",
			"ru.a: no cyrillic letter (untranslated?)",
			"ru.c: no cyrillic letter (untranslated?)",
			"ru.m: no cyrillic letter (untranslated?)",
			"ru.q: no cyrillic letter (untranslated?)",
			"ru.z: no cyrillic letter (untranslated?)",
			"th.b: no thai letter (untranslated?)",
			"th.k: no thai letter (untranslated?)",
		}
	)
end)

return nil
