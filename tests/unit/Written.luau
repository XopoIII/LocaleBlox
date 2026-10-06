--!strict
--- Every string is whole and in its own script.
const Spec = require("../Spec")
const Written = require("@localeblox/Written")

const CYRILLIC = utf8.char(0x416, 0x443, 0x43A)
const ARABIC = utf8.char(0x646, 0x645, 0x644)
const THAI = utf8.char(0xE21, 0xE14)
const KANA = utf8.char(0x30A2, 0x30EA)
const HAN = utf8.char(0x86C1)
const HANGUL = utf8.char(0xAC1C, 0xBBF8)
const DEVANAGARI = utf8.char(0x91A, 0x940)
const E_ACUTE = utf8.char(0xE9)

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
