--!strict
--- Text a server puts on a replicated instance (a sign, a prompt, a billboard), written as a key
--- and its arguments rather than finished words, so each client draws it in its own language.
---
---     const label = Label.new({ said = said, english = englishReader })
---     label.set(sign, "Text", "priceOf", { { pet = "Goldbun" }, "12K" })
---
--- `set` tags the instance and stores the sentence in an attribute named after the property
--- (`Said_Text`); the client's `Localize` rewrites that property locally in the reader's language.
--- The property itself gets the English, so it is never blank before the client has run, and a
--- viewer no client code reaches still sees words. Setting the same sentence again does nothing,
--- so a sign repainted several times a second costs nothing on the wire.
---
--- The instance is whatever the game hands in. This module calls `GetAttribute`, `SetAttribute`
--- and `AddTag` on it and writes the property; it reads no service and never touches `game`.
const Said = require("./Said")
const Text = require("./Text")

const Label = {}

--> The tag and the attribute prefix used when a game names none.
Label.TAG = "Localized"
Label.PREFIX = "Said_"

export type Options = {
	--- The game's sentences (`Said.new`).
	said: Said.Said,
	--- A reader in English over the game's tables: what the property holds before a client rewrites it.
	english: Text.Reader,
	--- The tag a labelled instance gets. "Localized" by default; the client's `Localize` must agree.
	tag: string?,
	--- What the sentence's attribute is called before the property's name. "Said_" by default.
	prefix: string?,
}

export type Label = {
	tag: string,
	prefix: string,
	--- The sentence in English, its key and name arguments resolved. A sentence whose arguments do
	--- not fit its placeholders reads as its bare template rather than raising.
	english: (key: string, args: { Said.Arg }?) -> string,
	--- Writes a sentence on `instance[property]`. `instance` is typed loosely: any Instance.
	set: (instance: any, property: string, key: string, args: { Said.Arg }?) -> (),
	--- Writes text that needs no language (a price, a player's name) and drops any sentence the
	--- property carried, so the client stops rewriting it.
	plain: (instance: any, property: string, text: string) -> (),
}

--> One game's labels.
function Label.new(options: Options): Label
	const said = options.said
	const reader = options.english
	const tag = options.tag or Label.TAG
	const prefix = options.prefix or Label.PREFIX

	const self = {} :: Label
	self.tag = tag
	self.prefix = prefix

	function self.english(key: string, args: { Said.Arg }?): string
		if args == nil or #args == 0 then
			return reader.get(key)
		end
		const ok, text = pcall(reader.get, key, table.unpack(args))
		return if ok then text else reader.get(key)
	end

	function self.set(instance: any, property: string, key: string, args: { Said.Arg }?)
		const encoded = said.encode(key, args)
		const attribute = prefix .. property
		if instance:GetAttribute(attribute) == encoded then
			return
		end
		instance[property] = self.english(key, args)
		instance:SetAttribute(attribute, encoded)
		instance:AddTag(tag)
	end

	function self.plain(instance: any, property: string, text: string)
		instance:SetAttribute(prefix .. property, nil)
		instance[property] = text
	end

	return self
end

return Label
