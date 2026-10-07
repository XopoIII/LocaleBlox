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

Spec.test("a table's type may be any type written on its opening line, or none", function()
	const source = table.concat({
		"local names: { [string]: string } = {",
		'\tGoldbun = "RU goldbun",',
		"}",
		"const plain = {",
		'\ta = "1",',
		"}",
		"local dotted: Locale.Table = {",
		'\tb = "2",',
		"}",
		"local generic: Map<string, string> = {",
		'\tc = "3",',
		"}",
	}, "\n")
	const out: Parse.Locales = {}
	Parse.source(source, out, { names = "ru" })
	Spec.equal(out, {
		ru = { Goldbun = "RU goldbun" },
		plain = { a = "1" },
		dotted = { b = "2" },
		generic = { c = "3" },
	})
end)

Spec.test("only a line that declares one table and opens it is an opening", function()
	Spec.equal(Parse.opens("local en: Table = {"), "en")
	Spec.equal(Parse.opens("const en = {"), "en")
	Spec.equal(Parse.opens("local  en  :  { [string]: string }  =  {  "), "en", "spaces do not matter")
	Spec.equal(Parse.opens("local en: Table = {}"), nil, "opened and closed at once")
	Spec.equal(Parse.opens("local en: Table = other"), nil, "not a table")
	Spec.equal(Parse.opens("local a, b = {"), nil, "two names")
	Spec.equal(Parse.opens("local en: Table = f() == {"), nil, "a comparison is not a declaration")
	Spec.equal(Parse.opens("\tlocal en = {"), nil, "indented: not at the top")
	Spec.equal(Parse.opens("localen = {"), nil, "local is a word")
	Spec.equal(Parse.opens("constant = {"), nil, "const is a word")
	Spec.equal(Parse.opens("en = {"), nil, "an assignment declares nothing")
end)

return nil
