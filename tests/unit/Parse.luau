--!strict
--- Tables read out of a Luau source as text.
const Parse = require("@localeblox/Parse")
const Spec = require("../Spec")

const SOURCE = table.concat({
	"--!strict",
	"type Table = { [string]: string }",
	"",
	"local en: Table = {",
	"\t-- a comment",
	'\tfeed = "Feed",',
	'\tlevel = "Lv %d",',
	'\tquoted = "say \\"hi\\", now",',
	"}",
	"",
	'\tstray = "outside any table",',
	"const zhHans: Locale.Table = {",
	'\tfeed = "ZH feed",',
	"}",
	"local helper = {",
	'\tnested = { "not a string value" },',
	"}",
	"return { en = en, zhHans = zhHans }",
}, "\n")

Spec.test("every table of a source is read, one key a line", function()
	const out: Parse.Locales = {}
	Parse.source(SOURCE, out)
	Spec.equal(out, {
		en = { feed = "Feed", level = "Lv %d", quoted = 'say \\"hi\\", now' },
		zhHans = { feed = "ZH feed" },
		helper = {},
	})
end)

Spec.test("an alias renames a table to its locale code", function()
	const out: Parse.Locales = {}
	Parse.source(SOURCE, out, { zhHans = "zh-hans" })
	Spec.equal(out["zh-hans"], { feed = "ZH feed" })
	Spec.equal(out.zhHans, nil)
end)

Spec.test("two sources add up, and Windows line ends are read", function()
	const out: Parse.Locales = {}
	Parse.source('local en = {\r\n\tfeed = "Feed",\r\n}\r\n', out)
	Parse.source('local en = {\n\tclose = "Close",\n}\nlocal ru = {\n\tfeed = "RU",\n}', out)
	Spec.equal(out, { en = { feed = "Feed", close = "Close" }, ru = { feed = "RU" } })
end)

Spec.test("specifiers are read in order, and an escaped percent is not one", function()
	Spec.equal(Parse.specifiers("%d / %d pieces"), { "%d", "%d" })
	Spec.equal(Parse.specifiers("%s moved to %s in %.2f s"), { "%s", "%s", "%.2f" })
	Spec.equal(Parse.specifiers("100%% done"), {})
	Spec.equal(Parse.specifiers("%d%% of %s"), { "%d", "%s" })
	Spec.equal(Parse.specifiers("Feed"), {})
end)

return nil
