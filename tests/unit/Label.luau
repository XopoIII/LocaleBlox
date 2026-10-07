--!strict
--- A server's text on an instance, written as a sentence, and the client's rewrite of it.
const serde = require("@lune/serde")

const Label = require("@localeblox/Label")
const Localize = require("@localeblox/Localize")
const Said = require("@localeblox/Said")
const Spec = require("../Spec")
const Text = require("@localeblox/Text")
const World = require("../fakes/World")

const said = Said.new({
	encode = function(value: any): string
		return serde.encode("json", value)
	end,
	decode = function(text: string): any
		return serde.decode("json", text)
	end,
})

const TABLES = {
	en = { priceOf = "%s costs %s", open = "Open", zoneHarbour = "Harbour", level = "Lv %d" },
	ru = { priceOf = "RU %s costs %s", open = "RU open", zoneHarbour = "RU harbour", level = "RU lv %d" },
}
const PETS = { ru = { Goldbun = "RU goldbun" } }
const english = Text.new({ tables = TABLES, names = { pet = PETS }, localeId = "en" })
const russian = Text.new({ tables = TABLES, names = { pet = PETS }, localeId = "ru" })

const function labels(): Label.Label
	return Label.new({ said = said, english = english })
end

Spec.test("a label writes the English, the sentence in an attribute, and the tag", function()
	const world = World.new()
	const sign = world.instance({ Text = "", Name = "Sign" })
	const label = labels()
	label.set(sign, "Text", "priceOf", { { pet = "Goldbun" }, "12K" })
	Spec.equal(sign.Text, "Goldbun costs 12K", "English, the name as its id")
	Spec.equal(sign:GetAttribute("Said_Text"), said.encode("priceOf", { { pet = "Goldbun" }, "12K" }))
	Spec.equal(sign:HasTag("Localized"), true)
	Spec.equal({ label.tag, label.prefix }, { "Localized", "Said_" }, "the defaults")
	Spec.equal({ Label.TAG, Label.PREFIX }, { "Localized", "Said_" })
end)

Spec.test("a sentence with no arguments is its template, and a key argument is looked up", function()
	const label = labels()
	Spec.equal(label.english("open"), "Open")
	Spec.equal(label.english("open", {}), "Open")
	Spec.equal(label.english("level"), "Lv %d", "a template with no arguments is as written")
	Spec.equal(label.english("priceOf", { { key = "zoneHarbour" }, "5" }), "Harbour costs 5")
	Spec.equal(label.english("level", { 7 }), "Lv 7")
end)

Spec.test("a sentence whose arguments do not fit reads as its template, and raises nothing", function()
	const label = labels()
	Spec.equal(label.english("level", { "seven" }), "Lv %d", "text where a number belongs")
	Spec.equal(label.english("priceOf", { "one" }), "%s costs %s", "an argument short")
	Spec.equal(label.english("priceOf", { { unknown = "x" }, "5" }), "%s costs %s", "a table no reader knows")
end)

Spec.test("setting the same sentence again does nothing", function()
	const world = World.new()
	const sign = world.instance({ Text = "" })
	const label = labels()
	local changes = 0
	sign.AttributeChanged:Connect(function()
		changes += 1
	end)
	label.set(sign, "Text", "open")
	Spec.equal(changes, 1)
	-- Somebody wrote over the property; the same sentence must not write it back.
	sign.Text = "scribbled"
	label.set(sign, "Text", "open")
	Spec.equal(changes, 1, "the attribute was not set again")
	Spec.equal(sign.Text, "scribbled", "nor the property")
	label.set(sign, "Text", "level", { 3 })
	Spec.equal(changes, 2, "a new sentence is")
	Spec.equal(sign.Text, "Lv 3")
end)

Spec.test("plain text drops the sentence its property carried", function()
	const world = World.new()
	const sign = world.instance({ Text = "", Hint = "" })
	const label = labels()
	label.set(sign, "Text", "open")
	label.set(sign, "Hint", "level", { 2 })
	label.plain(sign, "Text", "1,250")
	Spec.equal(sign.Text, "1,250")
	Spec.equal(sign:GetAttribute("Said_Text"), nil, "the sentence is gone")
	Spec.equal(sign:GetAttribute("Said_Hint"), said.encode("level", { 2 }), "the other property keeps its own")
end)

Spec.test("a game's own tag and prefix are used on both sides", function()
	const world = World.new()
	const sign = world.instance({ Text = "" })
	const label = Label.new({ said = said, english = english, tag = "Worded", prefix = "Line_" })
	label.set(sign, "Text", "open")
	Spec.equal(sign:HasTag("Worded"), true)
	Spec.equal(sign:HasTag("Localized"), false)
	Spec.equal(sign:GetAttribute("Line_Text"), said.encode("open"))
	Spec.equal(sign:GetAttribute("Said_Text"), nil)
	Localize.start({ said = said, text = russian, collection = world.collection, tag = "Worded", prefix = "Line_" })
	Spec.equal(sign.Text, "RU open")
end)

Spec.test("the client rewrites what is there and what comes, in its own language", function()
	const world = World.new()
	const label = labels()
	const before = world.instance({ Text = "" })
	label.set(before, "Text", "priceOf", { { pet = "Goldbun" }, "12K" })
	Localize.start({ said = said, text = russian, collection = world.collection })
	Spec.equal(before.Text, "RU RU goldbun costs 12K", "an instance tagged before the client ran")
	const after = world.instance({ Text = "", ActionText = "" })
	label.set(after, "Text", "open")
	label.set(after, "ActionText", "level", { 4 })
	Spec.equal(after.Text, "RU open", "an instance tagged later")
	Spec.equal(after.ActionText, "RU lv 4", "a second property of it")
end)

Spec.test("the server saying something new is drawn anew", function()
	const world = World.new()
	const label = labels()
	const sign = world.instance({ Text = "" })
	Localize.start({ said = said, text = russian, collection = world.collection })
	label.set(sign, "Text", "open")
	Spec.equal(sign.Text, "RU open")
	label.set(sign, "Text", "level", { 9 })
	Spec.equal(sign.Text, "RU lv 9")
end)

Spec.test("the server's English landing after its attribute is put back into the reader's language", function()
	const world = World.new()
	const sign = world.instance({ Text = "" })
	Localize.start({ said = said, text = russian, collection = world.collection })
	labels().set(sign, "Text", "open")
	-- Replication may deliver the property after the attribute.
	sign.Text = "Open"
	Spec.equal(sign.Text, "RU open")
end)

Spec.test("plain text is left alone by the client", function()
	const world = World.new()
	const label = labels()
	const sign = world.instance({ Text = "" })
	Localize.start({ said = said, text = russian, collection = world.collection })
	label.set(sign, "Text", "open")
	label.plain(sign, "Text", "1,250")
	Spec.equal(sign.Text, "1,250")
end)

Spec.test("an attribute that is no sentence, or names no property, costs nothing", function()
	const world = World.new()
	const sign = world.instance({ Text = "kept" })
	Localize.start({ said = said, text = russian, collection = world.collection })
	sign:SetAttribute("Said_Text", "not a sentence")
	sign:SetAttribute("Said_Missing", said.encode("open"))
	sign:SetAttribute("Colour", "red")
	sign:AddTag("Localized")
	Spec.equal(sign.Text, "kept", "nothing was written")
	sign:SetAttribute("Said_Text", said.encode("open"))
	Spec.equal(sign.Text, "RU open", "and the instance is still followed")
	-- A sentence under another prefix is not this client's to draw, whatever property its name ends in.
	sign:SetAttribute("Note_Text", said.encode("level", { 5 }))
	Spec.equal(sign.Text, "RU open", "another prefix is not read")
end)

Spec.test("an instance is watched once, and forgotten when it is destroyed", function()
	const world = World.new()
	const sign = world.instance({ Text = "" })
	Localize.start({ said = said, text = russian, collection = world.collection })
	labels().set(sign, "Text", "open")
	Spec.equal(sign.AttributeChanged.count(), 1, "one listener for its attributes")
	Spec.equal(sign:GetPropertyChangedSignal("Text").count(), 1, "one for the property")
	-- The engine may say an instance twice (tagged before the client ran, and again as it streams in).
	world.collection:GetInstanceAddedSignal("Localized").fire(sign)
	Spec.equal(sign.AttributeChanged.count(), 1, "said twice, watched once")
	-- A new sentence on a property already followed connects nothing more.
	labels().set(sign, "Text", "level", { 2 })
	labels().set(sign, "Text", "level", { 3 })
	Spec.equal(sign:GetPropertyChangedSignal("Text").count(), 1, "followed once")
	Spec.equal(sign.Text, "RU lv 3")
	Spec.equal(sign.Destroying.count(), 1)
	world.destroy(sign)
	Spec.equal(sign.Destroying.count(), 0, "it listened once")
end)

return nil
