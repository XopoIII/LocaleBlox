--!strict
--- Which table a LocaleId reads, and the lookup's fallbacks.
const Locale = require("@localeblox/Locale")
const Spec = require("../Spec")

Spec.test("a region collapses onto its language", function()
	Spec.equal(Locale.localeFor("en-us"), "en")
	Spec.equal(Locale.localeFor("ru-ru"), "ru")
	Spec.equal(Locale.localeFor("pt-br"), "pt")
	Spec.equal(Locale.localeFor("es-mx"), "es")
	Spec.equal(Locale.localeFor("fil-ph"), "fil")
	Spec.equal(Locale.localeFor("de"), "de")
	Spec.equal(Locale.localeFor("JA-JP"), "ja", "case does not matter")
	Spec.equal(Locale.localeFor("ko_kr"), "ko", "nor the separator")
end)

Spec.test("Belarusian and Kazakh read Russian, Tagalog reads Filipino, Ukrainian its own", function()
	Spec.equal(Locale.localeFor("be-by"), "ru")
	Spec.equal(Locale.localeFor("kk-kz"), "ru")
	Spec.equal(Locale.localeFor("tl"), "fil")
	Spec.equal(Locale.localeFor("uk-ua"), "uk")
end)

Spec.test("the three regional tables are kept apart from their defaults", function()
	Spec.equal(Locale.localeFor("es-es"), "es-ES")
	Spec.equal(Locale.localeFor("es-419"), "es")
	Spec.equal(Locale.localeFor("pt-pt"), "pt-PT")
	Spec.equal(Locale.localeFor("pt"), "pt")
	Spec.equal(Locale.localeFor("fr-ca"), "fr-CA")
	Spec.equal(Locale.localeFor("fr-fr"), "fr")
end)

Spec.test("Chinese is routed by script, and a bare tag reads Simplified", function()
	Spec.equal(Locale.localeFor("zh-hant"), "zh-hant")
	Spec.equal(Locale.localeFor("zh-tw"), "zh-hant")
	Spec.equal(Locale.localeFor("zh-hk"), "zh-hant")
	Spec.equal(Locale.localeFor("zh-mo"), "zh-hant")
	Spec.equal(Locale.localeFor("zh-cn"), "zh-hans")
	Spec.equal(Locale.localeFor("zh-hans"), "zh-hans")
	Spec.equal(Locale.localeFor("zh-sg"), "zh-hans")
	Spec.equal(Locale.localeFor("zh"), "zh-hans")
end)

Spec.test("anything unknown reads English", function()
	Spec.equal(Locale.localeFor(""), "en")
	Spec.equal(Locale.localeFor("sv-se"), "en")
	Spec.equal(Locale.localeFor("123"), "en")
	Spec.equal(Locale.localeFor("zz"), "en")
end)

Spec.test("every locale routes to itself, and there are twenty-five", function()
	Spec.equal(#Locale.ALL, 25)
	const seen: { [string]: boolean } = {}
	for _, locale in Locale.ALL do
		Spec.equal(Locale.localeFor(locale), locale, locale)
		Spec.equal(seen[locale], nil, `{locale} listed once`)
		seen[locale] = true
	end
end)

Spec.test("only Arabic is written right to left", function()
	for _, locale in Locale.ALL do
		Spec.equal(Locale.isRtl(locale), locale == "ar", locale)
	end
	Spec.equal(Locale.isRtl("he"), false)
end)

Spec.test("a lookup falls back from the locale to English to the key", function()
	const router = Locale.router({
		en = { feed = "Feed", close = "Close" },
		ru = { feed = "RU feed" },
	})
	Spec.equal(router.get("ru", "feed"), "RU feed", "its own")
	Spec.equal(router.get("ru", "close"), "Close", "a key the locale lacks")
	Spec.equal(router.get("de", "feed"), "Feed", "a locale with no table")
	Spec.equal(router.get("ru", "nothing"), "nothing", "a key nobody has")
	Spec.equal(router.get("en", "nothing"), "nothing")
end)

Spec.test("keys and populated are sorted and say only what is shipped", function()
	const router = Locale.router({
		ru = { feed = "RU feed" },
		en = { feed = "Feed", close = "Close", away = "Away" },
	})
	Spec.equal(router.keys("en"), { "away", "close", "feed" })
	Spec.equal(router.keys("ru"), { "feed" })
	Spec.equal(router.keys("de"), {})
	Spec.equal(router.populated(), { "en", "ru" })
	Spec.equal(router.localeFor("be"), "ru")
end)

Spec.test("tables without English are refused", function()
	Spec.throws(function()
		Locale.router({ ru = { feed = "RU feed" } })
	end, "no English table")
end)

return nil
